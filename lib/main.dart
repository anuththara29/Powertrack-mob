import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:power_app/src/notification_provider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'src/app.dart'; 
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Local Notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  runApp(
    ChangeNotifierProvider(
      create: (context) => NotificationProvider(),
      child: MyApp(settingsController: settingsController),
    ),
  );
}

