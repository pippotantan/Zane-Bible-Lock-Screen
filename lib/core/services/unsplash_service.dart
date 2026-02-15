import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class UnsplashService {
  static const String _accessKey =
      '-rS9QoE7QcKbk7JxliDlg4g-5AxfASbXa0G2gk-CPKI';

  static const String _endpoint =
      'https://api.unsplash.com/photos/random'
      '?orientation=portrait'
      '&query=nature,faith,sky,landscape'
      '&content_filter=high';

  static const int _maxRetries = 5;
  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _initialBackoff = Duration(seconds: 2);

  Future<String> fetchRandomBackground() async {
    print('[UnsplashService] Fetching random background image');

    return _retryWithBackoff(_fetchImageWithTimeout, maxAttempts: _maxRetries);
  }

  Future<String> _fetchImageWithTimeout() async {
    try {
      print('[UnsplashService] Making HTTP request to Unsplash API');

      final response = await http
          .get(
            Uri.parse(_endpoint),
            headers: {'Authorization': 'Client-ID $_accessKey'},
          )
          .timeout(
            _timeout,
            onTimeout: () {
              throw TimeoutException(
                'Unsplash API request timed out after ${_timeout.inSeconds}s',
                _timeout,
              );
            },
          );

      print('[UnsplashService] Response status: ${response.statusCode}');

      if (response.statusCode != 200 || response.body.isEmpty) {
        throw Exception('Unsplash API returned status ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final imageUrl = data['urls']?['regular'];

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('Unsplash response missing image URL');
      }

      print(
        '[UnsplashService] Image URL obtained: ${imageUrl.substring(0, 50)}...',
      );
      return imageUrl;
    } catch (e) {
      print('[UnsplashService] Error: $e');
      rethrow;
    }
  }

  Future<T> _retryWithBackoff<T>(
    Future<T> Function() operation, {
    required int maxAttempts,
  }) async {
    Duration backoff = _initialBackoff;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        print('[UnsplashService] Attempt $attempt/$maxAttempts');
        return await operation();
      } catch (e) {
        print('[UnsplashService] Attempt $attempt failed: $e');

        if (attempt == maxAttempts) {
          print('[UnsplashService] All retries exhausted');
          rethrow;
        }

        print('[UnsplashService] Retrying in ${backoff.inSeconds}s...');
        await Future.delayed(backoff);

        // Exponential backoff: 2s, 4s, 8s
        backoff = Duration(seconds: backoff.inSeconds * 2);
      }
    }

    throw Exception('Unexpected error in retry logic');
  }
}
