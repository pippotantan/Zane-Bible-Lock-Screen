import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

class ImageGenerationService {
  Future<File> generateImage(ScreenshotController controller) async {
    final imageBytes = await controller.capture(
      pixelRatio: 2.5, // High quality for lockscreen
    );

    if (imageBytes == null) {
      throw Exception('Failed to capture image');
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/zane_bible_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    await file.writeAsBytes(imageBytes);
    return file;
  }
}
