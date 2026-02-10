import 'package:workmanager/workmanager.dart';
import 'package:zane_bible_lockscreen/core/services/auto_wallpaper_service.dart';

const dailyVerseTask = 'dailyVerseWallpaper';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case dailyVerseTask:
        await AutoWallpaperService.run();
        break;
    }
    return Future.value(true);
  });
}
