import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk/router/app_router.dart';

void main() {
  testWidgets('앱이 기동한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: kioskRouter,
        ),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
