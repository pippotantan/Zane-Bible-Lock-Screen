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
  }

  static Duration _initialDelay() {
    final now = DateTime.now();
    final nextRun = DateTime(now.year, now.month, now.day, 5);
    return nextRun.isAfter(now)
        ? nextRun.difference(now)
        : nextRun.add(const Duration(days: 1)).difference(now);
  }
}