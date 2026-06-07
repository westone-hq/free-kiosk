import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/providers/providers.dart';

/// `activeOrdersProvider` 변화를 보고 새 주문이 들어오면 알림(시스템 사운드 + 콜백).
class KitchenOrderWatcher extends ConsumerStatefulWidget {
  const KitchenOrderWatcher({
    super.key,
    required this.child,
    required this.onNewOrdersDetected,
  });

  final Widget child;
  final void Function(List<OrderHeader> newcomers) onNewOrdersDetected;

  @override
  ConsumerState<KitchenOrderWatcher> createState() =>
      _KitchenOrderWatcherState();
}

class _KitchenOrderWatcherState extends ConsumerState<KitchenOrderWatcher> {
  void _maybeNotify(List<OrderHeader> previous, List<OrderHeader> next) {
    final prevIds = previous.map((e) => e.id).toSet();
    final newcomers = next.where((o) => !prevIds.contains(o.id)).toList();
    if (newcomers.isEmpty) {
      return;
    }
    final settings = ref.read(appSettingsProvider);
    if (settings.soundId != null && settings.soundId!.isNotEmpty) {
      if (settings.volume > 0) {
        SystemSound.play(SystemSoundType.alert);
      }
    }
    widget.onNewOrdersDetected(newcomers);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<OrderHeader>>(activeOrdersProvider, (previous, next) {
      if (previous == null) {
        return;
      }
      _maybeNotify(previous, next);
    });

    return widget.child;
  }
}
