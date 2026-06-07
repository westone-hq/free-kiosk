// lib/ui/customer/order_submit.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/providers/providers.dart';

String _combineNotes(List<CartLine> lines) {
  final parts = <String>[];
  for (final e in lines) {
    if (e.lineNote != null && e.lineNote!.trim().isNotEmpty) {
      parts.add('${e.nameSnapshot}: ${e.lineNote!.trim()}');
    }
  }
  if (parts.isEmpty) {
    return '';
  }
  return parts.join('\n');
}

Future<void> confirmAndSubmitOrder({
  required BuildContext context,
  required WidgetRef ref,
  required String storeId,
  required String tableNo,
}) async {
  final lines = ref.read(customerCartProvider);
  if (lines.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('장바구니가 비었습니다.')),
    );
    return;
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('주문할까요?'),
      content: Text(
        '총 ${lines.fold<int>(0, (s, e) => s + e.quantity)}개 · '
        '${lines.fold<int>(0, (s, e) => s + e.lineTotal)}원',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('주문'),
        ),
      ],
    ),
  );

  if (ok != true) {
    return;
  }

  final header = OrderHeader(
    id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
    storeId: storeId,
    tableNo: tableNo,
    status: OrderStatus.received,
    createdAt: DateTime.now(),
    note: _combineNotes(lines).isEmpty ? null : _combineNotes(lines),
    lines: [
      for (final c in lines)
        OrderLine(
          menuId: c.menuId,
          nameSnapshot: c.nameSnapshot,
          unitPrice: c.unitPrice,
          quantity: c.quantity,
        ),
    ],
  );

  try {
    await ref.read(activeOrdersProvider.notifier).addOrder(header);
    ref.read(customerCartProvider.notifier).clear();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주문을 접수했습니다.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }
}
