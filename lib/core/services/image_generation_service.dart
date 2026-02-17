import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ImageGenerationService {
  static const int wallpaperWidth = 1080;
  static const int wallpaperHeight = 1920;

  /// Reference logical width used by the in-app preview (typical phone).
  /// Font sizes are scaled from preview to wallpaper using this ratio.
  static const double _previewLogicalWidth = 400;

  /// Scale factor so wallpaper text matches preview proportions.
  static double get _fontScale => wallpaperWidth / _previewLogicalWidth;

  /// MAIN ENTRY POINT – canvas-based so it works identically in UI and background (WorkManager).
  /// Downloads background image, draws it with overlay and verse text, returns PNG bytes.
  static Future<Uint8List> generateVerseImage({
    required String backgroundUrl,
    required String verse,
    required String reference,
    required double fontSize,
    required TextAlign textAlign,
    required Color textColor,
    required String fontFamily,
  }) async {
    return _generateVerseImageCanvas(
      backgroundUrl: backgroundUrl,
      verse: verse,
      reference: reference,
      fontSize: fontSize,
      textAlign: textAlign,
      textColor: textColor,
      fontFamily: fontFamily,
    );
  }

  /// Canvas-based generator: works with or without Flutter view (e.g. WorkManager isolate).
  /// Produces identical output for manual and automatic wallpaper updates.
  static Future<Uint8List> _generateVerseImageCanvas({
    required String backgroundUrl,
    required String verse,
    required String reference,
    required double fontSize,
    required TextAlign textAlign,
    required Color textColor,
    required String fontFamily,
  }) async {
    final w = wallpaperWidth;
    final h = wallpaperHeight;

    // 1. Download background image
    final resp = await http
        .get(Uri.parse(backgroundUrl))
        .timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) {
      throw Exception('Failed to download background image: ${resp.statusCode}');
    }

    // 2. Decode image
    final codec = await ui.instantiateImageCodec(
      resp.bodyBytes,
      targetWidth: w,
      targetHeight: h,
    );
    final frame = await codec.getNextFrame();
    final ui.Image bgImage = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();

    // 3. Draw background (cover)
    final srcW = bgImage.width.toDouble();
    final srcH = bgImage.height.toDouble();
    final scale = (w / srcW).clamp(0.0, double.infinity) >
            (h / srcH).clamp(0.0, double.infinity)
        ? w / srcW
        : h / srcH;
    final drawW = srcW * scale;
    final drawH = srcH * scale;
    final src = ui.Rect.fromLTWH(0, 0, srcW, srcH);
    final dst = ui.Rect.fromLTWH(
      (w - drawW) / 2,
      (h - drawH) / 2,
      drawW,
      drawH,
    );
    canvas.drawImageRect(bgImage, src, dst, paint);

    // 4. Dark overlay for readability (stronger than preview so text stays readable on any background)
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..color = ui.Color.fromARGB((0.48 * 255).round(), 0, 0, 0),
    );

    // 5. Scaled font sizes and safe-area–style insets so text matches preview visibility
    // Use same proportion as in-app preview (SafeArea + padding): keep content in center
    // so lockscreen/homescreen rounded corners and system UI don’t cover text.
    final scaledVerseFontSize = fontSize * _fontScale;
    final scaledRefFontSize = (fontSize * 0.55) * _fontScale;
    // ~16% horizontal and ~12% vertical insets = content in center ~68% width, ~76% height
    const horizontalPadding = 172.0; // 16% of 1080
    const verticalPadding = 230.0;   // 12% of 1920
    final contentWidth = w - 2 * horizontalPadding;
    final maxVerseWidth = contentWidth;

    final uiTextAlign = _toUiTextAlign(textAlign);

    // Shadow color for readability on any background: dark outline so light text reads on light areas
    final shadowColor = _readabilityShadowColor(textColor);
    const shadowOffset = 3.0;

    // 6. Build verse paragraph (main + shadow for readability)
    final verseStyle = ui.ParagraphStyle(
      fontFamily: fontFamily,
      fontSize: scaledVerseFontSize,
      fontWeight: ui.FontWeight.w500,
      textAlign: uiTextAlign,
      height: 1.3,
    );
    final verseBuilderShadow = ui.ParagraphBuilder(verseStyle)
      ..pushStyle(ui.TextStyle(color: shadowColor));
    verseBuilderShadow.addText(verse);
    final verseParagraphShadow = verseBuilderShadow.build();
    verseParagraphShadow.layout(ui.ParagraphConstraints(width: maxVerseWidth));

    final verseBuilder = ui.ParagraphBuilder(verseStyle)
      ..pushStyle(ui.TextStyle(color: ui.Color(textColor.value)));
    verseBuilder.addText(verse);
    final verseParagraph = verseBuilder.build();
    verseParagraph.layout(ui.ParagraphConstraints(width: maxVerseWidth));

    final refStyle = ui.ParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: scaledRefFontSize,
      fontStyle: ui.FontStyle.italic,
      textAlign: uiTextAlign,
    );
    final refBuilderShadow = ui.ParagraphBuilder(refStyle)
      ..pushStyle(ui.TextStyle(color: shadowColor));
    refBuilderShadow.addText(reference);
    final refParagraphShadow = refBuilderShadow.build();
    refParagraphShadow.layout(ui.ParagraphConstraints(width: maxVerseWidth));

    final refBuilder = ui.ParagraphBuilder(refStyle)
      ..pushStyle(ui.TextStyle(
        color: ui.Color(
          textColor.withOpacity(0.9).value,
        ),
      ));
    refBuilder.addText(reference);
    final refParagraph = refBuilder.build();
    refParagraph.layout(ui.ParagraphConstraints(width: maxVerseWidth));

    final gap = 24.0 * _fontScale;
    final totalContentHeight =
        verseParagraph.height + gap + refParagraph.height;
    var contentTop = (h - totalContentHeight) / 2;
    contentTop = contentTop.clamp(
      verticalPadding,
      h - verticalPadding - totalContentHeight,
    );

    final verseLeft = _paragraphX(verseParagraph, maxVerseWidth, textAlign);
    final verseOffset = ui.Offset(horizontalPadding + verseLeft, contentTop);
    canvas.drawParagraph(verseParagraphShadow, verseOffset + ui.Offset(shadowOffset, shadowOffset));
    canvas.drawParagraph(verseParagraph, verseOffset);

    final refLeft = _paragraphX(refParagraph, maxVerseWidth, textAlign);
    final refOffset = ui.Offset(
      horizontalPadding + refLeft,
      contentTop + verseParagraph.height + gap,
    );
    canvas.drawParagraph(refParagraphShadow, refOffset + ui.Offset(shadowOffset, shadowOffset));
    canvas.drawParagraph(refParagraph, refOffset);

    // 7. Encode to PNG
    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to encode wallpaper image');
    return byteData.buffer.asUint8List();
  }

  /// Returns a shadow color that contrasts with [textColor] so text stays readable on any background.
  static ui.Color _readabilityShadowColor(Color textColor) {
    final luminance = textColor.computeLuminance();
    // Light text (e.g. white) -> dark shadow; dark text -> light shadow
    if (luminance > 0.4) {
      return const ui.Color(0xE6000000); // opaque black
    } else {
      return const ui.Color(0xE6FFFFFF); // opaque white
    }
  }

  static ui.TextAlign _toUiTextAlign(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return ui.TextAlign.left;
      case TextAlign.right:
        return ui.TextAlign.right;
      case TextAlign.center:
      default:
        return ui.TextAlign.center;
    }
  }

  static double _paragraphX(
    ui.Paragraph paragraph,
    double maxWidth,
    TextAlign align,
  ) {
    switch (align) {
      case TextAlign.left:
        return 0;
      case TextAlign.right:
        return maxWidth - paragraph.width;
      case TextAlign.center:
      default:
        return (maxWidth - paragraph.width) / 2;
    }
  }

  /// Save image
  static Future<File> saveImage(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }
}
