import 'package:kiosk/providers/admin_session_provider.dart';

/// 주방 URL의 `storeId`와 로그인 매장이 같을 때만 `true`.
/// `urlStoreId`가 비어 있으면 세션만 있으면 통과.
bool kitchenUrlMatchesSession(AdminSession session, String? urlStoreId) {
  if (!session.hydrated || !session.isLoggedIn) {
    return false;
  }
  final sid = session.storeId;
  if (sid == null || sid.isEmpty) {
    return false;
  }
  final q = urlStoreId?.trim();
  if (q == null || q.isEmpty) {
    return true;
  }
  return sid == q;
}
