// lib/ui/customer/customer_order_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/providers/providers.dart';

import 'customer_menu_screen.dart';
import 'order_submit.dart';

/// `/customer?storeId=&tableNo=`
class CustomerOrderPage extends ConsumerWidget {
  const CustomerOrderPage({
    super.key,
    required this.storeId,
    required this.tableNo,
  });

  final String storeId;
  final String tableNo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(storeProvider);
    final cart = ref.watch(customerCartProvider);

    return storeAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('매장 정보를 불러오지 못했습니다: $e')),
      ),
      data: (store) {
        if (store.id != storeId) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '주소의 storeId($storeId)와 저장된 매장 id(${store.id})가 다릅니다.\n'
                  '3.3 저장본·store.json 을 확인하세요.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text('${store.name} · 테이블 $tableNo'),
            actions: [
              IconButton(
                tooltip: '이 테이블 진행 중 주문',
                icon: const Icon(Icons.list_alt_outlined),
                onPressed: () {
                  final orders = ref.read(activeOrdersProvider);
                  final mine = orders
                      .where(
                        (o) =>
                            o.storeId == storeId && o.tableNo == tableNo,
                      )
                      .toList(growable: false);
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (sheetCtx) {
                      if (mine.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('진행 중인 주문이 없습니다.'),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: mine.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final o = mine[i];
                          return ListTile(
                            title: Text(
                              o.id,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              '상태: ${o.status.name} · 줄 수 ${o.lines.length}',
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
          body: CustomerMenuScreen(
            storeId: storeId,
            tableNo: tableNo,
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      cart.isEmpty
                          ? '장바구니 비움'
                          : '${cart.length}종 · '
                              '${cart.fold<int>(0, (s, e) => s + e.lineTotal)}원',
                    ),
                  ),
                  FilledButton(
                    onPressed: cart.isEmpty
                        ? null
                        : () => confirmAndSubmitOrder(
                              context: context,
                              ref: ref,
                              storeId: storeId,
                              tableNo: tableNo,
                            ),
                    child: const Text('주문하기'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
