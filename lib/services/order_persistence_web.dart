import 'package:kiosk/config/kiosk_storage_config.dart';
import 'package:kiosk/services/order_persistence_project_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyPrefix = 'kiosk_file_';

Future<void> writeAppTextFile(String relativeFileName, String contents) async {
  if (KioskStorageConfig.useProjectFileServer) {
    await writeAppTextFileViaProjectServer(relativeFileName, contents);
    return;
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('$_keyPrefix$relativeFileName', contents);
}

Future<String?> readAppTextFile(String relativeFileName) async {
  if (KioskStorageConfig.useProjectFileServer) {
    return readAppTextFileViaProjectServer(relativeFileName);
  }
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('$_keyPrefix$relativeFileName');
}
