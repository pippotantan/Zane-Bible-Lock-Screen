import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zane_bible_lockscreen/widgets/verse_background_preview.dart';

class ImageGenerationService {
  static const int wallpaperWidth = 1080;
  static const int wallpaperHeight = 1920;

  /// MAIN ENTRY POINT
  static Future<Uint8List> generateVerseImage({
    required String backgroundUrl,
    required String verse,
    required String reference,
    required double fontSize,
    required TextAlign textAlign,
    required Color textColor,
    required String fontFamily,
  }) async {
    return _renderWidgetToImage(
      backgroundUrl,
      verse,
      reference,
      fontSize,
      textAlign,
      textColor,
      fontFamily,
    );
  }

  /// SINGLE RENDER ENGINE (used by both UI & WorkManager)
  static Future<Uint8List> _renderWidgetToImage(
    String backgroundUrl,
    String verse,
    String reference,
    double fontSize,
    TextAlign textAlign,
    Color textColor,
    String fontFamily,
  ) async {
    final repaintBoundary = RenderRepaintBoundary();
    final view = ui.PlatformDispatcher.instance.views.first;

    final logicalSize = Size(
      wallpaperWidth.toDouble(),
      wallpaperHeight.toDouble(),
    );

    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(logicalSize),
        devicePixelRatio: 2.5,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: MediaQuery(
        data: MediaQueryData(size: logicalSize, devicePixelRatio: 2.5),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: logicalSize.width,
              height: logicalSize.height,
              child: VerseBackgroundPreview(
                imageUrl: backgroundUrl,
                verse: verse,
                reference: reference,
                fontSize: fontSize,
                textAlign: textAlign,
                textColor: textColor,
                fontFamily: fontFamily,
              ),
            ),
          ),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: 2.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception("Failed to render image");
    }

    return byteData.buffer.asUint8List();
  }

  /// Save image
  static Future<File> saveImage(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }
}
