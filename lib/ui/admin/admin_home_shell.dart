// lib/ui/admin/admin_home_shell.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kiosk/providers/providers.dart';
import 'package:kiosk/ui/admin/admin_sales_tab.dart';
import 'package:kiosk/ui/admin/admin_settings_tab.dart';
import 'package:kiosk/ui/admin/admin_store_tab.dart';
import 'package:kiosk/ui/admin/admin_table_qr_tab.dart';
import 'package:url_launcher/url_launcher.dart';

/// 3.2: 좌측 탭 + 우측 본문(6칸)
class AdminHomeShell extends ConsumerWidget {
  const AdminHomeShell({
    super.key,
    required this.storeId,
    this.ownerName,
  });

  final String storeId;
  final String? ownerName;

  static const _titles = <String>[
    '매장 주문',
    '매장 관리',
    '매출 통계',
    '주방 화면',
    '손님(소비자) 화면',
    '설정',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(adminHomeTabIndexProvider);
    final width = MediaQuery.sizeOf(context).width;
    final extended = width >= 900;

    final shellTitle = ownerName != null && ownerName!.isNotEmpty
        ? '$ownerName — ${AdminHomeShell._titles[index]}'
        : '내 매장 — ${AdminHomeShell._titles[index]}';

    return Scaffold(
      appBar: AppBar(
        title: Text(shellTitle),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            onPressed: () =>
                ref.read(adminSessionProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (i) {
              // 0 — POS · 3 — 주방: 같은 창에서 GoRouter 화면으로 (관리자 레일 혼선 방지).
              if (i == 0) {
                context.go('/pos?storeId=$storeId');
                return;
              }
              if (i == 3) {
                context.go('/kitchen?storeId=$storeId');
                return;
              }
              if (i == 4) {
                final table = ref.read(appSettingsProvider).tableNo ?? '1';
                context.go(
                  '/customer?storeId=$storeId&tableNo=$table',
                );
                return;
              }
              ref.read(adminHomeTabIndexProvider.notifier).state = i;
            },
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.selected,
            extended: extended,
            minWidth: 72,
            minExtendedWidth: 200,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale),
                label: Text('주문·POS'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(Icons.restaurant_menu),
                label: Text('매장 관리'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('매출'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.soup_kitchen_outlined),
                selectedIcon: Icon(Icons.soup_kitchen),
                label: Text('주방'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.smartphone_outlined),
                selectedIcon: Icon(Icons.smartphone),
                label: Text('손님'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('설정'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: IndexedStack(
              index: index,
              children: [
                _TabOpenPosUrl(storeId: storeId),
                DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: '매장(메뉴)'),
                          Tab(text: '테이블·QR'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            const AdminStoreTab(),
                            const AdminTableQrTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AdminSalesTab(storeId: storeId),
                _TabOpenKitchenUrl(storeId: storeId),
                _TabOpenCustomerUrl(storeId: storeId),
                const AdminSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 0) 1.4 /pos (레일 탭 시 context.go — 본문은 예외·직접 URL 진입용)
class _TabOpenPosUrl extends ConsumerWidget {
  const _TabOpenPosUrl({required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = '/pos?storeId=$storeId';
    return _LinkTabBody(
      title: 'POS(테이블) 화면으로 이동',
      line1: '1.4에서 정한 path: /pos',
      line2: '열 URL: $u',
      onPressed: () => context.go('/pos?storeId=$storeId'),
    );
  }
}

// --- 4) 1.4 /kitchen
class _TabOpenKitchenUrl extends ConsumerWidget {
  const _TabOpenKitchenUrl({required this.storeId});

  final String storeId;

  Future<void> _open(WidgetRef ref) async {
    final uri = _buildRootChildPath('/kitchen', {
      'storeId': storeId,
    });
    await _openUri(uri);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = _buildRootChildPath('/kitchen', {'storeId': storeId});
    return _LinkTabBody(
      title: '주방 화면으로 이동',
      line1: '1.4에서 정한 path: /kitchen',
      line2: '열 URL: $u',
      onPressed: () => _open(ref),
    );
  }
}

// --- 5) 1.4 /customer?storeId&tableNo
class _TabOpenCustomerUrl extends ConsumerWidget {
  const _TabOpenCustomerUrl({required this.storeId});

  final String storeId;

  Future<void> _open(WidgetRef ref) async {
    final table = ref.read(appSettingsProvider).tableNo ?? '1';
    final uri = _buildRootChildPath(
      '/customer',
      {
        'storeId': storeId,
        'tableNo': table,
      },
    );
    await _openUri(uri);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = ref.watch(appSettingsProvider).tableNo ?? '1';
    final u = _buildRootChildPath(
      '/customer',
      {
        'storeId': storeId,
        'tableNo': table,
      },
    );
    return _LinkTabBody(
      title: '손님(소비자) 화면으로 이동',
      line1: '1.4: /customer?storeId=&tableNo=',
      line2: '2.4 `appSettings` 의 tableNo(없으면 1) 사용 → $u',
      onPressed: () => _open(ref),
    );
  }
}

// --- 위젯+공통: 링크 열기
class _LinkTabBody extends StatelessWidget {
  const _LinkTabBody({
    required this.title,
    required this.line1,
    required this.line2,
    required this.onPressed,
  });

  final String title;
  final String line1;
  final String line2;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(line1, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              SelectableText(
                line2,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.open_in_new),
                label: const Text('이 URL 열기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 현재 앱 **호스트+포트** 를 유지하고 path+query만 바꾼 URI (1.4 path)
Uri _buildRootChildPath(
  String path,
  Map<String, String> query,
) {
  final b = Uri.base;
  return Uri(
    scheme: b.scheme,
    host: b.host,
    port: b.hasPort ? b.port : null,
    path: path,
    queryParameters: query,
  );
}

Future<void> _openUri(Uri uri) async {
  if (kIsWeb) {
    debugPrint('open: $uri');
  }
  final ok = await launchUrl(
    uri,
    webOnlyWindowName: '_blank',
  );
  if (!ok) {
    debugPrint('launchUrl failed: $uri');
  }
}
