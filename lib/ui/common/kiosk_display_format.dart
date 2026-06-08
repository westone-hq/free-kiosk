import 'package:kiosk/models/order_status.dart';

/// 화면에 보여 줄 때 긴 id·시간·상태를 짧고 읽기 쉽게.
class KioskDisplayFormat {
  KioskDisplayFormat._();

  /// `ord_1780881205411` → `#5411`
  static String orderShort(String orderId) {
    if (orderId.startsWith('ord_')) {
      final tail = orderId.substring(4);
      if (tail.length >= 4) {
        return '#${tail.substring(tail.length - 4)}';
      }
    }
    if (orderId.length <= 10) {
      return orderId;
    }
    return '…${orderId.substring(orderId.length - 6)}';
  }

  static String orderLabel(String orderId) => '주문 ${orderShort(orderId)}';

  /// `st_1780879251020000_2266` → `…2266`
  static String storeShort(String storeId) {
    final idx = storeId.lastIndexOf('_');
    if (idx >= 0 && idx < storeId.length - 1) {
      final tail = storeId.substring(idx + 1);
      return tail.length > 6 ? '…$tail' : tail;
    }
    if (storeId.length <= 12) {
      return storeId;
    }
    return '…${storeId.substring(storeId.length - 6)}';
  }

  static String storeLine({required String name, required String storeId}) {
    return '$name · 코드 ${storeShort(storeId)}';
  }

  static String orderStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.received:
        return '접수';
      case OrderStatus.cooking:
        return '조리중';
      case OrderStatus.done:
        return '완료';
      case OrderStatus.paid:
        return '결제완료';
      case OrderStatus.cancelled:
        return '취소';
    }
  }

  static String dateTime(DateTime t) {
    final local = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  static String timeHms(DateTime t) {
    final local = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }
}
