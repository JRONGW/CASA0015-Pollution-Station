import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'notifications/local_notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLocalNotifications();
  await requestNotificationPermission();
  runApp(
    const ProviderScope(
      child: EnvPollutionApp(),
    ),
  );
}
