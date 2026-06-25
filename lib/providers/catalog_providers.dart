// lib/providers/catalog_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/services/services.dart';

final storeConfigProvider = FutureProvider<StoreConfigData>((ref) async {
  return loadStoreConfig();
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
  return loadMenuItems();
});

final tablesProvider = FutureProvider<List<TableInfo>>((ref) async {
  return loadTables();
});
