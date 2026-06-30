import 'dart:convert';
import 'package:http/http.dart' as http;

class TestServer {
  final String url;
  final String name;
  final String country;
  final double latency;

  const TestServer({
    required this.url,
    required this.name,
    required this.country,
    required this.latency,
  });
}

class ServerSelector {
  // Ookla's public API — returns a list of nearby test servers
  // based on your IP geolocation, no API key needed
  static const String _serversUrl =
      'https://www.speedtest.net/api/js/servers?engine=js&limit=5&https_functional=true';

  // Find the closest server and return the one with lowest ping
  Future<TestServer?> getBestServer() async {
    try {
      final response = await http
          .get(
        Uri.parse(_serversUrl),
        headers: {
          // Must send a browser-like user agent or Ookla rejects the request
          'User-Agent':
          'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/91.0 Safari/537.36',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final List<dynamic> servers = json.decode(response.body);
      if (servers.isEmpty) return null;

      // Ping each server and pick the fastest one
      TestServer? best;
      for (final server in servers) {
        final url = server['url'] as String? ?? '';
        if (url.isEmpty) continue;

        // Convert the test URL to a latency ping URL
        // Ookla server URLs end in /upload.php — we ping /latency.txt
        final pingUrl = url
            .replaceAll('upload.php', 'latency.txt');

        final latency = await _pingServer(pingUrl);
        if (latency < 0) continue;

        final candidate = TestServer(
          url: url,
          name: server['name'] as String? ?? 'Unknown',
          country: server['country'] as String? ?? '',
          latency: latency,
        );

        if (best == null || candidate.latency < best.latency) {
          best = candidate;
        }
      }

      return best;
    } catch (e) {
      return null;
    }
  }

  Future<double> _pingServer(String url) async {
    final stopwatch = Stopwatch()..start();
    try {
      await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds.toDouble();
    } catch (e) {
      return -1;
    }
  }
}