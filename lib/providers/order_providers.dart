// lib/providers/order_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/services/services.dart';

final orderBookServiceProvider = Provider<OrderBookService>((ref) {
  return OrderBookService();
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

  Future<void> addOrder(OrderHeader order) async {
    state = [...state, order];
    await _save();
  }

  Future<void> removeOrder(String orderId) async {
    state = [
      for (final order in state)
        if (order.id != orderId) order,
    ];
    await _save();
  }

  Future<void> setStatus(String orderId, OrderStatus nextStatus) async {
    state = [
      for (final order in state)
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
