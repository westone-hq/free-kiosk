/// 실행 시 `--dart-define=KIOSK_FILE_SERVER=http://127.0.0.1:8765` 로
/// 웹에서도 프로젝트 `data/runtime/` 파일을 씁니다.
class KioskStorageConfig {
  KioskStorageConfig._();

  static const fileServerBase = String.fromEnvironment('KIOSK_FILE_SERVER');

  static const dataDir = String.fromEnvironment(
    'KIOSK_DATA_DIR',
    defaultValue: 'data/runtime',
  );

  static bool get useProjectFileServer => fileServerBase.isNotEmpty;
}
