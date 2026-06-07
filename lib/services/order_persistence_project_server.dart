import 'package:http/http.dart' as http;
import 'package:kiosk/config/kiosk_storage_config.dart';

Uri _fileUri(String relativeFileName) {
  final normalized = relativeFileName.replaceAll('\\', '/');
  final segments = normalized.split('/').where((s) => s.isNotEmpty);
  return Uri.parse(KioskStorageConfig.fileServerBase).replace(
    pathSegments: [
      ...Uri.parse(KioskStorageConfig.fileServerBase).pathSegments
          .where((s) => s.isNotEmpty),
      'files',
      ...segments,
    ],
  );
}

Future<void> writeAppTextFileViaProjectServer(
  String relativeFileName,
  String contents,
) async {
  final resp = await http.put(
    _fileUri(relativeFileName),
    headers: const {'Content-Type': 'text/plain; charset=utf-8'},
    body: contents,
  );
  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    throw StateError(
      '파일 저장 실패 ($relativeFileName): HTTP ${resp.statusCode}',
    );
  }
}

Future<String?> readAppTextFileViaProjectServer(
  String relativeFileName,
) async {
  final resp = await http.get(_fileUri(relativeFileName));
  if (resp.statusCode == 404) {
    return null;
  }
  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    throw StateError(
      '파일 읽기 실패 ($relativeFileName): HTTP ${resp.statusCode}',
    );
  }
  return resp.body;
}
