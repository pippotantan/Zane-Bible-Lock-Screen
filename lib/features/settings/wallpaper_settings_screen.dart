import 'package:flutter/material.dart';
import 'package:zane_bible_lockscreen/core/services/settings_service.dart';

class WallpaperSettingsScreen extends StatefulWidget {
  const WallpaperSettingsScreen({super.key});

  @override
  State<WallpaperSettingsScreen> createState() =>
      _WallpaperSettingsScreenState();
}

class _WallpaperSettingsScreenState extends State<WallpaperSettingsScreen> {
  WallpaperTarget selectedTarget = WallpaperTarget.both;
  bool isLoading = true;
  bool _isSaving = false;

  final availableFonts = ['Roboto', 'PlayfairDisplay', 'GreatVibes'];
  String selectedFont = 'Roboto'; // default

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _loadWallpaperTarget();

    try {
      final editorState = await SettingsService.loadEditorState();

      if (mounted) {
        final savedFont = editorState.fontFamily;

        setState(() {
          selectedFont = availableFonts.contains(savedFont)
              ? savedFont
              : 'Roboto';
        });
      }
    } catch (e) {
      print('[WallpaperSettingsScreen] Failed to load font: $e');
    }
  }

  Future<void> _saveFont(String font) async {
    try {
      final editorState = await SettingsService.loadEditorState();
      await SettingsService.saveEditorState(
        editorState.copyWith(fontFamily: font),
      );
      if (mounted) {
        setState(() {
          selectedFont = font;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Font updated to $font')));
      }
    } catch (e) {
      print('[WallpaperSettingsScreen] Failed to save font: $e');
    }
  }

  Future<void> _loadWallpaperTarget() async {
    try {
      final target = await SettingsService.getWallpaperTarget();
      if (mounted) {
        setState(() {
          selectedTarget = target;
          isLoading = false;
        });
      }
    } catch (e) {
      print('[WallpaperSettingsScreen] Failed to load target: $e');
      if (mounted) {
        setState(() {
          selectedTarget = WallpaperTarget.both;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _saveWallpaperTarget(WallpaperTarget target) async {
    setState(() => _isSaving = true);

    try {
      await SettingsService.setWallpaperTarget(target);
      if (mounted) {
        setState(() {
          selectedTarget = target;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallpaper target updated')),
        );
      }
    } catch (e) {
      print('[WallpaperSettingsScreen] Failed to save target: $e');
      if (mounted) setState(() => _isSaving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update target: $e')));
    }
  }

  Widget _buildRadioCard({
    required String title,
    required String subtitle,
    required WallpaperTarget value,
    IconData? icon,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: RadioListTile<WallpaperTarget>(
        title: Text(title),
        subtitle: Text(subtitle),
        secondary: icon != null ? Icon(icon, color: Colors.blue) : null,
        value: value,
        groupValue: selectedTarget,
        onChanged: _isSaving
            ? null
            : (target) {
                if (target != null) _saveWallpaperTarget(target);
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallpaper Settings')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Apply Background Updates To:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildRadioCard(
                    title: 'Lock Screen Only',
                    subtitle: 'Update only the lock screen background',
                    value: WallpaperTarget.lockScreenOnly,
                    icon: Icons.lock,
                  ),
                  _buildRadioCard(
                    title: 'Home Screen Only',
                    subtitle: 'Update only the home screen background',
                    value: WallpaperTarget.homeScreenOnly,
                    icon: Icons.home,
                  ),
                  _buildRadioCard(
                    title: 'Both',
                    subtitle:
                        'Update both lock screen and home screen backgrounds',
                    value: WallpaperTarget.both,
                    icon: Icons.smartphone,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'This setting applies to both manual wallpaper updates '
                      'and automatic daily wallpaper generation. When you use "Set Wallpaper" '
                      'or the scheduled automatic update runs, it will apply to your selected target location.',
                      style: TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ),
                  if (_isSaving)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Select Verse Font:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    value: selectedFont,
                    isExpanded: true,
                    items: availableFonts
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(f, style: TextStyle(fontFamily: f)),
                          ),
                        )
                        .toList(),
                    onChanged: (font) {
                      if (font != null) _saveFont(font);
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
