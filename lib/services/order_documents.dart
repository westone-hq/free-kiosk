import 'package:kiosk/models/models.dart';

/// `data/orders/active.json` 전체
class ActiveOrdersDocument {
  const ActiveOrdersDocument({
    required this.version,
    required this.orders,
  });

  final int version;
  final List<OrderHeader> orders;

  factory ActiveOrdersDocument.fromJson(Map<String, dynamic> json) {
    final raw = json['orders'] as List<dynamic>? ?? <dynamic>[];
    return ActiveOrdersDocument(
      version: json['version'] as int? ?? 1,
      orders: raw
          .map(
            (e) =>
                OrderHeader.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'orders': orders.map((e) => e.toJson()).toList(growable: false),
      };
}

/// `data/history/order_archive.json` 전체
class OrderArchiveDocument {
  const OrderArchiveDocument({
    required this.version,
    required this.entries,
  });

  final int version;
  final List<OrderHeader> entries;

  factory OrderArchiveDocument.fromJson(Map<String, dynamic> json) {
    final raw = json['entries'] as List<dynamic>? ?? <dynamic>[];
    return OrderArchiveDocument(
      version: json['version'] as int? ?? 1,
      entries: raw
          .map(
            (e) =>
                OrderHeader.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'entries': entries.map((e) => e.toJson()).toList(growable: false),
      };
}
