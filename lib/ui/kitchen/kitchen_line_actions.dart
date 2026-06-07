import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/providers/providers.dart';

/// 줄 단위 체크(로컬 UI) + 조리 시작·완료 버튼 (5.4)
class KitchenLineActions extends StatefulWidget {
  const KitchenLineActions({
    super.key,
    required this.order,
  });

  final OrderHeader order;

  @override
  State<KitchenLineActions> createState() => _KitchenLineActionsState();
}

class _KitchenLineActionsState extends State<KitchenLineActions> {
  final Set<int> _checkedLineIndexes = <int>{};

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '메뉴 줄 (체크는 주방 표시용)',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        ...List.generate(o.lines.length, (i) {
          final line = o.lines[i];
          final checked = _checkedLineIndexes.contains(i);
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${line.nameSnapshot} × ${line.quantity}',
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: Text(
              '${line.unitPrice}원 · 소계 ${line.lineTotal}원',
              style: const TextStyle(fontSize: 11),
            ),
            value: checked,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _checkedLineIndexes.add(i);
                } else {
                  _checkedLineIndexes.remove(i);
                }
              });
            },
          );
        }),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (o.status == OrderStatus.received)
                  FilledButton.tonal(
                    onPressed: () {
                      ref
                          .read(activeOrdersProvider.notifier)
                          .setStatus(o.id, OrderStatus.cooking);
                    },
                    child: const Text('조리 시작'),
                  ),
                if (o.status == OrderStatus.received ||
                    o.status == OrderStatus.cooking)
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(activeOrdersProvider.notifier)
                          .setStatus(o.id, OrderStatus.done);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${o.id} 조리 완료 처리')),
                      );
                    },
                    child: const Text('조리 완료'),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
