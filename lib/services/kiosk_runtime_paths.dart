import 'dart:io';

import 'package:kiosk/config/kiosk_storage_config.dart';

/// 프로젝트 `data/runtime/` 아래 실제 파일 경로.
Future<File> runtimeDataFile(String relativeFileName) async {
  final normalized = relativeFileName.replaceAll('\\', '/');
  final root = Directory(KioskStorageConfig.dataDir);
  if (!await root.exists()) {
    await root.create(recursive: true);
  }
  final file = File('${root.path}/$normalized');
  final parent = file.parent;
  if (!await parent.exists()) {
    await parent.create(recursive: true);
  }
  return file;
}
