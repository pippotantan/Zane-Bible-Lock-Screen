import 'package:flutter/material.dart';

class VerseEditorControls extends StatelessWidget {
  final double fontSize;
  final TextAlign textAlign;
  final Color textColor;
  final String fontFamily;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<TextAlign> onAlignmentChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<String> onFontFamilyChanged;

  const VerseEditorControls({
    super.key,
    required this.fontSize,
    required this.textAlign,
    required this.textColor,
    required this.fontFamily,
    required this.onFontSizeChanged,
    required this.onAlignmentChanged,
    required this.onColorChanged,
    required this.onFontFamilyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.black87,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Font size slider
          Row(
            children: [
              const Icon(Icons.format_size, color: Colors.white),
              Expanded(
                child: Slider(
                  value: fontSize,
                  min: 16,
                  max: 36,
                  divisions: 20,
                  label: fontSize.round().toString(),
                  onChanged: onFontSizeChanged,
                ),
              ),
            ],
          ),

          // Font family selection (sans / serif)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => onFontFamilyChanged('sans'),
                child: Text(
                  'Sans',
                  style: TextStyle(
                    color: fontFamily == 'sans' ? Colors.amber : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => onFontFamilyChanged('serif'),
                child: Text(
                  'Serif',
                  style: TextStyle(
                    color: fontFamily == 'serif' ? Colors.amber : Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // Alignment buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _alignButton(Icons.format_align_left, TextAlign.left),
              _alignButton(Icons.format_align_center, TextAlign.center),
              _alignButton(Icons.format_align_right, TextAlign.right),
            ],
          ),

          // Color picker (simple)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _colorDot(Colors.white),
              _colorDot(Colors.yellowAccent),
              _colorDot(Colors.orangeAccent),
              _colorDot(Colors.lightBlueAccent),
              _colorDot(Colors.purpleAccent),
              _colorDot(Colors.greenAccent),
              _colorDot(Colors.redAccent),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _alignButton(IconData icon, TextAlign align) {
    return IconButton(
      icon: Icon(
        icon,
        color: textAlign == align ? Colors.amber : Colors.white,
      ),
      onPressed: () => onAlignmentChanged(align),
    );
  }

  Widget _colorDot(Color color) {
    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: CircleAvatar(
        backgroundColor: color,
        radius: 14,
        child: textColor == color
            ? const Icon(Icons.check, color: Colors.black, size: 16)
            : null,
      ),
    );
  }
}