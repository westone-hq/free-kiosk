import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/providers/customer_cart_provider.dart';

/// 손님 장바구니 확인·수량 조절 (7장 테스트용)
Future<void> showCustomerCartSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final cart = ref.watch(customerCartProvider);
          final total =
              cart.fold<int>(0, (sum, line) => sum + line.lineTotal);
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
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
                              '장바구니',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (cart.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                ref.read(customerCartProvider.notifier).clear();
                              },
                              child: const Text('비우기'),
                            ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: cart.isEmpty
                          ? const Center(
                              child: Text('담은 메뉴가 없습니다.\n메뉴를 탭해 담아 보세요.'),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: cart.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final line = cart[i];
                                return ListTile(
                                  title: Text(line.nameSnapshot),
                                  subtitle: Text('${line.unitPrice}원 · ${line.lineNote ?? ''}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () {
                                          ref
                                              .read(customerCartProvider
                                                  .notifier)
                                              .setQty(
                                                line.menuId,
                                                line.quantity - 1,
                                              );
                                        },
                                      ),
                                      Text('${line.quantity}'),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          ref
                                              .read(customerCartProvider
                                                  .notifier)
                                              .setQty(
                                                line.menuId,
                                                line.quantity + 1,
                                              );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '합계 $total원',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
