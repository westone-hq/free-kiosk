// lib/ui/admin/admin_home_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kiosk/providers/providers.dart';
import 'package:kiosk/ui/admin/admin_sales_tab.dart';
import 'package:kiosk/ui/admin/admin_settings_tab.dart';
import 'package:kiosk/ui/admin/admin_store_tab.dart';
import 'package:kiosk/ui/admin/admin_table_qr_tab.dart';

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
              ref.read(adminHomeTabIndexProvider.notifier).state = i;
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

// --- 0·3·4) 별도 화면(/pos · /kitchen · /customer)으로 이동 안내
class _TabOpenPosUrl extends ConsumerWidget {
  const _TabOpenPosUrl({required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ScreenLaunchCard(
      icon: Icons.point_of_sale_outlined,
      title: '주문 · POS',
      description: '테이블 현황, 결제, 자리 이동을 처리합니다.',
      buttonLabel: 'POS 화면 열기',
      onPressed: () => context.go('/pos?storeId=$storeId'),
    );
  }
}

class _TabOpenKitchenUrl extends ConsumerWidget {
  const _TabOpenKitchenUrl({required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ScreenLaunchCard(
      icon: Icons.soup_kitchen_outlined,
      title: '주방',
      description: '들어온 주문을 확인하고 조리 상태를 변경합니다.',
      buttonLabel: '주방 화면 열기',
      onPressed: () => context.go('/kitchen?storeId=$storeId'),
    );
  }
}

class _TabOpenCustomerUrl extends ConsumerWidget {
  const _TabOpenCustomerUrl({required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = ref.watch(appSettingsProvider).tableNo ?? '1';
    return _ScreenLaunchCard(
      icon: Icons.smartphone_outlined,
      title: '손님 주문',
      description: '손님이 보는 메뉴·장바구니 화면입니다.',
      detail: '테이블 $table번 · 설정 탭에서 번호 변경',
      buttonLabel: '손님 화면 열기',
      onPressed: () => context.go(
        '/customer?storeId=$storeId&tableNo=$table',
      ),
    );
  }
}

class _ScreenLaunchCard extends StatelessWidget {
  const _ScreenLaunchCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? detail;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Card(
            elevation: 0,
            color: cs.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: cs.primary),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      detail!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onPressed,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(buttonLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
