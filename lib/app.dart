import 'package:flutter/material.dart';
import 'package:zane_bible_lockscreen/features/verse/verse_screen.dart';

class ZaneBibleApp extends StatelessWidget {
  const ZaneBibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zane Bible Lockscreen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const VerseScreen(),
    );
  }
}
