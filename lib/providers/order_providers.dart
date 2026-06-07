// lib/providers/order_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/services/services.dart';

import 'scoped_store_provider.dart';

// 주문 읽기/저장 서비스를 provider로 노출 (현재 scoped storeId 기준)
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
