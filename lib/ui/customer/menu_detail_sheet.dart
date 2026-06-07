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
  final qtyCtrl = TextEditingController(text: '1');
  final noteCtrl = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(menu.name, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('${menu.price}원'),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '수량',
                ),
              ),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: '요청(한 줄, 선택)',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final q = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                  ref.read(customerCartProvider.notifier).upsert(
                        menu,
                        q,
                        lineNote: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('장바구니에 담았습니다.')),
                  );
                },
                child: const Text('담기'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
