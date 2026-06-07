import 'package:kiosk/models/models.dart';

/// [start, end) — end 는 **미포함**
class SalesDateRange {
  const SalesDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

/// `PeriodFilter` → 조회 구간 (로컬 날짜 기준)
SalesDateRange resolvePeriodRange(PeriodFilter filter, {DateTime? now}) {
  final anchor = now ?? DateTime.now();
  final todayStart = DateTime(anchor.year, anchor.month, anchor.day);

  switch (filter.preset) {
    case PeriodPreset.today:
      return SalesDateRange(
        start: todayStart,
        end: todayStart.add(const Duration(days: 1)),
      );
    case PeriodPreset.thisWeek:
      final weekday = anchor.weekday;
      final monday = todayStart.subtract(Duration(days: weekday - 1));
      return SalesDateRange(
        start: monday,
        end: monday.add(const Duration(days: 7)),
      );
    case PeriodPreset.thisMonth:
      final monthStart = DateTime(anchor.year, anchor.month, 1);
      final nextMonth = anchor.month == 12
          ? DateTime(anchor.year + 1, 1, 1)
          : DateTime(anchor.year, anchor.month + 1, 1);
      return SalesDateRange(
        start: monthStart,
        end: nextMonth,
      );
    case PeriodPreset.custom:
      final start = filter.rangeStart ?? todayStart;
      final end = filter.rangeEnd ?? todayStart.add(const Duration(days: 1));
      final endExclusive = end.hour == 0 && end.minute == 0 && end.second == 0
          ? end.add(const Duration(days: 1))
          : end;
      return SalesDateRange(start: start, end: endExclusive);
  }
}

bool _inRange(DateTime createdAt, SalesDateRange range) {
  return !createdAt.isBefore(range.start) && createdAt.isBefore(range.end);
}

SalesSummary computeSalesSummary({
  required List<OrderHeader> archiveEntries,
  required String storeId,
  required SalesDateRange range,
}) {
  final paid = <OrderHeader>[];
  final cancelled = <OrderHeader>[];

  for (final entry in archiveEntries) {
    if (entry.storeId != storeId) {
      continue;
    }
    if (!_inRange(entry.createdAt.toLocal(), range)) {
      continue;
    }
    if (entry.status == OrderStatus.paid) {
      paid.add(entry);
    } else if (entry.status == OrderStatus.cancelled) {
      cancelled.add(entry);
    }
  }

  final gross = paid.fold<int>(0, (s, o) => s + orderHeaderTotal(o));
  final cancelAmt =
      cancelled.fold<int>(0, (s, o) => s + orderHeaderTotal(o));

  return SalesSummary(
    paidOrders: paid,
    cancelledOrders: cancelled,
    paidCount: paid.length,
    cancelledCount: cancelled.length,
    grossTotal: gross,
    cancelledTotal: cancelAmt,
    netTotal: gross - cancelAmt,
    averagePaidOrder: paid.isEmpty ? 0 : gross / paid.length,
  );
}

String buildSalesCsv(SalesSummary summary) {
  final buffer = StringBuffer();
  buffer.writeln('주문ID,일시,테이블,상태,금액,메뉴요약');
  void writeRow(OrderHeader o) {
    final lines = o.lines
        .map((l) => '${l.nameSnapshot}x${l.quantity}')
        .join(' / ');
    buffer.writeln(
      '"${o.id}","${o.createdAt.toLocal()}","${o.tableNo}","${o.status.name}",'
      '${orderHeaderTotal(o)},"$lines"',
    );
  }
  for (final o in summary.paidOrders) {
    writeRow(o);
  }
  for (final o in summary.cancelledOrders) {
    writeRow(o);
  }
  return buffer.toString();
}
