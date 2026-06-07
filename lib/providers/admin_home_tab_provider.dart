// lib/providers/admin_home_tab_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 0=매장 주문 … 5=설정. 사이드바 `NavigationRail` 과 **같은 순서**를 유지하세요.
final adminHomeTabIndexProvider = StateProvider<int>((ref) => 1);
