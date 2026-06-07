import 'dart:convert';

import 'package:flutter/services.dart';

/// 에셋 JSON 파일을 읽어 **맨 바깥이 Map** 인지 확인한 뒤 돌려줍니다.
Future<Map<String, dynamic>> loadRootJsonMap(String assetPath) async {
  final raw = await rootBundle.loadString(assetPath);
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw FormatException(
      '$assetPath: JSON 맨 바깥은 { } 한 덩어리(객체)여야 합니다.',
    );
  }
  return Map<String, dynamic>.from(decoded);
}
