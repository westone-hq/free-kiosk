import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/providers/providers.dart';
import 'package:kiosk/ui/common/kiosk_display_format.dart';

/// 테이블 탭 → 주문 상세·결제 (6.3)
Future<void> showPosTableDetail({
  required BuildContext context,
  required WidgetRef ref,
  required String storeId,
  required String tableNo,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return _PosTableDetailBody(
            storeId: storeId,
            tableNo: tableNo,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

class _PosTableDetailBody extends ConsumerStatefulWidget {
  const _PosTableDetailBody({
    required this.storeId,
    required this.tableNo,
    required this.scrollController,
  });

  final String storeId;
  final String tableNo;
  final ScrollController scrollController;

  @override
  ConsumerState<_PosTableDetailBody> createState() =>
      _PosTableDetailBodyState();
}

class _PosTableDetailBodyState extends ConsumerState<_PosTableDetailBody> {
  final Set<String> _selectedLineKeys = {};

  String _lineKey(OrderHeader order, int lineIndex) {
    return '${order.id}_$lineIndex';
  }

  int _orderTotal(OrderHeader order) {
    return order.lines.fold<int>(0, (s, e) => s + e.lineTotal);
  }

  List<OrderHeader> _tableOrders(List<OrderHeader> all) {
    return all
        .where(
          (o) =>
              o.storeId == widget.storeId &&
              o.tableNo == widget.tableNo &&
              o.status != OrderStatus.paid &&
              o.status != OrderStatus.cancelled,
        )
        .toList(growable: false);
  }

  Set<int> _selectedIndexesForOrder(OrderHeader order) {
    final result = <int>{};
    for (var i = 0; i < order.lines.length; i++) {
      if (_selectedLineKeys.contains(_lineKey(order, i))) {
        result.add(i);
      }
    }
    return result;
  }

  Future<void> _payFull(OrderHeader order) async {
    await ref.read(activeOrdersProvider.notifier).payOrderFull(order.id);
    ref.invalidate(archiveOrdersProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${KioskDisplayFormat.orderLabel(order.id)} 전체 결제 완료')),
      );
    }
  }

  Future<void> _cancel(OrderHeader order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('주문 취소'),
        content: Text('${KioskDisplayFormat.orderLabel(order.id)} 을(를) 취소하고 매출 취소 집계에 넣을까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('아니오'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('취소 처리'),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    await ref.read(activeOrdersProvider.notifier).cancelOrder(order.id);
    ref.invalidate(archiveOrdersProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${KioskDisplayFormat.orderLabel(order.id)} 취소됨')),
      );
    }
  }

  Future<void> _payPartial(OrderHeader order) async {
    final indexes = _selectedIndexesForOrder(order);
    if (indexes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제할 줄을 선택하세요.')),
      );
      return;
    }
    await ref.read(activeOrdersProvider.notifier).paySelectedLines(
          order.id,
          indexes,
        );
    ref.invalidate(archiveOrdersProvider);
    setState(() {
      for (final i in indexes) {
        _selectedLineKeys.remove(_lineKey(order, i));
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택 항목 결제 완료')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(activeOrdersProvider);
    final mine = _tableOrders(orders);

    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '테이블 ${widget.tableNo} · 주문 상세',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '줄 선택 후 부분 결제 · − 는 수량 감소 · × 는 줄 삭제',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: mine.isEmpty
                ? const Center(child: Text('진행 중인 주문이 없습니다.'))
                : ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: mine.length,
                    itemBuilder: (context, oi) {
                      final order = mine[oi];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      KioskDisplayFormat.orderLabel(order.id),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(
                                      KioskDisplayFormat.orderStatus(
                                        order.status,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${KioskDisplayFormat.dateTime(order.createdAt)} · '
                                '합계 ${_orderTotal(order)}원',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const Divider(height: 16),
                              ...List.generate(order.lines.length, (li) {
                                final line = order.lines[li];
                                final key = _lineKey(order, li);
                                final selected =
                                    _selectedLineKeys.contains(key);
                                return CheckboxListTile(
                                  value: selected,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selectedLineKeys.add(key);
                                      } else {
                                        _selectedLineKeys.remove(key);
                                      }
                                    });
                                  },
                                  title: Text(
                                    '${line.nameSnapshot} × ${line.quantity}',
                                  ),
                                  subtitle: Text('${line.lineTotal}원'),
                                  secondary: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: '수량 −1',
                                        icon: const Icon(Icons.remove),
                                        onPressed: () async {
                                          await ref
                                              .read(activeOrdersProvider
                                                  .notifier)
                                              .decreaseLineQuantity(
                                                order.id,
                                                li,
                                              );
                                        },
                                      ),
                                      IconButton(
                                        tooltip: '줄 삭제',
                                        icon: const Icon(Icons.close),
                                        onPressed: () async {
                                          await ref
                                              .read(activeOrdersProvider
                                                  .notifier)
                                              .removeLine(order.id, li);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FilledButton(
                                    onPressed: () => _payFull(order),
                                    child: const Text('전체 결제'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => _payPartial(order),
                                    child: const Text('선택 항목 결제'),
                                  ),
                                  TextButton(
                                    onPressed: () => _cancel(order),
                                    child: const Text('주문 취소'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
