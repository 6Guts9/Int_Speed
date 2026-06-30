import 'dart:math';
import 'dart:typed_data';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'server_selector.dart';

// ── Isolate message types ─────────────────────────────────────────
// These are the messages passed between the main isolate
// and each worker isolate

class _DownloadTask {
  final SendPort sendPort; // isolate sends progress back through this
  final String url;
  final int maxSeconds;
  final double warmupSeconds;
  _DownloadTask(this.sendPort, this.url, this.maxSeconds, this.warmupSeconds);
}

class _UploadTask {
  final SendPort sendPort;
  final String url;
  final Uint8List payload;
  final int chunkSize;
  final int maxSeconds;
  final double warmupSeconds;
  _UploadTask(this.sendPort, this.url, this.payload,
      this.chunkSize, this.maxSeconds, this.warmupSeconds);
}

// Progress message sent from worker back to main isolate
class _StreamProgress {
  final int streamIndex;
  final int totalBytesThisStream;
  final bool done;
  _StreamProgress(this.streamIndex, this.totalBytesThisStream, {this.done = false});
}

// ── Worker isolate functions (must be top-level) ──────────────────

// Each download stream runs in its own isolate
void _downloadWorker(List<dynamic> args) async {
  final sendPort      = args[0] as SendPort;
  final url           = args[1] as String;
  final maxSeconds    = args[2] as int;
  final streamIndex   = args[3] as int;

  int bytesReceived = 0;
  final stopwatch   = Stopwatch()..start();

  try {
    final client   = http.Client();
    final request  = http.Request('GET', Uri.parse(url));
    final response = await client.send(request)
        .timeout(Duration(seconds: maxSeconds + 5));

    await for (final chunk in response.stream) {
      bytesReceived += chunk.length;
      sendPort.send(_StreamProgress(streamIndex, bytesReceived));
      if (stopwatch.elapsedMilliseconds / 1000 >= maxSeconds) break;
    }
    client.close();
  } catch (_) {}

  sendPort.send(_StreamProgress(streamIndex, bytesReceived, done: true));
}

// Each upload stream runs in its own isolate
void _uploadWorker(List<dynamic> args) async {
  final sendPort    = args[0] as SendPort;
  final url         = args[1] as String;
  final payload     = args[2] as Uint8List;
  final chunkSize   = args[3] as int;
  final maxSeconds  = args[4] as int;
  final streamIndex = args[5] as int;

  int bytesSent   = 0;
  final stopwatch = Stopwatch()..start();

  try {
    for (int offset = 0; offset < payload.length; offset += chunkSize) {
      if (stopwatch.elapsedMilliseconds / 1000 >= maxSeconds) break;

      final end   = min(offset + chunkSize, payload.length);
      final chunk = payload.sublist(offset, end);

      await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/octet-stream'},
        body: chunk,
      ).timeout(const Duration(seconds: 10));

      bytesSent += chunk.length;
      sendPort.send(_StreamProgress(streamIndex, bytesSent));
    }
  } catch (_) {}

  sendPort.send(_StreamProgress(streamIndex, bytesSent, done: true));
}

// Payload generation also runs in background
Uint8List _generatePayload(int bytes) {
  final random = Random();
  return Uint8List.fromList(
    List.generate(bytes, (_) => random.nextInt(256)),
  );
}

// ── Service ───────────────────────────────────────────────────────
class SpeedTestService {
  static const int    _maxTestSeconds  = 12;
  static const int    _parallelStreams  = 6;
  static const double _warmupSeconds   = 2.0;

  String? _selectedServerUrl;
  String? _selectedServerName;

  String get serverName => _selectedServerName ?? 'Cloudflare';

  static String _downloadFallback(int bytes) =>
      'https://speed.cloudflare.com/__down?bytes=$bytes';
  static const String _uploadFallback =
      'https://speed.cloudflare.com/__up';

  // ── Server selection ──────────────────────────────────────────
  Future<String> selectBestServer() async {
    try {
      final selector = ServerSelector();
      final server   = await selector.getBestServer();
      if (server != null) {
        _selectedServerUrl  = server.url;
        _selectedServerName = '${server.name}, ${server.country}';
        return _selectedServerName!;
      }
    } catch (_) {}
    _selectedServerUrl  = null;
    _selectedServerName = 'Cloudflare (fallback)';
    return _selectedServerName!;
  }

  String _buildDownloadUrl(int bytes) {
    if (_selectedServerUrl == null) return _downloadFallback(bytes);
    final base = _selectedServerUrl!.replaceAll('upload.php', '');
    return '${base}random4000x4000.jpg';
  }

  String get _uploadUrl => _selectedServerUrl ?? _uploadFallback;

  // ── Ping ──────────────────────────────────────────────────────
  Future<double> measurePing() async {
    final pingUrl = _selectedServerUrl != null
        ? _selectedServerUrl!.replaceAll('upload.php', 'latency.txt')
        : 'https://speed.cloudflare.com/__down?bytes=0';

    final List<double> pings = [];
    for (int i = 0; i < 3; i++) {
      final stopwatch = Stopwatch()..start();
      try {
        await http.get(Uri.parse(pingUrl))
            .timeout(const Duration(seconds: 5));
        stopwatch.stop();
        pings.add(stopwatch.elapsedMilliseconds.toDouble());
      } catch (_) {
        stopwatch.stop();
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (pings.isEmpty) return -1;
    return pings.reduce((a, b) => a + b) / pings.length;
  }

  // ── Download — true parallel isolates ────────────────────────
  Future<double> measureDownload({
    required void Function(double mbps) onProgress,
  }) async {
    final receivePort    = ReceivePort();
    final bytesPerStream = List.filled(_parallelStreams, 0);
    int   doneCount      = 0;

    int    bytesAtWarmupEnd = 0;
    double timeAtWarmupEnd  = 0;
    bool   warmupDone       = false;

    final stopwatch = Stopwatch()..start();
    final completer = Completer<void>();

    // Spawn one isolate per stream
    for (int i = 0; i < _parallelStreams; i++) {
      await Isolate.spawn(_downloadWorker, [
        receivePort.sendPort,
        _buildDownloadUrl(10000000),
        _maxTestSeconds,
        i,
      ]);
    }

    // Time cap — after _maxTestSeconds we stop waiting
    final timer = Timer(Duration(seconds: _maxTestSeconds + 2), () {
      if (!completer.isCompleted) completer.complete();
    });

    // Listen to progress from all isolates on one port
    receivePort.listen((message) {
      if (message is _StreamProgress) {
        bytesPerStream[message.streamIndex] = message.totalBytesThisStream;

        if (message.done) {
          doneCount++;
          if (doneCount >= _parallelStreams && !completer.isCompleted) {
            completer.complete();
          }
          return;
        }

        final totalBytes     = bytesPerStream.reduce((a, b) => a + b);
        final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;

        if (!warmupDone && elapsedSeconds >= _warmupSeconds) {
          warmupDone       = true;
          bytesAtWarmupEnd = totalBytes;
          timeAtWarmupEnd  = elapsedSeconds;
        }

        if (elapsedSeconds > 0) {
          double mbps;
          if (!warmupDone) {
            mbps = (totalBytes * 8) / (elapsedSeconds * 1000000);
          } else {
            final stableBytes   = totalBytes - bytesAtWarmupEnd;
            final stableSeconds = elapsedSeconds - timeAtWarmupEnd;
            mbps = stableSeconds > 0
                ? (stableBytes * 8) / (stableSeconds * 1000000)
                : 0;
          }
          onProgress(mbps);
        }
      }
    });

    await completer.future;
    timer.cancel();
    receivePort.close();
    stopwatch.stop();

    final totalBytes = bytesPerStream.reduce((a, b) => a + b);
    if (totalBytes == 0) return -1;

    if (warmupDone) {
      final stableBytes   = totalBytes - bytesAtWarmupEnd;
      final stableSeconds =
          (stopwatch.elapsedMilliseconds / 1000) - timeAtWarmupEnd;
      if (stableSeconds > 0 && stableBytes > 0) {
        return (stableBytes * 8) / (stableSeconds * 1000000);
      }
    }

    final totalSeconds = stopwatch.elapsedMilliseconds / 1000;
    return (totalBytes * 8) / (totalSeconds * 1000000);
  }

  // ── Upload — true parallel isolates ──────────────────────────
  Future<double> measureUpload({
    required void Function(double mbps) onProgress,
  }) async {
    // Generate all payloads in background first
    final payloads = await Future.wait([
      for (int i = 0; i < _parallelStreams; i++)
        compute(_generatePayload, 4 * 1024 * 1024),
    ]);

    final receivePort    = ReceivePort();
    final bytesPerStream = List.filled(_parallelStreams, 0);
    int   doneCount      = 0;

    int    bytesAtWarmupEnd = 0;
    double timeAtWarmupEnd  = 0;
    bool   warmupDone       = false;

    final stopwatch = Stopwatch()..start();
    final completer = Completer<void>();

    // Spawn one isolate per stream
    for (int i = 0; i < _parallelStreams; i++) {
      await Isolate.spawn(_uploadWorker, [
        receivePort.sendPort,
        _uploadUrl,
        payloads[i],
        512 * 1024, // 512 KB chunks
        _maxTestSeconds,
        i,
      ]);
    }

    final timer = Timer(Duration(seconds: _maxTestSeconds + 2), () {
      if (!completer.isCompleted) completer.complete();
    });

    receivePort.listen((message) {
      if (message is _StreamProgress) {
        bytesPerStream[message.streamIndex] = message.totalBytesThisStream;

        if (message.done) {
          doneCount++;
          if (doneCount >= _parallelStreams && !completer.isCompleted) {
            completer.complete();
          }
          return;
        }

        final totalBytes     = bytesPerStream.reduce((a, b) => a + b);
        final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;

        if (!warmupDone && elapsedSeconds >= _warmupSeconds) {
          warmupDone       = true;
          bytesAtWarmupEnd = totalBytes;
          timeAtWarmupEnd  = elapsedSeconds;
        }

        if (elapsedSeconds > 0) {
          double mbps;
          if (!warmupDone) {
            mbps = (totalBytes * 8) / (elapsedSeconds * 1000000);
          } else {
            final stableBytes   = totalBytes - bytesAtWarmupEnd;
            final stableSeconds = elapsedSeconds - timeAtWarmupEnd;
            mbps = stableSeconds > 0
                ? (stableBytes * 8) / (stableSeconds * 1000000)
                : 0;
          }
          onProgress(mbps);
        }
      }
    });

    await completer.future;
    timer.cancel();
    receivePort.close();
    stopwatch.stop();

    final totalBytes = bytesPerStream.reduce((a, b) => a + b);
    if (totalBytes == 0) return -1;

    if (warmupDone) {
      final stableBytes   = totalBytes - bytesAtWarmupEnd;
      final stableSeconds =
          (stopwatch.elapsedMilliseconds / 1000) - timeAtWarmupEnd;
      if (stableSeconds > 0 && stableBytes > 0) {
        return (stableBytes * 8) / (stableSeconds * 1000000);
      }
    }

    final totalSeconds = stopwatch.elapsedMilliseconds / 1000;
    return (totalBytes * 8) / (totalSeconds * 1000000);
  }
}