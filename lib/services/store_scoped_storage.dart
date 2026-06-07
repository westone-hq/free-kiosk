// lib/services/store_scoped_storage.dart
/// 매장(storeId)마다 로컬 파일 키를 나눕니다.
String storeScopedKey(String storeId, String fileName) {
  return 'stores/$storeId/$fileName';
}
