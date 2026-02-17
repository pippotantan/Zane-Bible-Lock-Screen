import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';
import 'package:zane_bible_lockscreen/core/models/bible_verse.dart';
import 'package:zane_bible_lockscreen/core/services/bible_api_service.dart';
import 'package:zane_bible_lockscreen/core/services/image_generation_service.dart';
import 'package:zane_bible_lockscreen/core/services/unsplash_service.dart';
import 'package:zane_bible_lockscreen/core/services/network_service.dart';
import 'package:zane_bible_lockscreen/core/services/settings_service.dart';

class AutoWallpaperService {
  static Future<void> run() async {
    print('[AutoWallpaperService] Starting wallpaper generation');

    try {
      // ✅ 1. Check Network
      final hasNetwork = await NetworkService.hasNetworkConnection();
      if (!hasNetwork) {
        print('[AutoWallpaperService] No network connection. Aborting.');
        return;
      }

      // ✅ 2. Fetch random verse (filtered by user's topic if set)
      final topic = await SettingsService.getVerseTopic();
      final BibleVerse verse = await BibleApiService().fetchRandomVerse(topicId: topic);

      // ✅ 3. Fetch background image (hotlinked URL from API + attribution)
      final UnsplashPhotoResult unsplashPhoto =
          await UnsplashService().fetchRandomBackground();
      final String backgroundUrl = unsplashPhoto.imageUrl;

      // ✅ 4. Load editor settings (always)
      double fontSize = 42;
      TextAlign textAlign = TextAlign.center;
      Color textColor = Colors.white;
      String fontFamily = 'Roboto';

      try {
        final editor = await SettingsService.loadEditorState();
        fontSize = editor.fontSize;
        textAlign = editor.textAlign;
        textColor = editor.textColor;
        fontFamily = editor.fontFamily;
        print('[AutoWallpaperService] Editor settings applied');
      } catch (e) {
        print(
          '[AutoWallpaperService] Failed to load editor settings, using defaults',
        );
      }

      // ✅ 5. Load saved editor settings if enabled
      try {
        final useEditor = await SettingsService.getUseEditorForDaily();
        if (useEditor) {
          final editor = await SettingsService.loadEditorState();
          fontSize = editor.fontSize;
          textAlign = editor.textAlign;
          textColor = editor.textColor;
          fontFamily = editor.fontFamily;
          print('[AutoWallpaperService] Editor settings loaded');
        }
      } catch (e) {
        print('[AutoWallpaperService] Editor settings failed, using defaults');
      }

      // 6️⃣ Generate image using centralized service (with Unsplash attribution)
      final image = await ImageGenerationService.generateVerseImage(
        backgroundUrl: backgroundUrl,
        verse: verse.text,
        reference: verse.reference,
        fontSize: fontSize,
        textAlign: textAlign,
        textColor: textColor,
        fontFamily: fontFamily,
        unsplashAttribution: unsplashPhoto.attributionText,
      );

      print('[AutoWallpaperService] Image generated (${image.length} bytes)');

      // ✅ 7. Save file
      final file = await ImageGenerationService.saveImage(
        image,
        'daily_verse.png',
      );

      print('[AutoWallpaperService] Image saved at ${file.path}');

      // ✅ 8. Determine wallpaper target
      String locationStr = 'both';
      try {
        final target = await SettingsService.getWallpaperTarget();
        locationStr = target == WallpaperTarget.lockScreenOnly
            ? 'lockScreen'
            : target == WallpaperTarget.homeScreenOnly
            ? 'homeScreen'
            : 'both';
      } catch (_) {}

      // ✅ 9. Set wallpaper
      bool wallpaperSet = false;

      try {
        int location = WallpaperManagerFlutter.lockScreen;

        if (locationStr == 'homeScreen') {
          location = WallpaperManagerFlutter.homeScreen;
        } else if (locationStr == 'both') {
          location = WallpaperManagerFlutter.bothScreens;
        }

        await WallpaperManagerFlutter().setWallpaper(file, location);

        wallpaperSet = true;
        print('[AutoWallpaperService] Wallpaper set successfully');
      } catch (e) {
        print('[AutoWallpaperService] Wallpaper plugin failed: $e');
      }

      if (wallpaperSet) {
        print('[AutoWallpaperService] Wallpaper set successfully');
      } else {
        print('[AutoWallpaperService] Wallpaper may not have been set');
      }
    } catch (e, stackTrace) {
      print('[AutoWallpaperService] ERROR: $e');
      print(stackTrace);
      rethrow;
    }
  }
}

/* /// Headless image generator: download background, draw text overlay on Canvas
Future<Uint8List> generateSmartVerseWallpaper({
  required String backgroundUrl,
  required String verseText,
  required String reference,
  required double fontSize, // from SettingsService
  required Color textColor, // from SettingsService
  required String fontFamily, // real font name from SettingsService
  required int width,
  required int height,
  required ui.TextAlign textAlign, // from SettingsService
}) async {
  // 1️⃣ Download background image
  final resp = await http
      .get(Uri.parse(backgroundUrl))
      .timeout(const Duration(seconds: 20));
  if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) {
    throw Exception('Failed to download background image: ${resp.statusCode}');
  }

  // 2️⃣ Decode image
  final codec = await ui.instantiateImageCodec(
    resp.bodyBytes,
    targetWidth: width,
    targetHeight: height,
  );
  final frame = await codec.getNextFrame();
  final ui.Image bgImage = frame.image;

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint();

  // 3️⃣ Draw background scaled
  final src = ui.Rect.fromLTWH(
    0,
    0,
    bgImage.width.toDouble(),
    bgImage.height.toDouble(),
  );
  final dst = ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  canvas.drawImageRect(bgImage, src, dst, paint);

  // 4️⃣ Optional dark overlay for readability
  canvas.drawRect(dst, ui.Paint()..color = ui.Color.fromARGB(120, 0, 0, 0));

  // 5️⃣ Draw verse text
  final paragraphBuilder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: ui.TextAlign.center,
            maxLines: 10,
            fontFamily: fontFamily, // ← actual font from settings
            fontSize: fontSize, // ← actual font size from settings
          ),
        )
        ..pushStyle(
          ui.TextStyle(color: ui.Color(textColor.value), fontSize: fontSize),
        )
        ..addText(verseText);

  final paragraph = paragraphBuilder.build()
    ..layout(ui.ParagraphConstraints(width: width.toDouble() - 80));

  final double textX = 40.0;
  final double textY = (height - paragraph.height) / 2;
  canvas.drawParagraph(paragraph, ui.Offset(textX, textY));

  // 6️⃣ Draw reference smaller at bottom
  final refBuilder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: ui.TextAlign.center,
            fontSize: fontSize * 0.7,
            fontFamily: fontFamily,
          ),
        )
        ..pushStyle(
          ui.TextStyle(
            color: ui.Color(textColor.value),
            fontSize: fontSize * 0.7,
          ),
        )
        ..addText(reference);

  final refParagraph = refBuilder.build()
    ..layout(ui.ParagraphConstraints(width: width.toDouble() - 80));
  final double refX = 40.0;
  final double refY = height.toDouble() - refParagraph.height - 80.0;
  canvas.drawParagraph(refParagraph, ui.Offset(refX, refY));

  // 7️⃣ Finish image
  final picture = recorder.endRecording();
  final ui.Image finalImage = await picture.toImage(width, height);
  final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);

  if (byteData == null) throw Exception('Failed to encode final image');
  return byteData.buffer.asUint8List();
} */
