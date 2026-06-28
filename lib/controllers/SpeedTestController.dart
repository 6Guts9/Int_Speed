import 'package:flutter/foundation.dart';
import 'package:int_speed/models/TestResults.dart';
import 'package:int_speed/services/SpeedTestService.dart';

enum TestPhase {
  idle,
  ping,
  download,
  upload,
  done,
  error,
}
//change notifier (every widget that is watching the controller gets told to rebuild itself)
class SpeedTestController extends ChangeNotifier{
  final Speedtestservice _service = Speedtestservice();
  TestPhase _phase = TestPhase.idle;
  double _currentSpeed = 0.0;
  double _ping = 0.0;
  double _downloadSpeed = 0.0;
  double _uploadSpeed = 0.0;
  Testresults? _lastResults;
  String? _errorMessage;

  //getters

TestPhase get phase => _phase;
double get currentSpeed => _currentSpeed;
double get ping => _ping;
double get downloadSpeed => _downloadSpeed;
double get uploadSpeed => _uploadSpeed;
Testresults? get lastResult => _lastResults;
String? get errorMessage => _errorMessage;

  bool get isTesting =>
      _phase != TestPhase.idle &&
      _phase != TestPhase.done &&
      _phase != TestPhase.error;
  bool get isIdle => _phase == TestPhase.idle;
  bool get hasError => _phase == TestPhase.error;
  bool get isDone => _phase == TestPhase.done;

//state updater
  void _update({
    TestPhase? phase,
    double? currentSpeed,
    double? ping,
    double? downloadSpeed,
    double? uploadSpeed,
    String? errorMessage,
  }) {
    if (phase != null) _phase = phase;
    if (currentSpeed != null) _currentSpeed = currentSpeed;
    if (ping != null) _ping = ping;
    if (downloadSpeed != null) _downloadSpeed = downloadSpeed;
    if (uploadSpeed != null) _uploadSpeed = uploadSpeed;
    if (errorMessage != null) _errorMessage = errorMessage;
    notifyListeners();
  }

  Future<void> startTest() async {
    if (isTesting) return;

    _phase = TestPhase.idle;
    _currentSpeed = 0.0;
    _ping = 0.0;
    _downloadSpeed = 0.0;
    _uploadSpeed = 0.0;
    _lastResults = null;
    _errorMessage = null;
    notifyListeners();

    try {
// ── ping phase ──────────────────────────────────────
      _update(phase: TestPhase.ping);
      final ping = await _service.MeasurePing();

      if (ping < 0) {
        _update(
            phase: TestPhase.error,
            errorMessage: 'Could not reach test server. Check your connection.');
        return;
      }
      _update(ping: ping);

// ── download phase ──────────────────────────────────
      _update(phase: TestPhase.download, currentSpeed: 0.0);
      final download = await _service.MeasureDownload(
        onProgress: (mbps) {
          _update(currentSpeed: mbps);
        },
      );

      if (download < 0) {
        _update(phase: TestPhase.error, errorMessage: 'Download test failed.');
        return;
      }
      _update(downloadSpeed: download, currentSpeed: 0.0);

// ── Phase 3: Upload ────────────────────────────────────
      _update(phase: TestPhase.upload, currentSpeed: 0.0);
      final upload = await _service.MeasureUpload(
        onProgress: (mbps) {
          _update(currentSpeed: mbps);
        },
      );

      if (upload < 0) {
        _update(phase: TestPhase.error, errorMessage: 'Upload test failed.');
        return;
      }
      _update(uploadSpeed: upload, currentSpeed: 0.0);

// done hh
      _lastResults = Testresults(
        Ping: ping,
        DownloadSpeed: download,
        UploadSpeed: upload,
        TimeStamp: DateTime.now(),
      );
      _update(phase: TestPhase.done);
    } catch (e) {
      _update(
        phase: TestPhase.error,
        errorMessage: 'Something went wrong: ${e.toString()}',
      );
    }
  }

  void reset() {
    _phase = TestPhase.idle;
    _currentSpeed = 0.0;
    _ping = 0.0;
    _downloadSpeed = 0.0;
    _uploadSpeed = 0.0;
    _errorMessage = null;
    notifyListeners();
  }
}
