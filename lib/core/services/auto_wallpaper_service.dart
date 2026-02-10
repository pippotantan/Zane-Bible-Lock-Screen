import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter/material.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';
import 'package:zane_bible_lockscreen/core/services/bible_api_service.dart';
import 'package:zane_bible_lockscreen/core/services/unsplash_service.dart';
import 'package:zane_bible_lockscreen/widgets/verse_background_preview.dart';

class AutoWallpaperService {
  static Future<void> run() async {
    final verse = await BibleApiService().fetchRandomVerse();
    final backgroundUrl = await UnsplashService().fetchRandomBackground();

    final controller = ScreenshotController();

    final image = await controller.captureFromWidget(
      MaterialApp(
        home: VerseBackgroundPreview(
          imageUrl: backgroundUrl,
          verse: verse.text,
          reference: verse.reference,
          fontSize: 26,
          textAlign: TextAlign.center,
          textColor: Colors.white, 
          fontFamily: 'serif',
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
