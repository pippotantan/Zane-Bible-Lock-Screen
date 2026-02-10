import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class ImageSaver {
  static Future<File> saveImage(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/verse_wallpaper_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    return file;
  }
}