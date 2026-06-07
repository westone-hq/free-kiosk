import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kiosk/providers/providers.dart';
import 'package:kiosk/ui/pos/pos_auth_guard.dart';
import 'package:kiosk/ui/pos/pos_table_grid.dart';
import 'package:kiosk/ui/pos/pos_table_status.dart';

/// Part 6 — POS 메인 (가드·필터·그리드·자리이동)
class PosShell extends ConsumerWidget {
  const PosShell({super.key, this.expectedStoreId});

  final String? expectedStoreId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(adminSessionProvider);

    if (!session.hydrated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!session.isLoggedIn || session.storeId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('POS')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('관리자 로그인이 필요합니다.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('관리자 로그인으로'),
              ),
            ],
          ),
        ),
      );
    }

    final sid = session.storeId!;
    if (!posUrlMatchesSession(session, expectedStoreId)) {
      final q = expectedStoreId ?? '';
      return Scaffold(
        appBar: AppBar(title: const Text('POS')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '로그인 매장($sid)과 주소의 storeId($q)가 다릅니다.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final storeAsync = ref.watch(storeProvider);
    final filter = ref.watch(posStatusFilterProvider);
    final customLayout = ref.watch(posCustomLayoutProvider);
    final moveFrom = ref.watch(posMoveFromTableProvider);

    final title = storeAsync.maybeWhen(
      data: (s) => '${s.name} · POS',
      orElse: () => 'POS',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: '관리자 화면',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _filterIndex(filter),
            extended: MediaQuery.sizeOf(context).width >= 900,
            labelType: MediaQuery.sizeOf(context).width >= 900
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.selected,
            onDestinationSelected: (i) {
              ref.read(posStatusFilterProvider.notifier).state =
                  _filterFromIndex(i);
            },
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view),
                label: Text('전체'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.event_seat_outlined),
                selectedIcon: Icon(Icons.event_seat),
                label: Text('비어 있음'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('접수'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.restaurant_outlined),
                selectedIcon: Icon(Icons.restaurant),
                label: Text('조리 중'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.check_circle_outline),
                selectedIcon: Icon(Icons.check_circle),
                label: Text('완료 대기'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('4×4'),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('배치도'),
                          ),
                        ],
                        selected: {customLayout},
                        onSelectionChanged: (s) {
                          ref.read(posCustomLayoutProvider.notifier).state =
                              s.first;
                        },
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          if (moveFrom != null) {
                            ref.read(posMoveFromTableProvider.notifier).state =
                                null;
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '자리이동: 출발 테이블 → 도착 테이블 순으로 탭하세요.',
                              ),
                            ),
                          );
                          ref.read(posMoveFromTableProvider.notifier).state =
                              '';
                        },
                        icon: Icon(
                          moveFrom != null ? Icons.close : Icons.swap_horiz,
                        ),
                        label: Text(
                          moveFrom != null && moveFrom.isNotEmpty
                              ? '이동 취소 (출발: $moveFrom)'
                              : moveFrom != null
                                  ? '출발 테이블을 탭하세요'
                                  : '자리이동',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: PosTableGrid(storeId: sid)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _filterIndex(PosTableStatus? filter) {
    if (filter == null) {
      return 0;
    }
    switch (filter) {
      case PosTableStatus.empty:
        return 1;
      case PosTableStatus.received:
        return 2;
      case PosTableStatus.cooking:
        return 3;
      case PosTableStatus.done:
        return 4;
    }
  }

  PosTableStatus? _filterFromIndex(int index) {
    switch (index) {
      case 0:
        return null;
      case 1:
        return PosTableStatus.empty;
      case 2:
        return PosTableStatus.received;
      case 3:
        return PosTableStatus.cooking;
      case 4:
        return PosTableStatus.done;
      default:
        return null;
    }
  }
}
