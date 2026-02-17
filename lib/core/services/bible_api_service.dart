import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/bible_verse.dart';
import '../utils/bible_topics.dart';

class BibleApiService {
  static const String baseUrl =
      'https://labs.bible.org/api/?type=json&passage=';

  static const int _maxRetries = 5;
  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _initialBackoff = Duration(seconds: 2);

  /// [topicId] optional; e.g. "all" (default), "love", "hope". When not "all", picks from that topic's passages.
  Future<BibleVerse> fetchRandomVerse({String? topicId}) async {
    final passage = BibleTopics.getRandomPassageForTopic(topicId);
    final formatted = passage.replaceAll(' ', '+');
    final url = Uri.parse('$baseUrl$formatted');

    print('[BibleApiService] Fetching verse: $passage (topic: ${topicId ?? "all"})');

    return _retryWithBackoff(
      () => _fetchVerseWithTimeout(url),
      maxAttempts: _maxRetries,
    );
  }

  Future<BibleVerse> _fetchVerseWithTimeout(Uri url) async {
    try {
      print('[BibleApiService] Making HTTP request to: $url');

      final response = await http
          .get(url)
          .timeout(
            _timeout,
            onTimeout: () {
              throw TimeoutException(
                'Bible API request timed out after ${_timeout.inSeconds}s',
                _timeout,
              );
            },
          );

      print('[BibleApiService] Response status: ${response.statusCode}');

      if (response.statusCode != 200 || response.body.isEmpty) {
        throw Exception('Bible API returned status ${response.statusCode}');
      }

      final List data = jsonDecode(response.body);
      if (data.isEmpty) {
        throw Exception('Bible API returned empty data list');
      }

      final verse = data.first;

      return BibleVerse(
        reference: '${verse['bookname']} ${verse['chapter']}:${verse['verse']}',
        text: verse['text'],
      );
    } catch (e) {
      print('[BibleApiService] Error: $e');
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
        print('[BibleApiService] Attempt $attempt/$maxAttempts');
        return await operation();
      } catch (e) {
        print('[BibleApiService] Attempt $attempt failed: $e');

        if (attempt == maxAttempts) {
          print('[BibleApiService] All retries exhausted');
          rethrow;
        }

        print('[BibleApiService] Retrying in ${backoff.inSeconds}s...');
        await Future.delayed(backoff);

        // Exponential backoff: 2s, 4s, 8s
        backoff = Duration(seconds: backoff.inSeconds * 2);
      }
    }

    throw Exception('Unexpected error in retry logic');
  }
}
