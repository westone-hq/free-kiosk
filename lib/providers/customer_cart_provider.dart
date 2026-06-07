// lib/providers/customer_cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';

class CartLine {
  const CartLine({
    required this.menuId,
    required this.nameSnapshot,
    required this.unitPrice,
    required this.quantity,
    this.lineNote,
  });

  final String menuId;
  final String nameSnapshot;
  final int unitPrice;
  final int quantity;
  final String? lineNote;

  int get lineTotal => unitPrice * quantity;
}

class CustomerCartNotifier extends StateNotifier<List<CartLine>> {
  CustomerCartNotifier() : super(const <CartLine>[]);

  void upsert(MenuItem m, int addQty, {String? lineNote}) {
    if (addQty <= 0) {
      return;
    }
    final next = List<CartLine>.from(state);
    final i = next.indexWhere((e) => e.menuId == m.id);
    if (i < 0) {
      next.add(
        CartLine(
          menuId: m.id,
          nameSnapshot: m.name,
          unitPrice: m.price,
          quantity: addQty,
          lineNote: lineNote,
        ),
      );
    } else {
      final old = next[i];
      next[i] = CartLine(
        menuId: old.menuId,
        nameSnapshot: old.nameSnapshot,
        unitPrice: old.unitPrice,
        quantity: old.quantity + addQty,
        lineNote: lineNote ?? old.lineNote,
      );
    }
    state = next;
  }

  void setQty(String menuId, int qty) {
    if (qty <= 0) {
      remove(menuId);
      return;
    }
    state = [
      for (final e in state)
        if (e.menuId == menuId)
          CartLine(
            menuId: e.menuId,
            nameSnapshot: e.nameSnapshot,
            unitPrice: e.unitPrice,
            quantity: qty,
            lineNote: e.lineNote,
          )
        else
          e,
    ];
  }

  void remove(String menuId) {
    state = [
      for (final e in state)
        if (e.menuId != menuId) e,
    ];
  }

  void clear() {
    state = const <CartLine>[];
  }

  int get total =>
      state.fold<int>(0, (s, e) => s + e.lineTotal);
}

final customerCartProvider =
    StateNotifierProvider<CustomerCartNotifier, List<CartLine>>(
  (ref) => CustomerCartNotifier(),
);
