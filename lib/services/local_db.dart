// lib/services/local_db.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LocalDb {
  // 에셋 JSON 한 파일을 읽어 Map 으로 바꿉니다.
  Future<Map<String, dynamic>> _loadJson(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // menu_items.json 안의 items 배열만 꺼냅니다.
  Future<List<Map<String, dynamic>>> loadMenuItems() async {
    final json = await _loadJson('data/menu/menu_items.json');
    final items = (json['items'] as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
    return items;
  }
}
