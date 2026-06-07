// lib/ui/provider_check_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/providers/providers.dart';

class ProviderCheckPage extends ConsumerWidget {
  const ProviderCheckPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // provider에서 값을 읽어 옵니다.
    final storeAsync = ref.watch(storeProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final menusAsync = ref.watch(filteredMenuItemsProvider);
    final activeOrders = ref.watch(activeOrdersProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod 확인')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          storeAsync.when(
            data: (store) => Text('매장: ${store.name}'),
            loading: () => const Text('매장 읽는 중...'),
            error: (e, _) => Text('매장 읽기 실패: $e'),
          ),
          const SizedBox(height: 12),
          categoriesAsync.when(
            data: (categories) {
              return Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('전체'),
                    selected: selectedCategoryId == null,
                    onSelected: (_) {
                      ref.read(selectedCategoryIdProvider.notifier).state = null;
                    },
                  ),
                  for (final c in categories)
                    ChoiceChip(
                      label: Text(c.name),
                      selected: selectedCategoryId == c.id,
                      onSelected: (_) {
                        ref.read(selectedCategoryIdProvider.notifier).state = c.id;
                      },
                    ),
                ],
              );
            },
            loading: () => const Text('카테고리 읽는 중...'),
            error: (e, _) => Text('카테고리 읽기 실패: $e'),
          ),
          const SizedBox(height: 12),
          menusAsync.when(
            data: (menus) => Text('지금 보이는 메뉴 수: ${menus.length}'),
            loading: () => const Text('메뉴 읽는 중...'),
            error: (e, _) => Text('메뉴 읽기 실패: $e'),
          ),
          const SizedBox(height: 12),
          Text('진행 중 주문 수: ${activeOrders.length}'),
        ],
      ),
    );
  }
}
