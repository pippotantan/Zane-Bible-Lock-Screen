import 'dart:io';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';

class WallpaperService {
  static const int homeScreen = WallpaperManagerFlutter.homeScreen;
  static const int lockScreen = WallpaperManagerFlutter.lockScreen;
  static const int both = WallpaperManagerFlutter.bothScreens;

  static Future<void> setWallpaper(
    File imageFile, {
    int location = both,
  }) async {
    await WallpaperManagerFlutter().setWallpaper(
      imageFile,
      location,
    );
  }
}