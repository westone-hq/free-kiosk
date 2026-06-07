// lib/services/order_book_service.dart
import 'dart:convert';

import 'asset_paths.dart';
import 'json_from_asset.dart';
import 'order_documents.dart';
import 'order_persistence.dart';
import 'store_scoped_storage.dart';

/// 진행 중 주문(active) · 히스토리(archive) 읽기/저장 — storeId 별 파일.
class OrderBookService {
  OrderBookService({required this.storeId});

  final String storeId;

  static const _fileActive = 'active_orders.json';
  static const _fileArchive = 'order_archive.json';

  String _scoped(String name) => storeScopedKey(storeId, name);

  Future<ActiveOrdersDocument> loadActiveOrders() async {
    final persisted = await readAppTextFile(_scoped(_fileActive));
    if (persisted != null && persisted.trim().isNotEmpty) {
      return ActiveOrdersDocument.fromJson(
        jsonDecode(persisted) as Map<String, dynamic>,
      );
    }

    const legacyActive = 'active_orders.json';
    final legacy = await readAppTextFile(legacyActive);
    if (legacy != null && legacy.trim().isNotEmpty) {
      return ActiveOrdersDocument.fromJson(
        jsonDecode(legacy) as Map<String, dynamic>,
      );
    }

    final map = await loadRootJsonMap(AssetPaths.activeOrdersJson);
    final storeMap = await loadRootJsonMap(AssetPaths.storeJson);
    final assetStoreId = (storeMap['store'] as Map?)?['id'] as String?;
    if (assetStoreId == storeId) {
      return ActiveOrdersDocument.fromJson(map);
    }
    return const ActiveOrdersDocument(version: 1, orders: []);
  }

  Future<void> saveActiveOrders(ActiveOrdersDocument doc) async {
    final text = jsonEncode(doc.toJson());
    await writeAppTextFile(_scoped(_fileActive), text);
  }

  Future<OrderArchiveDocument> loadArchive() async {
    final persisted = await readAppTextFile(_scoped(_fileArchive));
    if (persisted != null && persisted.trim().isNotEmpty) {
      return OrderArchiveDocument.fromJson(
        jsonDecode(persisted) as Map<String, dynamic>,
      );
    }

    const legacyArchive = 'order_archive.json';
    final legacy = await readAppTextFile(legacyArchive);
    if (legacy != null && legacy.trim().isNotEmpty) {
      return OrderArchiveDocument.fromJson(
        jsonDecode(legacy) as Map<String, dynamic>,
      );
    }

    final map = await loadRootJsonMap(AssetPaths.orderArchiveJson);
    final storeMap = await loadRootJsonMap(AssetPaths.storeJson);
    final assetStoreId = (storeMap['store'] as Map?)?['id'] as String?;
    if (assetStoreId == storeId) {
      return OrderArchiveDocument.fromJson(map);
    }
    return const OrderArchiveDocument(version: 1, entries: []);
  }

  Future<void> saveArchive(OrderArchiveDocument doc) async {
    final text = jsonEncode(doc.toJson());
    await writeAppTextFile(_scoped(_fileArchive), text);
  }
}
