// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/router/app_router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: _KioskMaterialApp(),
    ),
  );
}

class _KioskMaterialApp extends StatelessWidget {
  const _KioskMaterialApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: kioskRouter,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
