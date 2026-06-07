import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/providers/providers.dart';

import 'kitchen_auth_guard.dart';
import 'kitchen_order_watcher.dart';
import 'kitchen_orders_strip.dart';

/// Part 5 — 주방 메인 화면 (가드·상단 시간·하단 이력 토글)
class KitchenShell extends ConsumerStatefulWidget {
  const KitchenShell({super.key, this.expectedStoreId});

  /// URL `?storeId=` 와 로그인 매장이 다를 때 안내
  final String? expectedStoreId;

  @override
  ConsumerState<KitchenShell> createState() => _KitchenShellState();
}

class _KitchenShellState extends ConsumerState<KitchenShell> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  bool _showArchive = false;
  final Set<String> _pulseIds = {};

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _onNewOrders(List<OrderHeader> newcomers) {
    setState(() {
      _pulseIds.addAll(newcomers.map((e) => e.id));
    });
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (!mounted) {
        return;
      }
      setState(() {
        for (final o in newcomers) {
          _pulseIds.remove(o.id);
        }
      });
    });
  }

  String _fmtClock(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    final local = t.toLocal();
    return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(adminSessionProvider);

    if (!session.hydrated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!session.isLoggedIn || session.storeId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('주방')),
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
    if (!kitchenUrlMatchesSession(session, widget.expectedStoreId)) {
      final q = widget.expectedStoreId ?? '';
      return Scaffold(
        appBar: AppBar(title: const Text('주방')),
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
    final orders = ref.watch(activeOrdersProvider);

    final title = storeAsync.maybeWhen(
      data: (s) => s.name,
      orElse: () => '주방',
    );

    return KitchenOrderWatcher(
      onNewOrdersDetected: _onNewOrders,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title),
              Text(
                _fmtClock(_now),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: '관리자 화면',
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home_outlined),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _showArchive
                  ? _KitchenArchiveBody(storeId: sid)
                  : KitchenOrdersStrip(
                      orders: orders,
                      pulseOrderIds: _pulseIds,
                      storeId: sid,
                    ),
            ),
            Material(
              elevation: 8,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('진행 주문'),
                              icon: Icon(Icons.restaurant),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('완료 이력'),
                              icon: Icon(Icons.history),
                            ),
                          ],
                          selected: {_showArchive},
                          onSelectionChanged: (Set<bool> selection) {
                            setState(() {
                              _showArchive = selection.first;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KitchenArchiveBody extends ConsumerWidget {
  const _KitchenArchiveBody({required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(archiveOrdersProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (entries) {
        final mine = entries.where((o) => o.storeId == storeId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (mine.isEmpty) {
          return Center(
            child: Text(
              '아카이브에 저장된 완료 주문이 없습니다.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: mine.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final o = mine[i];
            return ListTile(
              title: Text('테이블 ${o.tableNo} · ${o.id}'),
              subtitle: Text(
                '${o.status.name} · ${o.lines.length}줄 · ${o.createdAt.toLocal()}',
              ),
            );
          },
        );
      },
    );
  }
}
