// lib/ui/admin/admin_table_qr_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/providers/providers.dart';
import 'package:kiosk/router/app_router.dart';
import 'package:kiosk/services/services.dart';
import 'package:kiosk/ui/admin/customer_qr_panel.dart';

/// 3.4: stores/{storeId}/tables.json 편집 + 손님 /customer? URL QR
class AdminTableQrTab extends ConsumerStatefulWidget {
  const AdminTableQrTab({super.key});

  @override
  ConsumerState<AdminTableQrTab> createState() => _AdminTableQrTabState();
}

class _AdminTableQrTabState extends ConsumerState<AdminTableQrTab> {
  bool _inited = false;
  final int _fileVersion = 1;
  List<TableInfo> _list = [];

  void _init(List<TableInfo> fromProvider) {
    if (_inited) {
      return;
    }
    _inited = true;
    _list = List<TableInfo>.from(fromProvider);
  }

  String _buildCustomerUrl(String storeId, String tableNo) {
    final b = Uri.base;
    return Uri(
      scheme: b.scheme,
      host: b.host,
      port: b.hasPort ? b.port : null,
      path: '/customer',
      queryParameters: <String, String>{
        'storeId': storeId,
        'tableNo': tableNo,
      },
    ).toString();
  }

  TableInfo _copy(TableInfo t, {String? tableNo, String? label, int? gridX, int? gridY, bool? hidden}) {
    return TableInfo(
      tableNo: tableNo ?? t.tableNo,
      label: label != null
          ? (label.isEmpty ? null : label)
          : t.label,
      gridX: gridX ?? t.gridX,
      gridY: gridY ?? t.gridY,
      hidden: hidden ?? t.hidden,
    );
  }

  Future<void> _editRow(int i) async {
    final t = _list[i];
    final noCtrl = TextEditingController(text: t.tableNo);
    final labelCtrl = TextEditingController(text: t.label ?? '');
    final gridXCtrl = TextEditingController(text: '${t.gridX ?? ''}');
    final gridYCtrl = TextEditingController(text: '${t.gridY ?? ''}');
    final nav = rootNavigatorKey.currentContext;
    if (nav == null) {
      return;
    }
    final ok = await showDialog<bool>(
      context: nav,
      builder: (ctx) => AlertDialog(
        title: const Text('테이블 편집'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noCtrl,
              decoration: const InputDecoration(labelText: 'tableNo'),
            ),
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'label(비워도 됨)'),
            ),
            TextField(
              controller: gridXCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'gridX (배치도 열, 0부터)'),
            ),
            TextField(
              controller: gridYCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'gridY (배치도 행, 0부터)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('확인')),
        ],
      ),
    );
    if (ok == true) {
      final newNo = noCtrl.text.trim();
      final newLabel = labelCtrl.text;
      final gx = int.tryParse(gridXCtrl.text.trim());
      final gy = int.tryParse(gridYCtrl.text.trim());
      setState(() {
        _list[i] = _copy(
          t,
          tableNo: newNo.isEmpty ? t.tableNo : newNo,
          label: newLabel,
          gridX: gx,
          gridY: gy,
        );
      });
    }
    noCtrl.dispose();
    labelCtrl.dispose();
    gridXCtrl.dispose();
    gridYCtrl.dispose();
  }

  Future<void> _showQr(String storeId, TableInfo t) async {
    final url = _buildCustomerUrl(storeId, t.tableNo);
    if (url.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR URL을 만들 수 없습니다.')),
        );
      }
      return;
    }
    final nav = rootNavigatorKey.currentContext;
    if (nav == null) {
      return;
    }
    await showDialog<void>(
      context: nav,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: Text('QR — 테이블 ${t.tableNo}'),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: CustomerQrPanel(data: url)),
                const SizedBox(height: 12),
                SelectableText(url, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('URL을 복사했습니다.')),
              );
            },
            child: const Text('URL 복사'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToDisk() async {
    final storeId = ref.read(scopedStoreIdProvider);
    if (storeId == null || storeId.isEmpty) {
      return;
    }
    await saveTables(
      _list,
      fileVersion: _fileVersion,
      storeId: storeId,
    );
    if (!mounted) {
      return;
    }
    ref.invalidate(tablesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('테이블 목록을 저장했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(adminSessionProvider);
    final storeId = session.storeId;
    final asyncT = ref.watch(tablesProvider);

    return asyncT.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (tables) {
        _init(tables);
        if (storeId == null || storeId.isEmpty) {
          return const Center(
            child: Text('storeId가 없습니다. 로그인을 확인하세요.'),
          );
        }
        final sid = storeId;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: _saveToDisk,
                    child: const Text('테이블 목록 저장'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        final n = _list.length;
                        _list.add(
                          TableInfo(
                            tableNo: '${n + 1}',
                            label: '${n + 1}번',
                            gridX: n % 4,
                            gridY: n ~/ 4,
                            hidden: false,
                          ),
                        );
                      });
                    },
                    child: const Text('행 추가'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: _list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (c, i) {
                  final t = _list[i];
                  final url = _buildCustomerUrl(sid, t.tableNo);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '테이블 ${t.tableNo}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.label == null || t.label!.isEmpty
                                ? '라벨 없음 · 숨김: ${t.hidden}'
                                : t.label!,
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            url,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('숨김'),
                              Switch(
                                value: t.hidden,
                                onChanged: (v) {
                                  setState(() {
                                    _list[i] = _copy(t, hidden: v);
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: '편집',
                                onPressed: () => _editRow(i),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () => _showQr(sid, t),
                                icon: const Icon(Icons.qr_code_2),
                                label: const Text('QR 보기'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
