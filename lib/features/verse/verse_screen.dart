import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:zane_bible_lockscreen/core/models/bible_verse.dart';
import 'package:zane_bible_lockscreen/core/services/bible_api_service.dart';
import 'package:zane_bible_lockscreen/core/services/image_generation_service.dart';
import 'package:zane_bible_lockscreen/core/services/wallpaper_service.dart';
import 'package:zane_bible_lockscreen/core/services/workmanager_service.dart';
import 'package:zane_bible_lockscreen/core/services/settings_service.dart';
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
  bool useForDaily = false;
  bool isScheduled = false;
  TimeOfDay? scheduledTime;

  @override
  void initState() {
    super.initState();
    loadVerse();
    _loadEditorSettings();
  }

  Future<void> _loadEditorSettings() async {
    final saved = await SettingsService.loadEditorState();
    final use = await SettingsService.getUseEditorForDaily();
    final sched = await SettingsService.getScheduled();
    final schedTime = await SettingsService.getScheduledTime();
    setState(() {
      editor.fontSize = saved.fontSize;
      editor.textAlign = saved.textAlign;
      editor.textColor = saved.textColor;
      editor.fontFamily = saved.fontFamily;
      useForDaily = use;
      isScheduled = sched;
      scheduledTime = schedTime;
    });
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
                    useForDaily: useForDaily,
                    onFontSizeChanged: (v) => setState(() {
                      editor.fontSize = v;
                      SettingsService.saveEditorState(editor);
                    }),
                    onAlignmentChanged: (a) => setState(() {
                      editor.textAlign = a;
                      SettingsService.saveEditorState(editor);
                    }),
                    onColorChanged: (c) => setState(() {
                      editor.textColor = c;
                      SettingsService.saveEditorState(editor);
                    }),
                    fontFamily: editor.fontFamily,
                    onFontFamilyChanged: (f) => setState(() {
                      editor.fontFamily = f;
                      SettingsService.saveEditorState(editor);
                    }),
                    onUseForDailyChanged: (v) async {
                      setState(() => useForDaily = v);
                      await SettingsService.setUseEditorForDaily(v);
                    },
                    onRefreshPressed: loadVerse,
                    onCapturePressed: generateImage,
                    onSetLockPressed: () async => await generateAndSetWallpaper(),
                    onScheduleAt: (time) async {
                      // schedule with WorkManager for chosen time
                      await WorkManagerService.scheduleDailyVerseAt(time.hour, time.minute);
                      await SettingsService.setScheduled(true);
                      await SettingsService.setScheduledTime(time.hour, time.minute);
                      setState(() {
                        isScheduled = true;
                        scheduledTime = time;
                      });
                    },
                    onCancelSchedule: () async {
                      await WorkManagerService.cancelDailyVerse();
                      await SettingsService.setScheduled(false);
                      setState(() {
                        isScheduled = false;
                        scheduledTime = null;
                      });
                    },
                    isScheduled: isScheduled,
                    scheduledTime: scheduledTime,
                  ),
                ),
              ],
            ),
      floatingActionButton: null,
    );
  }
}
