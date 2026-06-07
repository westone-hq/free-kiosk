import 'package:shared_preferences/shared_preferences.dart';

/// 웹: 브라우저 localStorage(SharedPreferences)에 JSON 문자열 저장.
/// 키 = `kiosk_file_` + 파일명 (예: active_orders.json)
const _keyPrefix = 'kiosk_file_';

Future<void> writeAppTextFile(String relativeFileName, String contents) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('$_keyPrefix$relativeFileName', contents);
}

Future<String?> readAppTextFile(String relativeFileName) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('$_keyPrefix$relativeFileName');
}
