import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/ui/pos/pos_table_status.dart';

/// POS 좌측·상단 상태 필터 (`null` = 전체)
final posStatusFilterProvider = StateProvider<PosTableStatus?>((ref) => null);

/// `true` = tables.json 의 gridX/gridY 배치도, `false` = 기본 4×4
final posCustomLayoutProvider = StateProvider<bool>((ref) => false);

/// 자리이동 모드: 첫 탭 테이블 번호 (없으면 대기)
final posMoveFromTableProvider = StateProvider<String?>((ref) => null);
