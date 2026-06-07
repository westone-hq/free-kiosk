// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kiosk/ui/admin/admin_app_entry.dart';
import 'package:kiosk/ui/admin/admin_signup_page.dart';

/// 다이얼로그는 TabBarView 안 context가 아니라 이 키로 띄웁니다.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Part 3 — `/` 내 매장, `/signup` 회원가입 (4장에서 `/customer` 등 추가)
final GoRouter kioskRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const AdminAppEntry();
      },
    ),
    GoRoute(
      path: '/signup',
      builder: (BuildContext context, GoRouterState state) {
        return const AdminSignupPage();
      },
    ),
  ],
);
