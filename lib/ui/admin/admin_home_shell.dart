// lib/ui/admin/admin_home_shell.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/providers/providers.dart';
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
              // 3 — 주방: 같은 창에서 GoRouter path 로 이동
              if (i == 3) {
                context.go('/kitchen?storeId=$storeId');
                return;
              }
              // 4 — 손님: /customer 로 이동 (관리자 레일 안에 두면 주문 화면이 안 보임)
              if (i == 4) {
                final table =
                    ref.read(appSettingsProvider).tableNo ?? '1';
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
                _TabOrdersPos(storeId: storeId),
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
                const _TabPlaceholder(
                  message: '3.3에서 쌓이는 기록에 맞춰 차트(매출)를 둡니다.',
                ),
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

// --- 0) 간이 POS: 미완·미취소 주문 리스트
class _TabOrdersPos extends ConsumerWidget {
  const _TabOrdersPos({required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(unpaidOrdersProvider);
    final sorted = [...list]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (sorted.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              '진행 중인 주문이 없습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '손님이 주문하면 여기에 표시됩니다',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(activeOrdersProvider.notifier).reload(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _ActiveOrderCard(order: sorted[i]),
      ),
    );
  }
}

String _orderStatusLabel(OrderStatus status) {
  return switch (status) {
    OrderStatus.received => '접수',
    OrderStatus.cooking => '조리 중',
    OrderStatus.done => '완료',
    OrderStatus.paid => '결제 완료',
    OrderStatus.cancelled => '취소',
  };
}

Color _orderStatusColor(OrderStatus status, ColorScheme scheme) {
  return switch (status) {
    OrderStatus.received => scheme.primaryContainer,
    OrderStatus.cooking => scheme.tertiaryContainer,
    OrderStatus.done => scheme.secondaryContainer,
    OrderStatus.paid => scheme.surfaceContainerHighest,
    OrderStatus.cancelled => scheme.errorContainer,
  };
}

Color _orderStatusOnColor(OrderStatus status, ColorScheme scheme) {
  return switch (status) {
    OrderStatus.received => scheme.onPrimaryContainer,
    OrderStatus.cooking => scheme.onTertiaryContainer,
    OrderStatus.done => scheme.onSecondaryContainer,
    OrderStatus.paid => scheme.onSurfaceVariant,
    OrderStatus.cancelled => scheme.onErrorContainer,
  };
}

String _formatOrderTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

int _orderTotal(OrderHeader order) {
  return order.lines.fold<int>(0, (sum, line) => sum + line.lineTotal);
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order});

  final OrderHeader order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = _orderTotal(order);
    final itemCount =
        order.lines.fold<int>(0, (sum, line) => sum + line.quantity);

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '테이블 ${order.tableNo}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(_orderStatusLabel(order.status)),
                  backgroundColor: _orderStatusColor(order.status, scheme),
                  labelStyle: TextStyle(
                    color: _orderStatusOnColor(order.status, scheme),
                    fontWeight: FontWeight.w600,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                Text(
                  _formatOrderTime(order.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...order.lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        line.nameSnapshot,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      '×${line.quantity}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${line.lineTotal}원',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (order.note != null && order.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '요청: ${order.note}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Text(
                  '$itemCount개',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '합계 $total원',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2,3,6) 자리만
class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
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
    webOnlyWindowName: kIsWeb ? '_blank' : null,
  );
  if (!ok) {
    debugPrint('launchUrl failed: $uri');
  }
}
