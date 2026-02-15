import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:zane_bible_lockscreen/features/editor/verse_editor_state.dart';

class SettingsService {
  static const _useEditorForDailyKey = 'use_editor_for_daily';
  static const _fontSizeKey = 'editor_font_size';
  static const _textAlignKey = 'editor_text_align';
  static const _textColorKey = 'editor_text_color';
  static const _fontFamilyKey = 'editor_font_family';
  static const _isScheduledKey = 'daily_is_scheduled';
  static const _scheduledHourKey = 'daily_scheduled_hour';
  static const _scheduledMinuteKey = 'daily_scheduled_minute';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<bool> getUseEditorForDaily() async {
    final p = await _prefs();
    return p.getBool(_useEditorForDailyKey) ?? false;
  }

  static Future<void> setUseEditorForDaily(bool value) async {
    final p = await _prefs();
    await p.setBool(_useEditorForDailyKey, value);
  }

  static Future<VerseEditorState> loadEditorState() async {
    final p = await _prefs();
    final fontSize = p.getDouble(_fontSizeKey) ?? 22.0;
    final alignStr = p.getString(_textAlignKey) ?? 'center';
    final textColorValue = p.getInt(_textColorKey) ?? Colors.white.value;
    final fontFamily = p.getString(_fontFamilyKey) ?? 'sans';

    TextAlign align;
    switch (alignStr) {
      case 'left':
        align = TextAlign.left;
        break;
      case 'right':
        align = TextAlign.right;
        break;
      case 'center':
      default:
        align = TextAlign.center;
    }

    return VerseEditorState(
      fontSize: fontSize,
      textAlign: align,
      textColor: Color(textColorValue),
      fontFamily: fontFamily,
    );
  }

  static Future<void> saveEditorState(VerseEditorState state) async {
    final p = await _prefs();
    await p.setDouble(_fontSizeKey, state.fontSize);
    final alignStr = state.textAlign == TextAlign.left
        ? 'left'
        : state.textAlign == TextAlign.right
            ? 'right'
            : 'center';
    await p.setString(_textAlignKey, alignStr);
    await p.setInt(_textColorKey, state.textColor.value);
    await p.setString(_fontFamilyKey, state.fontFamily);
  }

  static Future<void> setScheduled(bool value) async {
    final p = await _prefs();
    await p.setBool(_isScheduledKey, value);
  }

  static Future<bool> getScheduled() async {
    final p = await _prefs();
    return p.getBool(_isScheduledKey) ?? false;
  }

  static Future<void> setScheduledTime(int hour, int minute) async {
    final p = await _prefs();
    await p.setInt(_scheduledHourKey, hour);
    await p.setInt(_scheduledMinuteKey, minute);
  }

  static Future<TimeOfDay?> getScheduledTime() async {
    final p = await _prefs();
    if (!p.containsKey(_scheduledHourKey) || !p.containsKey(_scheduledMinuteKey)) return null;
    final h = p.getInt(_scheduledHourKey)!;
    final m = p.getInt(_scheduledMinuteKey)!;
    return TimeOfDay(hour: h, minute: m);
  }
}
