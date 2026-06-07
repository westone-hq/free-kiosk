import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/providers/providers.dart';
import 'package:kiosk/ui/pos/pos_table_card.dart';
import 'package:kiosk/ui/pos/pos_table_detail.dart';
import 'package:kiosk/ui/pos/pos_table_status.dart';

/// 4×4 기본 그리드 또는 gridX/gridY 커스텀 배치 (6.2)
class PosTableGrid extends ConsumerWidget {
  const PosTableGrid({super.key, required this.storeId});

  final String storeId;

  List<OrderHeader> _ordersForTable(
    List<OrderHeader> orders,
    String tableNo,
  ) {
    return orders
        .where(
          (o) =>
              o.storeId == storeId &&
              o.tableNo == tableNo &&
              o.status != OrderStatus.paid &&
              o.status != OrderStatus.cancelled,
        )
        .toList(growable: false);
  }

  Future<void> _onTableTap(
    BuildContext context,
    WidgetRef ref,
    String tableNo,
  ) async {
    final moveFrom = ref.read(posMoveFromTableProvider);
    if (moveFrom != null) {
      if (moveFrom.isEmpty) {
        ref.read(posMoveFromTableProvider.notifier).state = tableNo;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('출발: 테이블 $tableNo → 도착 테이블을 탭하세요.')),
          );
        }
        return;
      }
      if (moveFrom == tableNo) {
        ref.read(posMoveFromTableProvider.notifier).state = null;
        return;
      }
      await ref.read(activeOrdersProvider.notifier).moveOpenOrdersToTable(
            storeId: storeId,
            fromTableNo: moveFrom,
            toTableNo: tableNo,
          );
      ref.read(posMoveFromTableProvider.notifier).state = null;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('테이블 $moveFrom → $tableNo 로 주문을 옮겼습니다.')),
        );
      }
      return;
    }

    await showPosTableDetail(
      context: context,
      ref: ref,
      storeId: storeId,
      tableNo: tableNo,
    );
  }

  bool _passesFilter(PosTableStatus status, PosTableStatus? filter) {
    if (filter == null) {
      return true;
    }
    return status == filter;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(activeOrdersProvider);
    final tablesAsync = ref.watch(tablesProvider);
    final customLayout = ref.watch(posCustomLayoutProvider);
    final filter = ref.watch(posStatusFilterProvider);
    final moveFrom = ref.watch(posMoveFromTableProvider);

    return tablesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (tables) {
        if (customLayout) {
          return _CustomLayoutGrid(
            storeId: storeId,
            tables: tables.where((t) => !t.hidden).toList(growable: false),
            orders: orders,
            filter: filter,
            moveFrom: moveFrom,
            onTap: (tableNo) => _onTableTap(context, ref, tableNo),
            ordersForTable: _ordersForTable,
            passesFilter: _passesFilter,
          );
        }
        return _FixedGrid(
          storeId: storeId,
          tables: tables,
          orders: orders,
          filter: filter,
          moveFrom: moveFrom,
          onTap: (tableNo) => _onTableTap(context, ref, tableNo),
          ordersForTable: _ordersForTable,
          passesFilter: _passesFilter,
        );
      },
    );
  }
}

class _FixedGrid extends StatelessWidget {
  const _FixedGrid({
    required this.storeId,
    required this.tables,
    required this.orders,
    required this.filter,
    required this.moveFrom,
    required this.onTap,
    required this.ordersForTable,
    required this.passesFilter,
  });

  final String storeId;
  final List<TableInfo> tables;
  final List<OrderHeader> orders;
  final PosTableStatus? filter;
  final String? moveFrom;
  final void Function(String tableNo) onTap;
  final List<OrderHeader> Function(List<OrderHeader>, String) ordersForTable;
  final bool Function(PosTableStatus, PosTableStatus?) passesFilter;

  TableInfo? _infoFor(String tableNo) {
    for (final t in tables) {
      if (t.tableNo == tableNo) {
        return t;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const cols = 4;
    const rows = 4;
    final cells = <Widget>[];

    for (var i = 0; i < rows * cols; i++) {
      final tableNo = '${i + 1}';
      final info = _infoFor(tableNo);
      if (info?.hidden == true) {
        cells.add(const SizedBox.shrink());
        continue;
      }
      final label = info?.label ?? '테이블 $tableNo';
      final tableOrders = ordersForTable(orders, tableNo);
      final status = computePosTableStatus(orders, storeId, tableNo);
      if (!passesFilter(status, filter)) {
        cells.add(const SizedBox.shrink());
        continue;
      }
      cells.add(
        PosTableCard(
          tableNo: tableNo,
          label: label,
          status: status,
          orderCount: tableOrders.length,
          moveSelected: moveFrom == tableNo,
          onTap: () => onTap(tableNo),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: cols,
      padding: const EdgeInsets.all(12),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: cells,
    );
  }
}

class _CustomLayoutGrid extends StatelessWidget {
  const _CustomLayoutGrid({
    required this.storeId,
    required this.tables,
    required this.orders,
    required this.filter,
    required this.moveFrom,
    required this.onTap,
    required this.ordersForTable,
    required this.passesFilter,
  });

  final String storeId;
  final List<TableInfo> tables;
  final List<OrderHeader> orders;
  final PosTableStatus? filter;
  final String? moveFrom;
  final void Function(String tableNo) onTap;
  final List<OrderHeader> Function(List<OrderHeader>, String) ordersForTable;
  final bool Function(PosTableStatus, PosTableStatus?) passesFilter;

  @override
  Widget build(BuildContext context) {
    final placed = tables
        .where((t) => t.gridX != null && t.gridY != null)
        .toList(growable: false);
    if (placed.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '커스텀 배치를 쓰려면 tables.json 에 gridX·gridY 를 넣어 주세요.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    var maxX = 0;
    var maxY = 0;
    for (final t in placed) {
      maxX = math.max(maxX, t.gridX!);
      maxY = math.max(maxY, t.gridY!);
    }
    // 좌표가 2~3개만 있어도 4×4처럼 칸 크기가 유지되게 (빈 칸은 테두리만).
    const minCols = 4;
    const minRows = 4;
    final cols = math.max(maxX + 1, minCols);
    final rows = math.max(maxY + 1, minRows);

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemCount: cols * rows,
      itemBuilder: (context, index) {
        final gx = index % cols;
        final gy = index ~/ cols;
        TableInfo? info;
        for (final t in placed) {
          if (t.gridX == gx && t.gridY == gy) {
            info = t;
            break;
          }
        }
        if (info == null) {
          return DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox.expand(),
          );
        }
        final tableNo = info.tableNo;
        final label = info.label ?? '테이블 $tableNo';
        final tableOrders = ordersForTable(orders, tableNo);
        final status = computePosTableStatus(orders, storeId, tableNo);
        if (!passesFilter(status, filter)) {
          return const SizedBox.shrink();
        }
        return PosTableCard(
          tableNo: tableNo,
          label: label,
          status: status,
          orderCount: tableOrders.length,
          moveSelected: moveFrom == tableNo,
          onTap: () => onTap(tableNo),
        );
      },
    );
  }
}
