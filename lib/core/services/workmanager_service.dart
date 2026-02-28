import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zane_bible_lockscreen/background/verse_worker.dart';

class WorkManagerService {
  static const _taskKey = 'dailyVerseTask';
  static const _scheduledHourKey = 'daily_scheduled_hour';
  static const _scheduledMinuteKey = 'daily_scheduled_minute';

  static Future<void> scheduleDailyVerse() async {
    // Default schedule at 5:00 AM
    await scheduleDailyVerseAt(5, 0);
  }

  static Future<void> cancelDailyVerse() async {
    print('[WorkManagerService] Cancelling daily verse task');
    await Workmanager().cancelByUniqueName(_taskKey);
    print('[WorkManagerService] Daily verse task cancelled');
  }

  static Future<void> scheduleDailyVerseAt(int hour, int minute) async {
    print(
      '[WorkManagerService] Scheduling daily verse at $hour:${minute.toString().padLeft(2, '0')}',
    );

    final initial = _initialDelayFor(hour, minute);
    print(
      '[WorkManagerService] Initial delay: ${initial.inSeconds} seconds (${(initial.inHours + (initial.inMinutes % 60) / 60).toStringAsFixed(1)} hours)',
    );

    try {
      // Save the scheduled time to SharedPreferences for later use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_scheduledHourKey, hour);
      await prefs.setInt(_scheduledMinuteKey, minute);
      print('[WorkManagerService] Saved scheduled time to SharedPreferences');

      // Cancel existing task before registering new one
      await Workmanager().cancelByUniqueName(_taskKey);

      print(
        '[WorkManagerService] Registering one-off task for tomorrow or later today',
      );

      // Use registerOneOffTask with exact time instead of periodic
      // This ensures execution at the exact scheduled time
      await Workmanager().registerOneOffTask(
        _taskKey,
        dailyVerseTask,
        initialDelay: initial,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      print('[WorkManagerService] Successfully registered daily verse task');
      print(
        '[WorkManagerService] Scheduled for $hour:${minute.toString().padLeft(2, '0')} daily',
      );
    } catch (e, stackTrace) {
      print('[WorkManagerService] Error registering task: $e');
      print('[WorkManagerService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Duration _initialDelayFor(int hour, int minute) {
    final now = DateTime.now();
    var nextRun = DateTime(now.year, now.month, now.day, hour, minute);

    // If the time has already passed today, schedule for tomorrow
    if (nextRun.isBefore(now)) {
      nextRun = nextRun.add(const Duration(days: 1));
      print(
        '[WorkManagerService] Scheduled time already passed today, scheduling for tomorrow at $hour:${minute.toString().padLeft(2, '0')}',
      );
    } else {
      print(
        '[WorkManagerService] Scheduling for today at $hour:${minute.toString().padLeft(2, '0')}',
      );
    }

    final delay = nextRun.difference(now);
    print(
      '[WorkManagerService] Delay calculated: ${delay.inMinutes} minutes from now',
    );
    return delay;
  }
}
