// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:kiosk/router/app_router.dart';

void main() {
  // 웹: /customer?storeId=... 처럼 # 없는 path URL 을 GoRouter 가 읽도록
  usePathUrlStrategy();
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
