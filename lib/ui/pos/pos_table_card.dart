import 'package:flutter/material.dart';
import 'package:kiosk/ui/pos/pos_table_status.dart';

/// 테이블 한 칸 카드 (상태별 색)
class PosTableCard extends StatelessWidget {
  const PosTableCard({
    super.key,
    required this.tableNo,
    required this.label,
    required this.status,
    required this.orderCount,
    required this.onTap,
    this.highlight = false,
    this.moveSelected = false,
  });

  final String tableNo;
  final String label;
  final PosTableStatus status;
  final int orderCount;
  final VoidCallback onTap;
  final bool highlight;
  final bool moveSelected;

  Color _statusColor(ColorScheme scheme) {
    switch (status) {
      case PosTableStatus.empty:
        return scheme.surfaceContainerHighest;
      case PosTableStatus.received:
        return scheme.primaryContainer;
      case PosTableStatus.cooking:
        return scheme.tertiaryContainer;
      case PosTableStatus.done:
        return scheme.secondaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = _statusColor(scheme);
    final border = moveSelected
        ? Border.all(color: scheme.primary, width: 3)
        : highlight
            ? Border.all(color: scheme.error, width: 2)
            : Border.all(color: scheme.outlineVariant);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                posTableStatusLabel(status),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (orderCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '주문 $orderCount건',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
