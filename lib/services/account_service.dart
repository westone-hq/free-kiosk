// lib/services/account_service.dart
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:kiosk/models/app_account.dart';

import 'order_persistence.dart';
import 'store_initializer.dart';

/// 회원가입·로그인 — 승인 없이 가입 즉시 자신의 매장(storeId)이 생깁니다.
class AccountService {
  AccountService._();

  static const _file = 'kiosk_accounts.json';

  static Future<AccountsDocument> loadAccounts() async {
    final text = await readAppTextFile(_file);
    if (text != null && text.trim().isNotEmpty) {
      return AccountsDocument.fromJson(
        jsonDecode(text) as Map<String, dynamic>,
      );
    }
    return const AccountsDocument(version: 1, accounts: []);
  }

  static Future<void> saveAccounts(AccountsDocument doc) async {
    await writeAppTextFile(_file, jsonEncode(doc.toJson()));
  }

  static String _hashPassword(String salt, String password) {
    return sha256.convert(utf8.encode(salt + password)).toString();
  }

  static String _newId(String prefix) {
    final n = DateTime.now().microsecondsSinceEpoch;
    final r = Random().nextInt(9999);
    return '${prefix}_${n}_$r';
  }

  static String? _normalizeEmail(String email) {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || !e.contains('@')) {
      return null;
    }
    return e;
  }

  /// 가입 — 성공 시 [AppAccount], 이메일 중복·입력 오류 시 null
  static Future<AppAccount?> signup({
    required String email,
    required String password,
    required String ownerName,
    required String address,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final name = ownerName.trim();
    final addr = address.trim();
    if (normalizedEmail == null ||
        password.length < 4 ||
        name.isEmpty ||
        addr.isEmpty) {
      return null;
    }

    final doc = await loadAccounts();
    if (doc.accounts.any((a) => a.email == normalizedEmail)) {
      return null;
    }

    final salt = base64Url.encode(
      List<int>.generate(16, (_) => Random().nextInt(256)),
    );
    final storeId = _newId('st');
    final account = AppAccount(
      id: _newId('acc'),
      email: normalizedEmail,
      passwordSalt: salt,
      passwordHashHex: _hashPassword(salt, password),
      ownerName: name,
      address: addr,
      storeId: storeId,
      createdAt: DateTime.now(),
    );

    await initializeNewStore(
      storeId: storeId,
      storeName: name,
      address: addr,
    );

    await saveAccounts(
      AccountsDocument(
        version: doc.version,
        accounts: [...doc.accounts, account],
      ),
    );
    return account;
  }

  /// 로그인 — 성공 시 [AppAccount]
  static Future<AppAccount?> login(String email, String password) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null || password.isEmpty) {
      return null;
    }
    final doc = await loadAccounts();
    for (final account in doc.accounts) {
      if (account.email != normalizedEmail) {
        continue;
      }
      final inputHex = _hashPassword(account.passwordSalt, password);
      if (inputHex == account.passwordHashHex) {
        return account;
      }
    }
    return null;
  }
}
