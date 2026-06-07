/// 주문이 진행 중인 단계 (JSON에는 영문 소문자로 저장)
enum OrderStatus {
  /// 접수됨
  received,

  /// 조리 중
  cooking,

  /// 조리 완료 (서빙/픽업 대기 등으로 쓸 수 있음)
  done,

  /// 결제 완료
  paid,

  /// 취소
  cancelled;

  /// JSON에 적힌 글자 → enum. 이상한 값이면 received 로 둡니다.
  static OrderStatus fromJson(String raw) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => OrderStatus.received,
    );
  }

  /// enum → JSON에 넣을 글자
  String toJson() => name;
}
