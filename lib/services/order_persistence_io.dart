import 'package:kiosk/services/kiosk_runtime_paths.dart';

Future<void> writeAppTextFile(String relativeFileName, String contents) async {
  final f = await runtimeDataFile(relativeFileName);
  await f.writeAsString(contents, flush: true);
}

Future<String?> readAppTextFile(String relativeFileName) async {
  final f = await runtimeDataFile(relativeFileName);
  if (!await f.exists()) {
    return null;
  }
  return f.readAsString();
}
