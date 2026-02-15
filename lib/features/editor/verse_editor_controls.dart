import 'package:flutter/material.dart';

class VerseEditorControls extends StatefulWidget {
  final double fontSize;
  final TextAlign textAlign;
  final Color textColor;
  final String fontFamily;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<TextAlign> onAlignmentChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<String> onFontFamilyChanged;
  final bool useForDaily;
  final ValueChanged<bool> onUseForDailyChanged;
  final VoidCallback onRefreshPressed;
  final VoidCallback onCapturePressed;
  final Future<void> Function() onSetLockPressed;
  final Future<void> Function(TimeOfDay time) onScheduleAt;
  final Future<void> Function() onCancelSchedule;
  final bool isScheduled;
  final TimeOfDay? scheduledTime;

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
    required this.useForDaily,
    required this.onUseForDailyChanged,
    required this.onRefreshPressed,
    required this.onCapturePressed,
    required this.onSetLockPressed,
    required this.onScheduleAt,
    required this.onCancelSchedule,
    required this.isScheduled,
    required this.scheduledTime,
  });

  @override
  State<VerseEditorControls> createState() => _VerseEditorControlsState();
}

class _VerseEditorControlsState extends State<VerseEditorControls> {
  bool expanded = true;

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
            // header: collapse/expand
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(expanded ? Icons.expand_more : Icons.chevron_left, color: Colors.white),
                  onPressed: () => setState(() => expanded = !expanded),
                ),
                const SizedBox(width: 8),
                const Text('Editor & Controls', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            if (!expanded) const SizedBox.shrink(),
            if (expanded) ...[
          // Font size slider
          Row(
            children: [
              const Icon(Icons.format_size, color: Colors.white),
              Expanded(
                child: Slider(
                  value: widget.fontSize,
                  min: 16,
                  max: 36,
                  divisions: 20,
                  label: widget.fontSize.round().toString(),
                  onChanged: widget.onFontSizeChanged,
                ),
              ),
            ],
          ),

          // Font family selection (sans / serif)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => widget.onFontFamilyChanged('sans'),
                child: Text(
                  'Sans',
                  style: TextStyle(
                    color: widget.fontFamily == 'sans' ? Colors.amber : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => widget.onFontFamilyChanged('serif'),
                child: Text(
                  'Serif',
                  style: TextStyle(
                    color: widget.fontFamily == 'serif' ? Colors.amber : Colors.white,
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

          // Use for daily verse toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Use these settings for Daily Verse', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              Switch(
                value: widget.useForDaily,
                onChanged: widget.onUseForDailyChanged,
                activeColor: Colors.amber,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Action buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: 'Refresh verse',
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: widget.onRefreshPressed,
              ),
              IconButton(
                tooltip: 'Capture image',
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: widget.onCapturePressed,
              ),
              IconButton(
                tooltip: 'Set as lock screen',
                icon: const Icon(Icons.wallpaper, color: Colors.white),
                onPressed: () => widget.onSetLockPressed(),
              ),
            ],
          ),

          // Scheduling controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final now = TimeOfDay.now();
                  final picked = await showTimePicker(context: context, initialTime: widget.scheduledTime ?? now);
                  if (picked != null) {
                    await widget.onScheduleAt(picked);
                  }
                },
                child: const Text('Schedule Daily Update'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: widget.isScheduled ? widget.onCancelSchedule : null,
                child: const Text('Cancel Schedule'),
              ),
            ],
          ),
          if (widget.isScheduled && widget.scheduledTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text('Scheduled at ${widget.scheduledTime!.format(context)}', style: const TextStyle(color: Colors.white70)),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _alignButton(IconData icon, TextAlign align) {
    return IconButton(
      icon: Icon(
        icon,
        color: widget.textAlign == align ? Colors.amber : Colors.white,
      ),
      onPressed: () => widget.onAlignmentChanged(align),
    );
  }

  Widget _colorDot(Color color) {
    return GestureDetector(
      onTap: () => widget.onColorChanged(color),
      child: CircleAvatar(
        backgroundColor: color,
        radius: 14,
        child: widget.textColor == color
            ? const Icon(Icons.check, color: Colors.black, size: 16)
            : null,
      ),
    );
  }
}