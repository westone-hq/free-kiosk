// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kiosk/ui/admin/admin_app_entry.dart';
import 'package:kiosk/ui/admin/admin_signup_page.dart';
import 'package:kiosk/ui/customer/customer_order_page.dart';
import 'package:kiosk/ui/kitchen/kitchen_shell.dart';
import 'package:kiosk/ui/pos/pos_shell.dart';
import 'package:kiosk/providers/scoped_store_provider.dart';

/// 다이얼로그는 TabBarView 안 context가 아니라 이 키로 띄웁니다.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// `/` = 내 매장, `/signup` = 회원가입, `/customer` = 손님, `/kitchen` = 주방, `/pos` = POS
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
    GoRoute(
      path: '/customer',
      builder: (BuildContext context, GoRouterState state) {
        final q = state.uri.queryParameters;
        final storeId = q['storeId']?.trim();
        final tableNo = q['tableNo']?.trim();
        if (storeId == null ||
            storeId.isEmpty ||
            tableNo == null ||
            tableNo.isEmpty) {
          return const _MissingQueryPage();
        }
        return StoreScope(
          storeId: storeId,
          child: CustomerOrderPage(
            storeId: storeId,
            tableNo: tableNo,
          ),
        );
      },
    ),
    GoRoute(
      path: '/kitchen',
      builder: (BuildContext context, GoRouterState state) {
        final storeId = state.uri.queryParameters['storeId']?.trim();
        if (storeId == null || storeId.isEmpty) {
          return const KitchenShell();
        }
        return StoreScope(
          storeId: storeId,
          child: KitchenShell(expectedStoreId: storeId),
        );
      },
    ),
    GoRoute(
      path: '/pos',
      builder: (BuildContext context, GoRouterState state) {
        final storeId = state.uri.queryParameters['storeId']?.trim();
        if (storeId == null || storeId.isEmpty) {
          return const PosShell();
        }
        return StoreScope(
          storeId: storeId,
          child: PosShell(expectedStoreId: storeId),
        );
      },
    ),
  ],
);

class _MissingQueryPage extends StatelessWidget {
  const _MissingQueryPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '주소에 storeId 와 tableNo 가 필요합니다.\n예: /customer?storeId=store_001&tableNo=1',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}
