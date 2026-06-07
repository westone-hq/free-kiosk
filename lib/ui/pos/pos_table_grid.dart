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
      skipLoadingOnReload: true,
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

  Widget _cell({
    required String tableNo,
    required String label,
    required PosTableStatus status,
    required int orderCount,
    required bool visible,
  }) {
    return Visibility(
      visible: visible,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      child: PosTableCard(
        tableNo: tableNo,
        label: label,
        status: status,
        orderCount: orderCount,
        moveSelected: moveFrom == tableNo,
        onTap: () => onTap(tableNo),
      ),
    );
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
        cells.add(const SizedBox(height: 1, width: 1));
        continue;
      }
      final label = info?.label ?? '테이블 $tableNo';
      final tableOrders = ordersForTable(orders, tableNo);
      final status = computePosTableStatus(orders, storeId, tableNo);
      cells.add(
        _cell(
          tableNo: tableNo,
          label: label,
          status: status,
          orderCount: tableOrders.length,
          visible: passesFilter(status, filter),
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

/// gridX·gridY 좌표만큼 **딱 맞는** 배치도 (빈 4×4 칸을 억지로 늘리지 않음)
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
    final unplaced = tables
        .where((t) => t.gridX == null || t.gridY == null)
        .toList(growable: false);

    if (placed.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            unplaced.isEmpty
                ? '표시할 테이블이 없습니다.'
                : '배치도를 쓰려면 테이블·QR 탭에서 gridX·gridY 를 넣거나,\n'
                    '「행 추가」 시 좌표가 자동으로 붙습니다.',
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
    final cols = maxX + 1;
    final rows = maxY + 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        const padding = 12.0;
        const minCell = 80.0;
        final innerW = constraints.maxWidth - padding * 2;
        final cellSize = math.max(
          minCell,
          (innerW - spacing * (cols - 1)) / cols,
        );
        final totalW = cols * cellSize + spacing * (cols - 1);
        final totalH = rows * cellSize + spacing * (rows - 1);

        Widget tableAt(int gx, int gy) {
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
            );
          }
          final tableNo = info.tableNo;
          final label = info.label ?? '테이블 $tableNo';
          final tableOrders = ordersForTable(orders, tableNo);
          final status = computePosTableStatus(orders, storeId, tableNo);
          return Visibility(
            visible: passesFilter(status, filter),
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: PosTableCard(
              tableNo: tableNo,
              label: label,
              status: status,
              orderCount: tableOrders.length,
              moveSelected: moveFrom == tableNo,
              onTap: () => onTap(tableNo),
            ),
          );
        }

        final stackChildren = <Widget>[];
        for (var gy = 0; gy < rows; gy++) {
          for (var gx = 0; gx < cols; gx++) {
            stackChildren.add(
              Positioned(
                left: gx * (cellSize + spacing),
                top: gy * (cellSize + spacing),
                width: cellSize,
                height: cellSize,
                child: tableAt(gx, gy),
              ),
            );
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: totalW,
                  height: totalH,
                  child: Stack(children: stackChildren),
                ),
              ),
              if (unplaced.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '좌표 없음 (4×4에서만 번호로 표시): '
                  '${unplaced.map((t) => t.tableNo).join(', ')}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
