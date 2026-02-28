/// Unified result for background image retrieval.
/// Either [imageUrl] (from Unsplash) or [localPath] (from device gallery) will be set.
class BackgroundResult {
  /// URL for network image (Unsplash). Null when using local gallery.
  final String? imageUrl;

  /// Local file path for device gallery image. Null when using Unsplash.
  final String? localPath;

  /// Attribution text (e.g. "Photo by X / Unsplash"). Only for Unsplash.
  final String? attributionText;

  const BackgroundResult({
    this.imageUrl,
    this.localPath,
    this.attributionText,
  });

  bool get isLocal => localPath != null && localPath!.isNotEmpty;
  bool get isNetwork => imageUrl != null && imageUrl!.isNotEmpty;
}
