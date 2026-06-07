import 'package:kiosk/models/models.dart';

/// POS 테이블 카드에 쓰는 상태 (빈 테이블 + 진행 중 주문 단계)
enum PosTableStatus {
  empty,
  received,
  cooking,
  done,
}

PosTableStatus computePosTableStatus(
  List<OrderHeader> orders,
  String storeId,
  String tableNo,
) {
  final open = orders.where(
    (o) =>
        o.storeId == storeId &&
        o.tableNo == tableNo &&
        o.status != OrderStatus.paid &&
        o.status != OrderStatus.cancelled,
  );
  if (open.isEmpty) {
    return PosTableStatus.empty;
  }
  if (open.any((o) => o.status == OrderStatus.cooking)) {
    return PosTableStatus.cooking;
  }
  if (open.any((o) => o.status == OrderStatus.received)) {
    return PosTableStatus.received;
  }
  if (open.any((o) => o.status == OrderStatus.done)) {
    return PosTableStatus.done;
  }
  return PosTableStatus.empty;
}

String posTableStatusLabel(PosTableStatus status) {
  switch (status) {
    case PosTableStatus.empty:
      return '비어 있음';
    case PosTableStatus.received:
      return '접수';
    case PosTableStatus.cooking:
      return '조리 중';
    case PosTableStatus.done:
      return '완료 대기';
  }
}
