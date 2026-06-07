// lib/ui/customer/menu_detail_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/providers/providers.dart';

Future<void> showMenuDetailSheet(
  BuildContext context,
  WidgetRef ref, {
  required MenuItem menu,
  required String storeId,
  required String tableNo,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return _MenuDetailSheetBody(
        menu: menu,
        onAdd: (qty, note) {
          ref.read(customerCartProvider.notifier).upsert(
                menu,
                qty,
                lineNote: note,
              );
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('장바구니에 담았습니다.')),
          );
        },
      );
    },
  );
}

class _MenuDetailSheetBody extends StatefulWidget {
  const _MenuDetailSheetBody({
    required this.menu,
    required this.onAdd,
  });

  final MenuItem menu;
  final void Function(int qty, String? note) onAdd;

  @override
  State<_MenuDetailSheetBody> createState() => _MenuDetailSheetBodyState();
}

class _MenuDetailSheetBodyState extends State<_MenuDetailSheetBody> {
  int _qty = 1;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _decQty() {
    if (_qty <= 1) {
      return;
    }
    setState(() => _qty--);
  }

  void _incQty() {
    setState(() => _qty++);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menu = widget.menu;
    final lineTotal = menu.price * _qty;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            menu.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${menu.price}원',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          if (menu.soldOut) ...[
            const SizedBox(height: 8),
            Chip(
              label: const Text('품절'),
              backgroundColor: theme.colorScheme.errorContainer,
              labelStyle: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ],
          const SizedBox(height: 20),
          Text('수량', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: _qty > 1 ? _decQty : null,
                  icon: const Icon(Icons.remove),
                  tooltip: '수량 줄이기',
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    '$_qty',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: menu.soldOut ? null : _incQty,
                  icon: const Icon(Icons.add),
                  tooltip: '수량 늘리기',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: '요청 사항 (선택)',
              hintText: '덜 맵게, 얼음 빼기 등',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  '합계 $lineTotal원',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: menu.soldOut
                    ? null
                    : () {
                        final note = _noteCtrl.text.trim();
                        widget.onAdd(
                          _qty,
                          note.isEmpty ? null : note,
                        );
                      },
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('담기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
