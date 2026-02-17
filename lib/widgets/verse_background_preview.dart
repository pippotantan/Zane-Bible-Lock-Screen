import 'dart:ui';

import 'package:flutter/material.dart';

class VerseBackgroundPreview extends StatelessWidget {
  final String imageUrl;
  final String verse;
  final String reference;
  final double fontSize;
  final TextAlign textAlign;
  final Color textColor;
  final String fontFamily;

  const VerseBackgroundPreview({
    super.key,
    required this.imageUrl,
    required this.verse,
    required this.reference,
    required this.fontSize,
    required this.textAlign,
    required this.textColor,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        /// Background
        Image.network(imageUrl, fit: BoxFit.cover),

        /// Dark overlay
        Container(color: Colors.black.withOpacity(0.35)),

        /// Safe padded content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Verse
                  Text(
                    verse,
                    textAlign: textAlign,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: textColor,
                      height: 1.3,
                      fontFamily: fontFamily,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Reference (smaller + simple font)
                  Text(
                    reference,
                    textAlign: textAlign,
                    style: TextStyle(
                      fontSize: fontSize * 0.55,
                      color: textColor.withOpacity(0.9),
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Roboto', // simple clean font
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
