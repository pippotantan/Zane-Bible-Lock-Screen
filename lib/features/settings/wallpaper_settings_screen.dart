import 'package:flutter/material.dart';
import 'package:zane_bible_lockscreen/core/services/settings_service.dart';
import 'package:zane_bible_lockscreen/core/utils/bible_topics.dart';

class WallpaperSettingsScreen extends StatefulWidget {
  const WallpaperSettingsScreen({super.key});

  @override
  State<WallpaperSettingsScreen> createState() =>
      _WallpaperSettingsScreenState();
}

class _WallpaperSettingsScreenState extends State<WallpaperSettingsScreen> {
  WallpaperTarget selectedTarget = WallpaperTarget.both;
  String selectedVerseTopic = BibleTopics.all;
  bool isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final target = await SettingsService.getWallpaperTarget();
      final topic = await SettingsService.getVerseTopic();
      if (mounted) {
        setState(() {
          selectedTarget = target;
          selectedVerseTopic = topic;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          selectedTarget = WallpaperTarget.both;
          selectedVerseTopic = BibleTopics.all;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _saveVerseTopic(String topicId) async {
    setState(() => _isSaving = true);
    try {
      await SettingsService.setVerseTopic(topicId);
      if (mounted) {
        setState(() {
          selectedVerseTopic = topicId;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verse topic updated')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update topic: $e')),
      );
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
                    'Verse by topic or keyword',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Filter which verses appear on manual and automatic wallpapers. Default: all 66 books.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: BibleTopics.topicIds.contains(selectedVerseTopic)
                            ? selectedVerseTopic
                            : BibleTopics.all,
                        underline: const SizedBox(),
                        items: BibleTopics.topicIds.map((id) {
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(BibleTopics.labelFor(id)),
                          );
                        }).toList(),
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value != null) _saveVerseTopic(value);
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
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
                      'and automatic daily wallpaper generation.',
                      style: TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ),
                  if (_isSaving)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
    );
  }
}
