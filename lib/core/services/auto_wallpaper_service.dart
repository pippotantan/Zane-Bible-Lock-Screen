import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter/material.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';
import 'package:zane_bible_lockscreen/core/services/bible_api_service.dart';
import 'package:zane_bible_lockscreen/core/services/unsplash_service.dart';
import 'package:zane_bible_lockscreen/widgets/verse_background_preview.dart';
import 'package:zane_bible_lockscreen/core/services/settings_service.dart';

class AutoWallpaperService {
  static Future<void> run() async {
    final verse = await BibleApiService().fetchRandomVerse();
    final backgroundUrl = await UnsplashService().fetchRandomBackground();
    // Use saved editor settings if configured
    final useEditor = await SettingsService.getUseEditorForDaily();
    var fontSize = 26.0;
    var textAlign = TextAlign.center;
    var textColor = Colors.white;
    var fontFamily = 'serif';

    if (useEditor) {
      final editor = await SettingsService.loadEditorState();
      fontSize = editor.fontSize;
      textAlign = editor.textAlign;
      textColor = editor.textColor;
      fontFamily = editor.fontFamily;
    }

    final controller = ScreenshotController();

    final image = await controller.captureFromWidget(
      MaterialApp(
        home: VerseBackgroundPreview(
          imageUrl: backgroundUrl,
          verse: verse.text,
          reference: verse.reference,
          fontSize: fontSize,
          textAlign: textAlign,
          textColor: textColor,
          fontFamily: fontFamily,
        ),
      ),
      pixelRatio: 2.5,
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/daily_verse.png');
    await file.writeAsBytes(image);

    await WallpaperManagerFlutter().setWallpaper(
      file,
      WallpaperManagerFlutter.lockScreen,
    );
  }
}
