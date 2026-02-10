import 'package:flutter/material.dart';
import 'package:zane_bible_lockscreen/app.dart';
import 'package:workmanager/workmanager.dart';
import 'background/verse_worker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // turn OFF in release
  );
  runApp(const ZaneBibleApp());
}
