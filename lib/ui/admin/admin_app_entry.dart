// lib/ui/admin/admin_app_entry.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/providers/admin_session_provider.dart';
import 'package:kiosk/providers/scoped_store_provider.dart';
import 'package:kiosk/ui/admin/admin_home_shell.dart';
import 'package:kiosk/ui/admin/admin_login_page.dart';

class AdminAppEntry extends ConsumerWidget {
  const AdminAppEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(adminSessionProvider);

    if (!s.hydrated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (s.isLoggedIn && s.storeId != null) {
      return StoreScope(
        storeId: s.storeId!,
        child: AdminHomeShell(
          storeId: s.storeId!,
          ownerName: s.ownerName,
        ),
      );
    }
    return const AdminLoginPage();
  }
}
