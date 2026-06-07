final Map<String, String> _memoryFiles = <String, String>{};

/// 상대 파일 이름 → 내용 (stub / 웹에서 사용)
Future<void> writeAppTextFile(String relativeFileName, String contents) async {
  _memoryFiles[relativeFileName] = contents;
}

Future<String?> readAppTextFile(String relativeFileName) async {
  return _memoryFiles[relativeFileName];
}
