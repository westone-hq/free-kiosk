import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/providers/order_providers.dart';
import 'package:kiosk/services/sales_calculator.dart';

final salesPeriodFilterProvider = StateProvider<PeriodFilter>(
  (ref) => const PeriodFilter(preset: PeriodPreset.today),
);

final salesSummaryProvider =
    FutureProvider.family<SalesSummary, String>((ref, storeId) async {
  final archive = await ref.watch(archiveOrdersProvider.future);
  final period = ref.watch(salesPeriodFilterProvider);
  final range = resolvePeriodRange(period);
  return computeSalesSummary(
    archiveEntries: archive,
    storeId: storeId,
    range: range,
  );
});
