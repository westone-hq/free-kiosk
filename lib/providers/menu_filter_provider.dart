import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';

import 'catalog_providers.dart';

final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

final filteredMenuItemsProvider = FutureProvider<List<MenuItem>>((ref) async {
  final items = await ref.watch(menuItemsProvider.future);
  final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

  final visible = items.where((item) {
    if (!item.enabled || item.soldOut) {
      return false;
    }
    if (selectedCategoryId == null || selectedCategoryId.isEmpty) {
      return true;
    }
    return item.categoryId == selectedCategoryId;
  });

  return visible.toList(growable: false);
});
