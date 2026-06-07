// lib/providers/order_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/services/services.dart';

import 'scoped_store_provider.dart';

final orderBookServiceProvider = Provider<OrderBookService>((ref) {
  final storeId = ref.watch(scopedStoreIdProvider);
  if (storeId == null || storeId.isEmpty) {
    return OrderBookService(storeId: '_unset');
  }
  return OrderBookService(storeId: storeId);
});

class ActiveOrdersController extends StateNotifier<List<OrderHeader>> {
  ActiveOrdersController(this._service) : super(const []) {
    _load();
  }

  final OrderBookService _service;

  Future<void> _load() async {
    final doc = await _service.loadActiveOrders();
    state = doc.orders;
  }

  Future<void> reload() async {
    await _load();
  }

  Future<void> _syncFromDisk() async {
    final doc = await _service.loadActiveOrders();
    state = doc.orders;
  }

  /// 저장본을 먼저 읽어 합칩니다. (여러 탭/창에서 주문할 때 덮어쓰기 방지)
  Future<void> addOrder(OrderHeader order) async {
    final doc = await _service.loadActiveOrders();
    state = [...doc.orders, order];
    await _save();
  }

  Future<void> removeOrder(String orderId) async {
    final doc = await _service.loadActiveOrders();
    state = [
      for (final order in doc.orders)
        if (order.id != orderId) order,
    ];
    await _save();
  }

  Future<void> setStatus(String orderId, OrderStatus nextStatus) async {
    final doc = await _service.loadActiveOrders();
    state = [
      for (final order in doc.orders)
        if (order.id == orderId)
          OrderHeader(
            id: order.id,
            storeId: order.storeId,
            tableNo: order.tableNo,
            status: nextStatus,
            createdAt: order.createdAt,
            note: order.note,
            lines: order.lines,
          )
        else
          order,
    ];
    await _save();
  }

  static bool _isOpen(OrderHeader order) {
    return order.status != OrderStatus.paid &&
        order.status != OrderStatus.cancelled;
  }

  OrderHeader? _findOrder(String orderId) {
    for (final order in state) {
      if (order.id == orderId) {
        return order;
      }
    }
    return null;
  }

  OrderHeader _copyOrder(OrderHeader order, {List<OrderLine>? lines}) {
    return OrderHeader(
      id: order.id,
      storeId: order.storeId,
      tableNo: order.tableNo,
      status: order.status,
      createdAt: order.createdAt,
      note: order.note,
      lines: lines ?? order.lines,
    );
  }

  Future<void> updateOrderLines(String orderId, List<OrderLine> lines) async {
    await _syncFromDisk();
    final order = _findOrder(orderId);
    if (order == null) {
      return;
    }
    if (lines.isEmpty) {
      await removeOrder(orderId);
      return;
    }
    state = [
      for (final o in state)
        if (o.id == orderId) _copyOrder(order, lines: lines) else o,
    ];
    await _save();
  }

  Future<void> decreaseLineQuantity(String orderId, int lineIndex) async {
    await _syncFromDisk();
    final order = _findOrder(orderId);
    if (order == null || lineIndex < 0 || lineIndex >= order.lines.length) {
      return;
    }
    final next = <OrderLine>[];
    for (var i = 0; i < order.lines.length; i++) {
      final line = order.lines[i];
      if (i == lineIndex) {
        if (line.quantity > 1) {
          next.add(
            OrderLine(
              menuId: line.menuId,
              nameSnapshot: line.nameSnapshot,
              unitPrice: line.unitPrice,
              quantity: line.quantity - 1,
            ),
          );
        }
      } else {
        next.add(line);
      }
    }
    await updateOrderLines(orderId, next);
  }

  Future<void> removeLine(String orderId, int lineIndex) async {
    await _syncFromDisk();
    final order = _findOrder(orderId);
    if (order == null || lineIndex < 0 || lineIndex >= order.lines.length) {
      return;
    }
    final next = [
      for (var i = 0; i < order.lines.length; i++)
        if (i != lineIndex) order.lines[i],
    ];
    await updateOrderLines(orderId, next);
  }

  Future<void> _appendArchive(OrderHeader entry) async {
    final archive = await _service.loadArchive();
    await _service.saveArchive(
      OrderArchiveDocument(
        version: archive.version,
        entries: [...archive.entries, entry],
      ),
    );
  }

  Future<void> payOrderFull(String orderId) async {
    await _syncFromDisk();
    final order = _findOrder(orderId);
    if (order == null || !_isOpen(order)) {
      return;
    }
    await removeOrder(orderId);
    await _appendArchive(
      OrderHeader(
        id: order.id,
        storeId: order.storeId,
        tableNo: order.tableNo,
        status: OrderStatus.paid,
        createdAt: order.createdAt,
        note: order.note,
        lines: order.lines,
      ),
    );
  }

  Future<void> paySelectedLines(String orderId, Set<int> lineIndexes) async {
    await _syncFromDisk();
    final order = _findOrder(orderId);
    if (order == null || lineIndexes.isEmpty) {
      return;
    }
    final paidLines = <OrderLine>[];
    final remain = <OrderLine>[];
    for (var i = 0; i < order.lines.length; i++) {
      if (lineIndexes.contains(i)) {
        paidLines.add(order.lines[i]);
      } else {
        remain.add(order.lines[i]);
      }
    }
    if (paidLines.isEmpty) {
      return;
    }
    final paidEntry = OrderHeader(
      id: '${order.id}_partial_${DateTime.now().millisecondsSinceEpoch}',
      storeId: order.storeId,
      tableNo: order.tableNo,
      status: OrderStatus.paid,
      createdAt: DateTime.now(),
      note: order.note,
      lines: paidLines,
    );
    await _appendArchive(paidEntry);
    if (remain.isEmpty) {
      await removeOrder(orderId);
      return;
    }
    await updateOrderLines(orderId, remain);
  }

  Future<void> moveOpenOrdersToTable({
    required String storeId,
    required String fromTableNo,
    required String toTableNo,
  }) async {
    await _syncFromDisk();
    state = [
      for (final order in state)
        if (_isOpen(order) &&
            order.storeId == storeId &&
            order.tableNo == fromTableNo)
          OrderHeader(
            id: order.id,
            storeId: order.storeId,
            tableNo: toTableNo,
            status: order.status,
            createdAt: order.createdAt,
            note: order.note,
            lines: order.lines,
          )
        else
          order,
    ];
    await _save();
  }

  Future<void> _save() async {
    final doc = ActiveOrdersDocument(
      version: 2,
      orders: state,
    );
    await _service.saveActiveOrders(doc);
  }
}

final activeOrdersProvider =
    StateNotifierProvider<ActiveOrdersController, List<OrderHeader>>(
  (ref) => ActiveOrdersController(ref.watch(orderBookServiceProvider)),
);

final unpaidOrdersProvider = Provider<List<OrderHeader>>((ref) {
  final orders = ref.watch(activeOrdersProvider);
  return orders.where((order) {
    return order.status != OrderStatus.paid &&
        order.status != OrderStatus.cancelled;
  }).toList(growable: false);
});

final archiveOrdersProvider = FutureProvider<List<OrderHeader>>((ref) async {
  final service = ref.watch(orderBookServiceProvider);
  final doc = await service.loadArchive();
  return doc.entries;
});
