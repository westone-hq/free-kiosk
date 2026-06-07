import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> downloadTextFile(String filename, String contents) async {
  final dir = await getApplicationDocumentsDirectory();
  final folder = Directory('${dir.path}/kiosk_exports');
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }
  final file = File('${folder.path}/$filename');
  await file.writeAsString(contents, flush: true);
  return file.path;
}
