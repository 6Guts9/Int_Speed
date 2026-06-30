import 'package:flutter/foundation.dart';
import '../models/TestResults.dart';
import '../services/SpeedTestService.dart';

enum TestPhase {
  idle,
  ping,
  download,
  upload,
  done,
  error,
}

class SpeedTestController extends ChangeNotifier {
  final SpeedTestService _service = SpeedTestService();
  String _serverName = '';
  String get serverName => _serverName;
  TestPhase _phase        = TestPhase.idle;
  double _currentSpeed    = 0.0;
  double _ping            = 0.0;
  double _downloadSpeed   = 0.0;
  double _uploadSpeed     = 0.0;
  Testresults? _lastResult;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────
  TestPhase   get phase         => _phase;
  double      get currentSpeed  => _currentSpeed;
  double      get ping          => _ping;
  double      get downloadSpeed => _downloadSpeed;
  double      get uploadSpeed   => _uploadSpeed;
  Testresults? get lastResult    => _lastResult;
  String?     get errorMessage  => _errorMessage;

  bool get isTesting => _phase != TestPhase.idle
      && _phase != TestPhase.done
      && _phase != TestPhase.error;
  bool get isDone    => _phase == TestPhase.done;
  bool get hasError  => _phase == TestPhase.error;

  void _update({
    TestPhase? phase,
    double? currentSpeed,
    double? ping,
    double? downloadSpeed,
    double? uploadSpeed,
    String? errorMessage,
  }) {
    if (phase         != null) _phase         = phase;
    if (currentSpeed  != null) _currentSpeed  = currentSpeed;
    if (ping          != null) _ping          = ping;
    if (downloadSpeed != null) _downloadSpeed = downloadSpeed;
    if (uploadSpeed   != null) _uploadSpeed   = uploadSpeed;
    if (errorMessage  != null) _errorMessage  = errorMessage;
    notifyListeners();
  }

  //  Start test
  Future<void> startTest() async {
    if (isTesting) return;

    // Reset
    _phase         = TestPhase.idle;
    _currentSpeed  = 0.0;
    _ping          = 0.0;
    _downloadSpeed = 0.0;
    _uploadSpeed   = 0.0;
    _errorMessage  = null;
    _lastResult    = null;
    notifyListeners();

    try {
      _update(phase: TestPhase.ping);
      _serverName = await _service.selectBestServer();
      notifyListeners();
      //  Ping
      _update(phase: TestPhase.ping);
      final ping = await _service.measurePing();

      if (ping < 0) {
        _update(
          phase: TestPhase.error,
          errorMessage: 'Cannot reach server.\nCheck your connection and try again.',
        );
        return;
      }
      _update(ping: ping);

      //  Download
      _update(phase: TestPhase.download, currentSpeed: 0.0);
      final download = await _service.measureDownload(
        onProgress: (mbps) => _update(currentSpeed: mbps),
      );

      if (download < 0) {
        _update(
          phase: TestPhase.error,
          errorMessage: 'Download test failed.\nTry again.',
        );
        return;
      }
      _update(downloadSpeed: download, currentSpeed: 0.0);

      //  Upload
      _update(phase: TestPhase.upload, currentSpeed: 0.0);
      final upload = await _service.measureUpload(
        onProgress: (mbps) => _update(currentSpeed: mbps),
      );

      // Upload failing is non-fatal — we still show download results
      final finalUpload = upload < 0 ? 0.0 : upload;
      _update(uploadSpeed: finalUpload, currentSpeed: 0.0);

      // Done
      _lastResult = Testresults(
        Ping: ping,
        DownloadSpeed: download,
        UploadSpeed: finalUpload,
        TimeStamp: DateTime.now(),
      );
      _update(phase: TestPhase.done);

    } catch (e) {
      _update(
        phase: TestPhase.error,
        errorMessage: 'Something went wrong.\nPlease try again.',
      );
    }
  }

  void reset() {
    _phase        = TestPhase.idle;
    _currentSpeed = 0.0;
    _ping         = 0.0;
    _downloadSpeed = 0.0;
    _uploadSpeed  = 0.0;
    _errorMessage = null;
    notifyListeners();
  }
}