// lib/models/order_header.dart
import 'order_line.dart';
import 'order_status.dart';

/// 주문 한 건 (상태·테이블·시간·요청·줄 목록)
class OrderHeader {
  OrderHeader({
    required this.id,
    required this.storeId,
    required this.tableNo,
    required this.status,
    required this.createdAt,
    this.note,
    required List<OrderLine> lines,
  }) : lines = List<OrderLine>.unmodifiable(lines);

  final String id;
  final String storeId;
  final String tableNo;
  final OrderStatus status;
  final DateTime createdAt;
  final String? note;
  final List<OrderLine> lines;

  factory OrderHeader.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? <dynamic>[];
    return OrderHeader(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      tableNo: json['tableNo'] as String,
      status: OrderStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String?,
      lines: rawLines
          .map((e) => OrderLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeId': storeId,
        'tableNo': tableNo,
        'status': status.toJson(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        if (note != null) 'note': note,
        'lines': lines.map((e) => e.toJson()).toList(growable: false),
      };
}
