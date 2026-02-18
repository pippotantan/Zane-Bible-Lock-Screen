import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../utils/background_keywords.dart';

/// Result of a random Unsplash photo. Uses only API-returned photo.urls (hotlinking).
/// Attribution text follows Unsplash guidelines: "Photo by [Name] / Unsplash".
class UnsplashPhotoResult {
  /// Hotlinked image URL from API (photo.urls.regular or .full). Must not be altered.
  final String imageUrl;
  /// Attribution line for the photographer and Unsplash (e.g. "Photo by Jane Doe / Unsplash").
  final String attributionText;

  const UnsplashPhotoResult({
    required this.imageUrl,
    required this.attributionText,
  });
}

class UnsplashService {
  static const String _accessKey =
      '-rS9QoE7QcKbk7JxliDlg4g-5AxfASbXa0G2gk-CPKI';

  static const String _baseUrl =
      'https://api.unsplash.com/photos/random';
  static const String _defaultQuery = 'nature,faith,sky,landscape';

  static const int _maxRetries = 5;
  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _initialBackoff = Duration(seconds: 2);

  /// Fetches a random background. [keywordId] filters by Unsplash query (e.g. "all", "nature", "christian").
  /// Returns hotlinked URL from photo.urls and attribution.
  Future<UnsplashPhotoResult> fetchRandomBackground({String? keywordId}) async {
    print('[UnsplashService] Fetching random background image (keyword: ${keywordId ?? "all"})');

    return _retryWithBackoff(
      () => _fetchPhotoWithTimeout(keywordId),
      maxAttempts: _maxRetries,
    );
  }

  Future<UnsplashPhotoResult> _fetchPhotoWithTimeout(String? keywordId) async {
    try {
      final query = BackgroundKeywords.queryFor(keywordId ?? BackgroundKeywords.all);
      final endpoint = '$_baseUrl?orientation=portrait&query=${Uri.encodeQueryComponent(query)}&content_filter=high';
      print('[UnsplashService] Making HTTP request to Unsplash API');

      final response = await http
          .get(
            Uri.parse(endpoint),
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

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Use only hotlinked URLs from API (photo.urls) per Unsplash guidelines
      final urls = data['urls'] as Map<String, dynamic>?;
      final imageUrl = urls?['regular'] as String?;

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('Unsplash response missing image URL in photo.urls');
      }

      // Build attribution per Unsplash guideline: "Photo by [Name] / Unsplash"
      final user = data['user'] as Map<String, dynamic>?;
      final name = user?['name'] as String? ?? 'Unknown';
      final attributionText = 'Photo by $name / Unsplash';

      print(
        '[UnsplashService] Image URL (hotlinked): ${imageUrl.substring(0, imageUrl.length > 50 ? 50 : imageUrl.length)}...',
      );
      return UnsplashPhotoResult(
        imageUrl: imageUrl,
        attributionText: attributionText,
      );
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
