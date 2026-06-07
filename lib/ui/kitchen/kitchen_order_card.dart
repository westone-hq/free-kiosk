import 'package:flutter/material.dart';
import 'package:kiosk/models/models.dart';

import 'kitchen_line_actions.dart';

/// 주문 카드 + 신규 주문 강조(짧은 펄스)
class KitchenOrderCard extends StatefulWidget {
  const KitchenOrderCard({
    super.key,
    required this.order,
    this.emphasizeNew = false,
  });

  final OrderHeader order;
  final bool emphasizeNew;

  @override
  State<KitchenOrderCard> createState() => _KitchenOrderCardState();
}

class _KitchenOrderCardState extends State<KitchenOrderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    if (widget.emphasizeNew) {
      _pulseCtrl.repeat(reverse: true);
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _pulseCtrl.stop();
          _pulseCtrl.reset();
        }
      });
    }
  }

  @override
  void didUpdateWidget(KitchenOrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.emphasizeNew && !oldWidget.emphasizeNew) {
      _pulseCtrl.repeat(reverse: true);
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _pulseCtrl.stop();
          _pulseCtrl.reset();
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime t) {
    final local = t.toLocal();
    String pad2(int n) => n.toString().padLeft(2, '0');
    return '${pad2(local.hour)}:${pad2(local.minute)}:${pad2(local.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final t = widget.emphasizeNew ? _pulseCtrl.value : 0.0;
        final scale = 1.0 + (t * 0.02);
        final glow = Color.lerp(
          scheme.surfaceContainerHighest,
          scheme.primaryContainer,
          t * 0.85,
        )!;
        return Transform.scale(
          scale: scale,
          child: Material(
            elevation: 2 + (t * 4),
            borderRadius: BorderRadius.circular(12),
            color: glow,
            child: child,
          ),
        );
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 260, maxWidth: 300),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(
                      '테이블 ${o.tableNo}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      o.status.name,
                      style: TextStyle(color: scheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _fmt(o.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '주문 ${o.id}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              if (o.note != null && o.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '요청: ${o.note}',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const Divider(height: 20),
              KitchenLineActions(order: o),
            ],
          ),
        ),
      ),
    );
  }
}
