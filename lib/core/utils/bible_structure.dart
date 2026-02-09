import 'dart:math';

class BibleStructure {
  static final Map<String, List<int>> books = {
    // Old Testament
    'Genesis': [31, 25, 24, 26, 32, 22, 24, 22, 29, 32],
    'Exodus': [22, 25, 22, 31, 23],
    'Psalms': List.filled(150, 20), // safe average

    // New Testament
    'Matthew': [25, 23, 17, 25, 48, 34, 29],
    'John': [51, 25, 36, 54, 47, 71],
    'Romans': [32, 29, 31, 25, 21],
  };

  static final _random = Random();

  static String randomPassage() {
    final book = books.keys.elementAt(
      _random.nextInt(books.length),
    );

    final chapters = books[book]!;
    final chapterIndex = _random.nextInt(chapters.length);
    final verseCount = chapters[chapterIndex];

    final verse = _random.nextInt(verseCount) + 1;

    return '$book ${chapterIndex + 1}:$verse';
  }
}