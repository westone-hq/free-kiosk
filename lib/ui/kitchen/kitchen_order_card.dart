import 'package:flutter/material.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/ui/common/kiosk_display_format.dart';

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

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final scheme = Theme.of(context).colorScheme;
    final statusLabel = KioskDisplayFormat.orderStatus(o.status);

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
        constraints: const BoxConstraints(minWidth: 260, maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '테이블 ${o.tableNo}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(statusLabel),
                  ),
                  Text(
                    KioskDisplayFormat.timeHms(o.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Tooltip(
                message: o.id,
                child: Text(
                  KioskDisplayFormat.orderLabel(o.id),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
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
