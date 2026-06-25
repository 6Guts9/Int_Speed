import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;


// test servers
class Speedtestservice {
  static const String _DownloadUrl = 'https://speed.cloudflare.com/__down?bytes=25000000';
  static const String _UploadUrl =      'https://httpbin.org/post';

}
// ping
Future<double> MeasurePing() async {
const testUrl =  'https://speed.cloudflare.com/__down?bytes=0';
final List<double> pings= [] ;
for (int i = 0; i < 4; i++) {
  final Stopwatch stopwatch = Stopwatch()..start();
  try {
await http.get(Uri.parse(testUrl));
stopwatch.stop();
pings.add(stopwatch.elapsedMilliseconds.toDouble());
      }
  catch(e){
    stopwatch.stop();
    }
  await Future.delayed(const Duration(milliseconds: 200));
  }
if (pings.isEmpty) return -1;
return pings.reduce((a,b) => a+b)/ pings.length ;
}
// downlaod
Future<double> MeasureDownload({
  required void Function(double mbps) onProgress,})
async{
  final stopwatch = Stopwatch()..start();
  int bytesReceived = 0;
  try{
    final request =http.Request('GET',Uri.parse(Speedtestservice._DownloadUrl));
    final response = await http.Client().send(request);

    await for (final chunk in response.stream){
      bytesReceived += chunk.length;
      final elapsedSeconds = stopwatch.elapsedMilliseconds /1000;
      if(elapsedSeconds > 0){
      final mbps = (bytesReceived*8) / (elapsedSeconds * 1024 * 1024);
      onProgress(mbps);

      }
    }
    stopwatch.stop();
    final totalSeconds= stopwatch.elapsedMilliseconds/1000;
    return (bytesReceived * 8) / (totalSeconds * 1024 * 1024);
  }catch (e){
    return -1;
  }
}
// upload
Future <double> MeasureUpload({
  required void Function(double mbps) onProgress,
}) async {
  const int totalBytes = 10 * 1024 * 1024;
  const int chunkSize = 1024 * 1024;
  final random = Random();

  final Uint8List payload = Uint8List.fromList(
    List.generate(chunkSize, (_) => random.nextInt(256)),

  );
  final stopwatch = Stopwatch()..start();
  int bytesSent = 0;
  try {
    for (int offset = 0; offset < totalBytes; offset += chunkSize) {
      final end = min(offset + chunkSize, totalBytes);
      final chunk = payload.sublist(offset, end);

      await http.post(Uri.parse(Speedtestservice._UploadUrl), body: chunk);
      bytesSent += chunk.length;
      final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;
      if (elapsedSeconds > 0) {
        final mbps = (bytesSent * 8) / (elapsedSeconds * 1024 * 1024);
        onProgress(mbps);
      };
    }
    stopwatch.stop();
    final totalSeconds = stopwatch.elapsedMilliseconds / 1000;
    return (bytesSent * 8) / (totalSeconds * 1024 * 1024);
  } catch (e) {
    return -1;
  }
}