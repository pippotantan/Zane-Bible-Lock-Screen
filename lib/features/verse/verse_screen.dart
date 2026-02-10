import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:zane_bible_lockscreen/core/models/bible_verse.dart';
import 'package:zane_bible_lockscreen/core/services/bible_api_service.dart';
import 'package:zane_bible_lockscreen/core/services/image_generation_service.dart';
import 'package:zane_bible_lockscreen/core/services/wallpaper_service.dart';
import 'package:zane_bible_lockscreen/core/services/workmanager_service.dart';
import 'package:zane_bible_lockscreen/core/utils/image_saver.dart';
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
  final ScreenshotController screenshotController = ScreenshotController();
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

  Future<void> generateImage() async {
    try {
      final service = ImageGenerationService();
      final file = await service.generateImage(screenshotController);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image generated:\n${file.path}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate image: $e')));
    }
  }

  Future<void> generateAndSetWallpaper() async {
    final image = await screenshotController.capture(
      delay: const Duration(milliseconds: 200),
    );

    if (image == null) return;

    final file = await ImageSaver.saveImage(image);

    await WallpaperService.setWallpaper(
      file,
      location: WallpaperService.lockScreen, // or homeScreen / both
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading || verse == null || backgroundUrl == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Screenshot(
                  controller: screenshotController,
                  child: VerseBackgroundPreview(
                    imageUrl: backgroundUrl!,
                    verse: verse!.text,
                    reference: verse!.reference,
                    fontSize: editor.fontSize,
                    textAlign: editor.textAlign,
                    textColor: editor.textColor,
                    fontFamily: editor.fontFamily,
                  ),
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
                    onColorChanged: (c) => setState(() => editor.textColor = c),
                    fontFamily: editor.fontFamily,
                    onFontFamilyChanged: (f) =>
                        setState(() => editor.fontFamily = f),
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'refresh',
            onPressed: loadVerse,
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'generate',
            onPressed: generateImage,
            child: const Icon(Icons.camera_alt),
          ),
          ElevatedButton(
            onPressed: () => generateAndSetWallpaper(),
            child: const Text('Set as Lock Screen'),
          ),
          ElevatedButton(
            onPressed: () => WorkManagerService.scheduleDailyVerse(),
            child: const Text('Schedule Daily Verse'),
          ),
        ],
      ),
    );
  }
}
