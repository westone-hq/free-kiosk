// lib/providers/scoped_store_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_providers.dart';
import 'menu_filter_provider.dart';
import 'order_providers.dart';

/// 현재 화면이 다루는 매장 id — 로그인·손님 URL·POS/주방 진입 시 설정.
final scopedStoreIdProvider = StateProvider<String?>((ref) => null);

/// [storeId] 범위를 잡고 catalog·주문 provider 를 새로 읽게 합니다.
class StoreScope extends ConsumerStatefulWidget {
  const StoreScope({
    super.key,
    required this.storeId,
    required this.child,
  });

  final String storeId;
  final Widget child;

  @override
  ConsumerState<StoreScope> createState() => _StoreScopeState();
}

class _StoreScopeState extends ConsumerState<StoreScope> {
  void _applyScope() {
    final current = ref.read(scopedStoreIdProvider);
    if (current == widget.storeId) {
      return;
    }
    ref.read(scopedStoreIdProvider.notifier).state = widget.storeId;
    ref.invalidate(storeConfigProvider);
    ref.invalidate(storeProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(menuItemsProvider);
    ref.invalidate(tablesProvider);
    ref.invalidate(filteredMenuItemsProvider);
    ref.invalidate(activeOrdersProvider);
    ref.invalidate(archiveOrdersProvider);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyScope());
  }

  @override
  void didUpdateWidget(StoreScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storeId != widget.storeId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyScope());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
