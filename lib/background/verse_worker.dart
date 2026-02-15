import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zane_bible_lockscreen/core/services/auto_wallpaper_service.dart';

const dailyVerseTask = 'dailyVerseWallpaper';

// Keys must match what SettingsService uses
const _scheduledHourKey = 'daily_scheduled_hour';
const _scheduledMinuteKey = 'daily_scheduled_minute';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Initialize Flutter bindings for background execution
    WidgetsFlutterBinding.ensureInitialized();

    try {
      print('[BackgroundWorker] Task received: $task');
      switch (task) {
        case dailyVerseTask:
          print('[BackgroundWorker] Starting AutoWallpaperService.run()');
          bool success = false;
          try {
            await AutoWallpaperService.run();
            print(
              '[BackgroundWorker] AutoWallpaperService.run() completed successfully',
            );
            success = true;
          } catch (e) {
            print('[BackgroundWorker] AutoWallpaperService.run() failed: $e');
            print('[BackgroundWorker] Will reschedule for retry in 2 minutes');
          }

          // Reschedule: if successful, schedule for next day; if failed, retry in 2 minutes
          if (success) {
            await _rescheduleForNextDay();
          } else {
            await _rescheduleForRetry();
          }
          break;
        default:
          print('[BackgroundWorker] Unknown task: $task');
          return Future.value(false); // Unknown task
      }
      return Future.value(true);
    } catch (e, stackTrace) {
      print('[BackgroundWorker] Task error: $e');
      print('[BackgroundWorker] Stack trace: $stackTrace');
      // Try to reschedule for retry in 2 minutes on error
      try {
        await _rescheduleForRetry();
      } catch (rescheduleError) {
        print('[BackgroundWorker] Failed to reschedule: $rescheduleError');
      }
      return Future.value(true);
    }
  });
}

Future<void> _rescheduleForNextDay() async {
  try {
    print('[BackgroundWorker] Rescheduling for next day');
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_scheduledHourKey) ?? 5;
    final minute = prefs.getInt(_scheduledMinuteKey) ?? 0;

    print(
      '[BackgroundWorker] Retrieved scheduled time: $hour:${minute.toString().padLeft(2, '0')}',
    );

    // Calculate delay to next occurrence of the scheduled time
    final now = DateTime.now();
    var nextRun = DateTime(now.year, now.month, now.day, hour, minute);

    // If scheduled time has already passed today, schedule for tomorrow
    if (nextRun.isBefore(now)) {
      nextRun = nextRun.add(const Duration(days: 1));
      print(
        '[BackgroundWorker] Scheduled time already passed, scheduling for tomorrow at $hour:${minute.toString().padLeft(2, '0')}',
      );
    } else {
      // Schedule for same time tomorrow
      nextRun = nextRun.add(const Duration(days: 1));
      print(
        '[BackgroundWorker] Scheduling for tomorrow at $hour:${minute.toString().padLeft(2, '0')}',
      );
    }

    final delay = nextRun.difference(now);
    print(
      '[BackgroundWorker] Delay to next execution: ${delay.inMinutes} minutes',
    );

    await Workmanager().registerOneOffTask(
      'dailyVerseTask',
      'dailyVerseWallpaper',
      initialDelay: delay,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    print('[BackgroundWorker] Successfully rescheduled task');
  } catch (e, stackTrace) {
    print('[BackgroundWorker] Error rescheduling: $e');
    print('[BackgroundWorker] Stack trace: $stackTrace');
  }
}

/// Reschedules the wallpaper update task for 2 minutes from now (for transient failures)
Future<void> _rescheduleForRetry() async {
  try {
    print('[BackgroundWorker] Rescheduling task for retry in 2 minutes');

    final delay = const Duration(minutes: 2);

    await Workmanager().registerOneOffTask(
      'dailyVerseTask',
      'dailyVerseWallpaper',
      initialDelay: delay,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    print(
      '[BackgroundWorker] Successfully rescheduled task for retry in 2 minutes',
    );
  } catch (e, stackTrace) {
    print('[BackgroundWorker] Error rescheduling for retry: $e');
    print('[BackgroundWorker] Stack trace: $stackTrace');
  }
}
