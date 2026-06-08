import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/providers/providers.dart';
import 'package:kiosk/services/sales_calculator.dart';
import 'package:kiosk/services/sales_file_download.dart';
import 'package:kiosk/ui/common/kiosk_display_format.dart';

/// 관리자 2번 탭 — 매출 통계 (7.1~7.4)
class AdminSalesTab extends ConsumerWidget {
  const AdminSalesTab({super.key, required this.storeId});

  final String storeId;

  String _presetLabel(PeriodPreset p) {
    switch (p) {
      case PeriodPreset.today:
        return '일';
      case PeriodPreset.thisWeek:
        return '주';
      case PeriodPreset.thisMonth:
        return '월';
      case PeriodPreset.custom:
        return '기간';
    }
  }

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 6)),
        end: now,
      ),
    );
    if (picked == null) {
      return;
    }
    ref.read(salesPeriodFilterProvider.notifier).state = PeriodFilter(
      preset: PeriodPreset.custom,
      rangeStart: picked.start,
      rangeEnd: picked.end,
    );
  }

  Future<void> _exportCsv(
    BuildContext context,
    SalesSummary summary,
  ) async {
    final csv = buildSalesCsv(summary);
    final name =
        'sales_${storeId}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final path = await downloadTextFile(name, csv);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('내보냈습니다: $path')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(salesPeriodFilterProvider);
    final summaryAsync = ref.watch(salesSummaryProvider(storeId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final p in PeriodPreset.values)
                FilterChip(
                  label: Text(_presetLabel(p)),
                  selected: period.preset == p,
                  onSelected: (_) {
                    if (p == PeriodPreset.custom) {
                      _pickCustomRange(context, ref);
                      return;
                    }
                    ref.read(salesPeriodFilterProvider.notifier).state =
                        PeriodFilter(preset: p);
                  },
                ),
              IconButton(
                tooltip: '새로고침',
                onPressed: () => ref.invalidate(archiveOrdersProvider),
                icon: const Icon(Icons.refresh),
              ),
              FilledButton.tonalIcon(
                onPressed: summaryAsync.maybeWhen(
                  data: (s) => () => _exportCsv(context, s),
                  orElse: () => null,
                ),
                icon: const Icon(Icons.download),
                label: const Text('엑셀(CSV) 내보내기'),
              ),
            ],
          ),
        ),
        if (period.preset == PeriodPreset.custom &&
            period.rangeStart != null &&
            period.rangeEnd != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '선택: ${period.rangeStart!.toLocal().toString().split(' ').first}'
              ' ~ ${period.rangeEnd!.toLocal().toString().split(' ').first}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: summaryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (summary) => _SalesBody(summary: summary),
          ),
        ),
      ],
    );
  }
}

class _SalesBody extends StatelessWidget {
  const _SalesBody({required this.summary});

  final SalesSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              title: '결제 건수',
              value: '${summary.paidCount}건',
              subtitle: 'paid만 매출 포함',
            ),
            _StatCard(
              title: '총 매출',
              value: '${summary.grossTotal}원',
            ),
            _StatCard(
              title: '평균 단가',
              value: summary.paidCount == 0
                  ? '-'
                  : '${summary.averagePaidOrder.round()}원',
            ),
            _StatCard(
              title: '취소',
              value: '${summary.cancelledCount}건 · ${summary.cancelledTotal}원',
              subtitle: 'cancelled 별도',
            ),
            _StatCard(
              title: '순매출',
              value: '${summary.netTotal}원',
              subtitle: '총매출 − 취소',
              highlight: true,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('결제 내역', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (summary.paidOrders.isEmpty)
          Text(
            '이 기간에 paid 기록이 없습니다.\n'
            '손님 주문 → POS 결제 후 archive에 쌓입니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...summary.paidOrders.map(
            (o) => _OrderTile(order: o, statusColor: Colors.green.shade700),
          ),
        const SizedBox(height: 16),
        Text('취소 내역', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (summary.cancelledOrders.isEmpty)
          Text(
            '취소(cancelled) 기록 없음 — POS 주문 상세에서 취소 가능',
            style: theme.textTheme.bodySmall,
          )
        else
          ...summary.cancelledOrders.map(
            (o) => _OrderTile(order: o, statusColor: Colors.red.shade700),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.highlight = false,
  });

  final String title;
  final String value;
  final String? subtitle;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlight
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.statusColor});

  final OrderHeader order;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final total = orderHeaderTotal(order);
    final lines = order.lines
        .map((l) => '${l.nameSnapshot}×${l.quantity}')
        .join(', ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          '테이블 ${order.tableNo} · ${KioskDisplayFormat.orderShort(order.id)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                KioskDisplayFormat.dateTime(order.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                lines,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$total원',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              KioskDisplayFormat.orderStatus(order.status),
              style: TextStyle(color: statusColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
