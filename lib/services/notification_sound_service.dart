// lib/services/notification_sound_service.dart
import 'package:audioplayers/audioplayers.dart';

/// 3.5 · 8.10 — 설정 탭 `soundId` + `volume` 으로 주방 신규 주문 알림 재생.
class NotificationSoundService {
  NotificationSoundService._();

  static final AudioPlayer _player = AudioPlayer();

  static const _soundIds = {'chime1', 'chime2', 'buzz'};

  static String? assetPathForSoundId(String? soundId) {
    if (soundId == null || soundId.isEmpty || !_soundIds.contains(soundId)) {
      return null;
    }
    return 'sounds/$soundId.wav';
  }

  static Future<void> play({
    required String? soundId,
    required double volume,
  }) async {
    final asset = assetPathForSoundId(soundId);
    if (asset == null || volume <= 0) {
      return;
    }
    await _player.stop();
    await _player.setVolume(volume.clamp(0.0, 1.0));
    await _player.play(AssetSource(asset));
  }
}
