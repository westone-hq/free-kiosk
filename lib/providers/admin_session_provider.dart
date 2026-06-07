// lib/providers/admin_session_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kiosk/services/services.dart';

class AdminSession {
  const AdminSession({
    this.hydrated = false,
    this.isLoggedIn = false,
    this.accountId,
    this.ownerName,
    this.storeId,
  });

  /// SharedPreferences 에서 **첫** 복원이 끝났는지
  final bool hydrated;
  final bool isLoggedIn;
  final String? accountId;
  final String? ownerName;
  final String? storeId;

  AdminSession copyWith({
    bool? hydrated,
    bool? isLoggedIn,
    String? accountId,
    String? ownerName,
    String? storeId,
    bool clearAccountId = false,
    bool clearOwnerName = false,
    bool clearStoreId = false,
  }) {
    return AdminSession(
      hydrated: hydrated ?? this.hydrated,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      ownerName: clearOwnerName ? null : (ownerName ?? this.ownerName),
      storeId: clearStoreId ? null : (storeId ?? this.storeId),
    );
  }
}

class AdminSessionController extends StateNotifier<AdminSession> {
  AdminSessionController() : super(const AdminSession()) {
    _restore();
  }

  static const _kLoggedIn = 'admin_session_loggedIn';
  static const _kStoreId = 'admin_session_storeId';
  static const _kAccountId = 'admin_session_accountId';
  static const _kOwnerName = 'admin_session_ownerName';

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final logged = prefs.getBool(_kLoggedIn) ?? false;
    final sid = prefs.getString(_kStoreId) ?? '';
    final accountId = prefs.getString(_kAccountId) ?? '';
    final ownerName = prefs.getString(_kOwnerName) ?? '';
    if (logged && sid.isNotEmpty) {
      state = AdminSession(
        hydrated: true,
        isLoggedIn: true,
        accountId: accountId.isEmpty ? null : accountId,
        ownerName: ownerName.isEmpty ? null : ownerName,
        storeId: sid,
      );
    } else {
      state = const AdminSession(hydrated: true);
    }
  }

  Future<void> _persistSession({
    required String accountId,
    required String ownerName,
    required String storeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kStoreId, storeId);
    await prefs.setString(_kAccountId, accountId);
    await prefs.setString(_kOwnerName, ownerName);
    state = AdminSession(
      hydrated: true,
      isLoggedIn: true,
      accountId: accountId,
      ownerName: ownerName,
      storeId: storeId,
    );
  }

  /// 이메일 로그인 — 성공이면 true
  Future<bool> login(String email, String password) async {
    final account = await AccountService.login(email, password);
    if (account == null) {
      return false;
    }
    await _persistSession(
      accountId: account.id,
      ownerName: account.ownerName,
      storeId: account.storeId,
    );
    return true;
  }

  /// 회원가입 후 바로 로그인 — 성공이면 true
  Future<bool> signup({
    required String email,
    required String password,
    required String ownerName,
    required String address,
  }) async {
    final account = await AccountService.signup(
      email: email,
      password: password,
      ownerName: ownerName,
      address: address,
    );
    if (account == null) {
      return false;
    }
    await _persistSession(
      accountId: account.id,
      ownerName: account.ownerName,
      storeId: account.storeId,
    );
    return true;
  }

  /// 로그아웃 — 메모리 + SharedPreferences
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedIn);
    await prefs.remove(_kStoreId);
    await prefs.remove(_kAccountId);
    await prefs.remove(_kOwnerName);
    state = const AdminSession(hydrated: true);
  }
}

final adminSessionProvider =
    StateNotifierProvider<AdminSessionController, AdminSession>(
  (ref) => AdminSessionController(),
);
