import 'package:workmanager/workmanager.dart';
import 'package:zane_bible_lockscreen/background/verse_worker.dart';

class WorkManagerService {
  static Future<void> scheduleDailyVerse() async {
    await Workmanager().registerPeriodicTask(
      'dailyVerseTask',
      dailyVerseTask,
      frequency: const Duration(hours: 24),
      initialDelay: _initialDelay(),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
      // Default schedule at 5:00 AM
      await scheduleDailyVerseAt(5, 0);
    }

  static Future<void> cancelDailyVerse() async {
    await Workmanager().cancelByUniqueName('dailyVerseTask');
  }

  static Duration _initialDelay() {
    final now = DateTime.now();
    final nextRun = DateTime(now.year, now.month, now.day, 5);
    return nextRun.isAfter(now)
        ? nextRun.difference(now)
        : nextRun.add(const Duration(days: 1)).difference(now);
  }

    static Future<void> scheduleDailyVerseAt(int hour, int minute) async {
      final initial = _initialDelayFor(hour, minute);
      await Workmanager().registerPeriodicTask(
        'dailyVerseTask',
        dailyVerseTask,
        frequency: const Duration(hours: 24),
        initialDelay: initial,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    }

    static Duration _initialDelayFor(int hour, int minute) {
      final now = DateTime.now();
      final nextRun = DateTime(now.year, now.month, now.day, hour, minute);
      return nextRun.isAfter(now)
          ? nextRun.difference(now)
          : nextRun.add(const Duration(days: 1)).difference(now);
    }
}