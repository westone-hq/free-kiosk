// lib/ui/admin/admin_settings_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/providers/providers.dart';
import 'package:kiosk/services/notification_sound_service.dart';
import 'package:kiosk/ui/common/kiosk_display_format.dart';

class _SoundOption {
  const _SoundOption(this.id, this.label);
  final String? id;
  final String label;
}

const _kSoundOptions = <_SoundOption>[
  _SoundOption(null, '(없음 — 소리 안 남)'),
  _SoundOption('chime1', '차임 1'),
  _SoundOption('chime2', '차임 2 (길게)'),
  _SoundOption('buzz', '짧은 버즈'),
];

class AdminSettingsTab extends ConsumerStatefulWidget {
  const AdminSettingsTab({super.key});

  @override
  ConsumerState<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends ConsumerState<AdminSettingsTab> {
  late final TextEditingController _tableCtrl;
  bool _tableCtrlSynced = false;

  @override
  void initState() {
    super.initState();
    _tableCtrl = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _tableCtrl.dispose();
    super.dispose();
  }

  Future<void> _previewSound() async {
    final s = ref.read(appSettingsProvider);
    await NotificationSoundService.play(
      soundId: s.soundId,
      volume: s.volume,
    );
    if (!mounted) {
      return;
    }
    if (s.soundId == null || s.soundId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 음을 먼저 고르세요.')),
      );
      return;
    }
    if (s.volume <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('볼륨이 0% 입니다. 슬라이더를 올려 보세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appSettingsProvider);
    final c = ref.read(appSettingsProvider.notifier);
    final session = ref.watch(adminSessionProvider);
    final sessionStoreId = session.storeId;

    if (!_tableCtrlSynced) {
      _tableCtrlSynced = true;
      _tableCtrl.text = s.tableNo ?? '1';
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          '알림·볼륨 (기기별)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '주방 화면에서 새 주문이 들어오면 선택한 소리가 납니다. '
          '같은 PC·브라우저 시스템 볼륨도 확인하세요.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        const Text('알림 음'),
        DropdownButton<String?>(
          isExpanded: true,
          value: s.soundId,
          items: _kSoundOptions
              .map(
                (o) => DropdownMenuItem<String?>(
                  value: o.id,
                  child: Text(o.label),
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
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _previewSound,
          icon: const Icon(Icons.volume_up),
          label: const Text('들어보기'),
        ),
        const SizedBox(height: 24),
        const Text('볼륨 (0~100%)'),
        Slider(
          value: s.volume,
          onChanged: c.setVolume,
        ),
        Text(
          '${(s.volume * 100).round()} %',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        const Divider(),
        const Text(
          '손님 탭 · URL 기본값',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '로그인 매장',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                if (sessionStoreId == null)
                  Text(
                    '(로그인 필요)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  )
                else ...[
                  Text(
                    KioskDisplayFormat.storeShort(sessionStoreId),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    sessionStoreId,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _tableCtrl,
          decoration: const InputDecoration(
            labelText: 'tableNo — 손님 탭(4번) 기본 테이블',
            hintText: '1',
            helperText: '4번 탭·「손님 화면 열기」에 쓰입니다.',
          ),
          onSubmitted: (v) {
            final t = v.trim();
            if (t.isEmpty) {
              c.clearTableNo();
            } else {
              c.setTableNo(t);
            }
          },
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () {
            final t = _tableCtrl.text.trim();
            if (t.isEmpty) {
              c.clearTableNo();
            } else {
              c.setTableNo(t);
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('테이블 번호를 "$t"(으)로 저장했습니다.')),
              );
            }
          },
          child: const Text('tableNo 저장'),
        ),
      ],
    );
  }
}
