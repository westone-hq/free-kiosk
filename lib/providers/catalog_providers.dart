// lib/providers/catalog_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/services/services.dart';

import 'scoped_store_provider.dart';

String _requireStoreId(Ref ref) {
  final storeId = ref.watch(scopedStoreIdProvider);
  if (storeId == null || storeId.isEmpty) {
    throw StateError('매장 범위(storeId)가 설정되지 않았습니다.');
  }
  return storeId;
}

final storeConfigProvider = FutureProvider<StoreConfigData>((ref) async {
  return loadStoreConfig(storeId: _requireStoreId(ref));
});

final storeProvider = FutureProvider<Store>((ref) async {
  final config = await ref.watch(storeConfigProvider.future);
  return config.store;
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final config = await ref.watch(storeConfigProvider.future);
  return config.categories;
});

final menuItemsProvider = FutureProvider<List<MenuItem>>((ref) async {
  return loadMenuItems(storeId: _requireStoreId(ref));
});

final tablesProvider = FutureProvider<List<TableInfo>>((ref) async {
  return loadTables(storeId: _requireStoreId(ref));
});
