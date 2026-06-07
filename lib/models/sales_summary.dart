import 'order_header.dart';

/// 기간·매장 기준 매출 집계 결과 (7.3)
class SalesSummary {
  const SalesSummary({
    required this.paidOrders,
    required this.cancelledOrders,
    required this.paidCount,
    required this.cancelledCount,
    required this.grossTotal,
    required this.cancelledTotal,
    required this.netTotal,
    required this.averagePaidOrder,
  });

  final List<OrderHeader> paidOrders;
  final List<OrderHeader> cancelledOrders;
  final int paidCount;
  final int cancelledCount;
  final int grossTotal;
  final int cancelledTotal;
  final int netTotal;
  final double averagePaidOrder;
}

int orderHeaderTotal(OrderHeader order) {
  return order.lines.fold<int>(0, (sum, line) => sum + line.lineTotal);
}
