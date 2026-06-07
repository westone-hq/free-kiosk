import 'package:flutter/material.dart';
import 'package:kiosk/models/models.dart';

import 'kitchen_order_card.dart';

/// `received`·`cooking` 주문만 오래된 순 가로 스크롤 (5.2)
class KitchenOrdersStrip extends StatelessWidget {
  const KitchenOrdersStrip({
    super.key,
    required this.orders,
    required this.pulseOrderIds,
    required this.storeId,
  });

  final List<OrderHeader> orders;
  final Set<String> pulseOrderIds;
  final String storeId;

  List<OrderHeader> _filteredSorted() {
    final mine = orders
        .where(
          (o) =>
              o.storeId == storeId &&
              (o.status == OrderStatus.received ||
                  o.status == OrderStatus.cooking),
        )
        .toList();
    mine.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return mine;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredSorted();
    if (list.isEmpty) {
      return Center(
        child: Text(
          '조리 대기·조리 중인 주문이 없습니다.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, i) {
        final o = list[i];
        return KitchenOrderCard(
          order: o,
          emphasizeNew: pulseOrderIds.contains(o.id),
        );
      },
    );
  }
}
