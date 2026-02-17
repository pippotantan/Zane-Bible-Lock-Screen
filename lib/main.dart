import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zane_bible_lockscreen/app.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zane_bible_lockscreen/background/verse_worker.dart';
import 'package:zane_bible_lockscreen/core/services/workmanager_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request necessary permissions
  await _requestPermissions();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // Set to false for production
  );

  // Restore any previously scheduled tasks on app startup
  await _restoreScheduledTasks();

  runApp(const DailyFaithApp());
}

Future<void> _requestPermissions() async {
  try {
    print('[Main] Requesting permissions');

    // Request storage permissions
    final storageStatus = await Permission.storage.request();
    print('[Main] Storage permission: $storageStatus');

    // Request photos/media permission for Android 13+
    final photosStatus = await Permission.photos.request();
    print('[Main] Photos permission: $photosStatus');

    // Request notification permission for Android 13+
    final notificationStatus = await Permission.notification.request();
    print('[Main] Notification permission: $notificationStatus');

    // Request background execution permission
    final scheduleExactAlarmStatus = await Permission.scheduleExactAlarm
        .request();
    print('[Main] Schedule exact alarm permission: $scheduleExactAlarmStatus');

    // Request ignore battery optimizations for reliable background execution
    final batteryOptStatus = await Permission.ignoreBatteryOptimizations
        .request();
    print('[Main] Ignore battery optimizations permission: $batteryOptStatus');

    print('[Main] All permissions requested');
  } catch (e) {
    print('[Main] Error requesting permissions: $e');
  }
}

Future<void> _restoreScheduledTasks() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final isScheduled = prefs.getBool('daily_is_scheduled') ?? false;
    final hour = prefs.getInt('daily_scheduled_hour');
    final minute = prefs.getInt('daily_scheduled_minute');

    if (isScheduled && hour != null && minute != null) {
      print(
        '[Main] Restoring scheduled task: $hour:${minute.toString().padLeft(2, '0')}',
      );
      await WorkManagerService.scheduleDailyVerseAt(hour, minute);
      print('[Main] Task restored successfully');
    }
  } catch (e) {
    print('[Main] Error restoring tasks: $e');
  }
}
