import 'package:flutter/material.dart';

import 'router.dart';

class EnvPollutionApp extends StatelessWidget {
  const EnvPollutionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Environment Pollution',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Garamond',
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8E8E8),
          primary: const Color.fromARGB(255, 240, 240, 240),
          brightness: Brightness.light,
        ),
      ),
      routerConfig: createRouter(),
    );
  }
}
