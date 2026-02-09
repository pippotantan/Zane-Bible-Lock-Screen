import 'package:flutter/material.dart';
import 'package:zane_bible_lockscreen/core/models/bible_verse.dart';
import 'package:zane_bible_lockscreen/core/services/bible_api_service.dart';
import 'package:zane_bible_lockscreen/features/editor/verse_editor_controls.dart';
import 'package:zane_bible_lockscreen/features/editor/verse_editor_state.dart';
import '../../core/services/unsplash_service.dart';
import '../../widgets/verse_background_preview.dart';

class VerseScreen extends StatefulWidget {
  const VerseScreen({super.key});
  
  @override
  State<VerseScreen> createState() => _VerseScreenState();
}

class _VerseScreenState extends State<VerseScreen> {
  BibleVerse? verse;
  String? backgroundUrl;
  bool loading = true;
  final editor = VerseEditorState();

  @override
  void initState() {
    super.initState();
    loadVerse();
  }

  Future<void> loadVerse() async {
  setState(() => loading = true);

  final bibleService = BibleApiService();
  final unsplashService = UnsplashService();

  final verseResult = await bibleService.fetchRandomVerse();
  final bgResult = await unsplashService.fetchRandomBackground();
  
  setState(() {
    verse = verseResult;
    backgroundUrl = bgResult;
    loading = false;
  });
}


@override
Widget build(BuildContext context) {
    return Scaffold(
      body: loading || verse == null || backgroundUrl == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                VerseBackgroundPreview(
                  imageUrl: backgroundUrl!,
                  verse: verse!.text,
                  reference: verse!.reference,
                  fontSize: editor.fontSize,
                  textAlign: editor.textAlign,
                  textColor: editor.textColor,
                  fontFamily: editor.fontFamily,
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 5,
                  child: VerseEditorControls(
                    fontSize: editor.fontSize,
                    textAlign: editor.textAlign,
                    textColor: editor.textColor,
                    onFontSizeChanged: (v) =>
                        setState(() => editor.fontSize = v),
                    onAlignmentChanged: (a) =>
                        setState(() => editor.textAlign = a),
                    onColorChanged: (c) =>
                        setState(() => editor.textColor = c),
                  fontFamily: editor.fontFamily,
                  onFontFamilyChanged: (f) =>
                    setState(() => editor.fontFamily = f),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadVerse,
        child: const Icon(Icons.refresh),
      ),
    );
  }

}