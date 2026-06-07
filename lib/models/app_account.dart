// lib/models/app_account.dart
class AppAccount {
  const AppAccount({
    required this.id,
    required this.email,
    required this.passwordSalt,
    required this.passwordHashHex,
    required this.ownerName,
    required this.address,
    required this.storeId,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String passwordSalt;
  final String passwordHashHex;
  final String ownerName;
  final String address;
  final String storeId;
  final DateTime createdAt;

  factory AppAccount.fromJson(Map<String, dynamic> json) {
    return AppAccount(
      id: json['id'] as String,
      email: json['email'] as String,
      passwordSalt: json['passwordSalt'] as String,
      passwordHashHex: json['passwordHashHex'] as String,
      ownerName: json['ownerName'] as String,
      address: json['address'] as String,
      storeId: json['storeId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'passwordSalt': passwordSalt,
        'passwordHashHex': passwordHashHex,
        'ownerName': ownerName,
        'address': address,
        'storeId': storeId,
        'createdAt': createdAt.toIso8601String(),
      };
}

class AccountsDocument {
  const AccountsDocument({
    required this.version,
    required this.accounts,
  });

  final int version;
  final List<AppAccount> accounts;

  factory AccountsDocument.fromJson(Map<String, dynamic> json) {
    final raw = json['accounts'] as List<dynamic>? ?? <dynamic>[];
    return AccountsDocument(
      version: json['version'] as int? ?? 1,
      accounts: raw
          .map(
            (e) => AppAccount.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'accounts': accounts.map((e) => e.toJson()).toList(growable: false),
      };
}
