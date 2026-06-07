// lib/ui/admin/admin_settings_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/providers/providers.dart';

const _kSoundOptions = <String?>[null, 'chime1', 'chime2', 'buzz'];

class AdminSettingsTab extends ConsumerWidget {
  const AdminSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final c = ref.read(appSettingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('알림·볼륨(기기별)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('알림 음(식별자) — 3.5.4에서 실제 파일과 연결 가능'),
        DropdownButton<String?>(
          isExpanded: true,
          value: s.soundId,
          items: _kSoundOptions
              .map(
                (id) => DropdownMenuItem<String?>(
                  value: id,
                  child: Text(id ?? '(없음)'),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) {
              c.clearSoundId();
            } else {
              c.setSoundId(v);
            }
          },
        ),
        const SizedBox(height: 24),
        const Text('볼륨(0.0~1.0)'),
        Slider(
          value: s.volume,
          onChanged: (v) {
            c.setVolume(v);
          },
        ),
        Text('${(s.volume * 100).round()} %', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 24),
        const Divider(),
        const Text('2.4 AppSettings(참고)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('storeId'),
          subtitle: Text(s.storeId ?? '(없음)'),
        ),
        ListTile(
          title: const Text('tableNo'),
          subtitle: Text(s.tableNo ?? '(없음)'),
        ),
      ],
    );
  }
}
