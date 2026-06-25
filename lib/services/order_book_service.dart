// lib/services/order_book_service.dart
import 'dart:convert';

import 'asset_paths.dart';
import 'json_from_asset.dart';
import 'order_documents.dart';
import 'order_persistence.dart';

/// 진행 중 주문(active) · 히스토리(archive) 읽기/저장
class OrderBookService {
  static const _fileActive = 'active_orders.json';
  static const _fileArchive = 'order_archive.json';

  Future<ActiveOrdersDocument> loadActiveOrders() async {
    final persisted = await readAppTextFile(_fileActive);
    if (persisted != null && persisted.trim().isNotEmpty) {
      return ActiveOrdersDocument.fromJson(
        jsonDecode(persisted) as Map<String, dynamic>,
      );
    }
    final map = await loadRootJsonMap(AssetPaths.activeOrdersJson);
    return ActiveOrdersDocument.fromJson(map);
  }

  Future<void> saveActiveOrders(ActiveOrdersDocument doc) async {
    final text = jsonEncode(doc.toJson());
    await writeAppTextFile(_fileActive, text);
  }

  Future<OrderArchiveDocument> loadArchive() async {
    final persisted = await readAppTextFile(_fileArchive);
    if (persisted != null && persisted.trim().isNotEmpty) {
      return OrderArchiveDocument.fromJson(
        jsonDecode(persisted) as Map<String, dynamic>,
      );
    }
    final map = await loadRootJsonMap(AssetPaths.orderArchiveJson);
    return OrderArchiveDocument.fromJson(map);
  }

  Future<void> saveArchive(OrderArchiveDocument doc) async {
    final text = jsonEncode(doc.toJson());
    await writeAppTextFile(_fileArchive, text);
  }
}
