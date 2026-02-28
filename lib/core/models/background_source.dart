/// Source of background images for verse wallpapers.
/// [unsplash] uses the Unsplash API (requires internet).
/// [localGallery] uses user-selected images from device gallery (works offline).
enum BackgroundSource {
  unsplash,
  localGallery,
}

extension BackgroundSourceExtension on BackgroundSource {
  String get displayName {
    switch (this) {
      case BackgroundSource.unsplash:
        return 'Unsplash (online)';
      case BackgroundSource.localGallery:
        return 'Device gallery (offline)';
    }
  }
}
