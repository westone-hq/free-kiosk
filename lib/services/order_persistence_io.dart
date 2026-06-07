import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<File> _localFile(String fileName) async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory('${base.path}/kiosk_local');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return File('${dir.path}/$fileName');
}

Future<void> writeAppTextFile(String relativeFileName, String contents) async {
  final f = await _localFile(relativeFileName);
  await f.writeAsString(contents, flush: true);
}

Future<String?> readAppTextFile(String relativeFileName) async {
  final f = await _localFile(relativeFileName);
  if (!await f.exists()) {
    return null;
  }
  return f.readAsString();
}
