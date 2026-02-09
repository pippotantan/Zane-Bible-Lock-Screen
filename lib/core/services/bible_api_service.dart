import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bible_verse.dart';
import '../utils/bible_metadata.dart';

class BibleApiService {
  static const String baseUrl =
      'https://labs.bible.org/api/?type=json&passage=';

  Future<BibleVerse> fetchRandomVerse() async {
    final passage = BibleMetadata.randomPassage();
    final formatted = passage.replaceAll(' ', '+');

    final response = await http.get(
      Uri.parse('$baseUrl$formatted'),
    );

    if (response.statusCode != 200 || response.body.isEmpty) {
      throw Exception('Bible API returned empty response');
    }

    final List data = jsonDecode(response.body);
    final verse = data.first;

    return BibleVerse(
      reference:
          '${verse['bookname']} ${verse['chapter']}:${verse['verse']}',
      text: verse['text'],
    );
  }
}