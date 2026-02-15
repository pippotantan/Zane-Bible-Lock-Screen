import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:screenshot/screenshot.dart';

class VerseBackgroundPreview extends StatelessWidget {
  final String imageUrl;
  final String verse;
  final String reference;
  final double fontSize;
  final TextAlign textAlign;
  final Color textColor;
  final String fontFamily;
  final ScreenshotController screenshotController = ScreenshotController();

  VerseBackgroundPreview({
    super.key,
    required this.imageUrl,
    required this.verse,
    required this.reference,
    required this.fontSize,
    required this.textAlign,
    required this.textColor,
    this.fontFamily = 'Roboto',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, _) =>
                const Center(child: CircularProgressIndicator()),
          ),
        ),

        // Dark overlay for readability
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.35)),
        ),

        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  verse,
                  textAlign: textAlign,
                  style: TextStyle(
                    fontSize: fontSize,
                    height: 1.4,
                    color: textColor,
                    fontFamily: fontFamily,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(blurRadius: 12, color: Colors.black),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  '— $reference',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
