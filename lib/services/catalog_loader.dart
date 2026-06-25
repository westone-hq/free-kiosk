// lib/services/catalog_loader.dart
import 'dart:convert';

import 'package:kiosk/models/models.dart';

import 'asset_paths.dart';
import 'order_persistence.dart';
import 'json_from_asset.dart';

/// `store.json` 한 파일을 풀었을 때의 모양 (파일 버전 + 매장 + 카테고리 배열)
class StoreConfigData {
  const StoreConfigData({
    required this.fileVersion,
    required this.store,
    required this.categories,
  });

  /// JSON 맨 위 `version` (파일 형식 구분용)
  final int fileVersion;
  final Store store;
  final List<Category> categories;
}

StoreConfigData storeConfigDataFromMap(Map<String, dynamic> map) {
  final storeRaw = map['store'];
  if (storeRaw is! Map) {
    throw FormatException('store: store 필드가 없습니다.');
  }
  final cats = map['categories'] as List<dynamic>? ?? <dynamic>[];
  return StoreConfigData(
    fileVersion: map['version'] as int? ?? 1,
    store: Store.fromJson(Map<String, dynamic>.from(storeRaw)),
    categories: cats
        .map((e) => Category.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false),
  );
}

Future<StoreConfigData> loadStoreConfig() async {
  const k = 'store_config.json';
  final p = await readAppTextFile(k);
  if (p != null && p.trim().isNotEmpty) {
    return storeConfigDataFromMap(jsonDecode(p) as Map<String, dynamic>);
  }
  final map = await loadRootJsonMap(AssetPaths.storeJson);
  return storeConfigDataFromMap(map);
}

Future<void> saveStoreConfig(StoreConfigData data) async {
  final map = {
    'version': data.fileVersion,
    'store': data.store.toJson(),
    'categories': data.categories.map((c) => c.toJson()).toList(),
  };
  await writeAppTextFile('store_config.json', jsonEncode(map));
}

List<MenuItem> _menuListFromMap(Map<String, dynamic> map) {
  final items = map['items'] as List<dynamic>? ?? <dynamic>[];
  return items
      .map((e) => MenuItem.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(growable: false);
}

Future<List<MenuItem>> loadMenuItems() async {
  const k = 'menu_items.json';
  final p = await readAppTextFile(k);
  if (p != null && p.trim().isNotEmpty) {
    return _menuListFromMap(jsonDecode(p) as Map<String, dynamic>);
  }
  final map = await loadRootJsonMap(AssetPaths.menuItemsJson);
  return _menuListFromMap(map);
}

Future<void> saveMenuItems(
  List<MenuItem> items, {
  required int fileVersion,
}) async {
  final map = {
    'version': fileVersion,
    'items': items.map((e) => e.toJson()).toList(),
  };
  await writeAppTextFile('menu_items.json', jsonEncode(map));
}

class TablesDocument {
  TablesDocument({required this.version, required this.tables});
  final int version;
  final List<TableInfo> tables;

  Map<String, dynamic> toJson() => {
        'version': version,
        'tables': tables.map((e) => e.toJson()).toList(growable: false),
      };

  static TablesDocument fromJson(Map<String, dynamic> json) {
    final raw = json['tables'] as List<dynamic>? ?? <dynamic>[];
    return TablesDocument(
      version: json['version'] as int? ?? 1,
      tables: raw
          .map((e) => TableInfo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
    );
  }
}

Future<List<TableInfo>> loadTables() async {
  const k = 'tables.json';
  final p = await readAppTextFile(k);
  if (p != null && p.trim().isNotEmpty) {
    return TablesDocument.fromJson(jsonDecode(p) as Map<String, dynamic>).tables;
  }
  final map = await loadRootJsonMap(AssetPaths.tablesJson);
  return TablesDocument.fromJson(map).tables;
}

Future<void> saveTables(
  List<TableInfo> tables, {
  required int fileVersion,
}) async {
  final doc = TablesDocument(version: fileVersion, tables: tables);
  await writeAppTextFile('tables.json', jsonEncode(doc.toJson()));
}
