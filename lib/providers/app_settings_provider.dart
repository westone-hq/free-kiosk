// lib/providers/app_settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.storeId,
    this.tableNo,
    this.soundId,
    this.volume = 0.5,
  });

  final String? storeId;
  final String? tableNo;
  final String? soundId;
  final double volume;

  AppSettings copyWith({
    String? storeId,
    String? tableNo,
    String? soundId,
    double? volume,
    bool clearStoreId = false,
    bool clearTableNo = false,
    bool clearSoundId = false,
  }) {
    return AppSettings(
      storeId: clearStoreId ? null : (storeId ?? this.storeId),
      tableNo: clearTableNo ? null : (tableNo ?? this.tableNo),
      soundId: clearSoundId ? null : (soundId ?? this.soundId),
      volume: volume ?? this.volume,
    );
  }
}

class AppSettingsController extends StateNotifier<AppSettings> {
  AppSettingsController() : super(const AppSettings()) {
    _load();
  }

  static const _keyStoreId = 'storeId';
  static const _keyTableNo = 'tableNo';
  static const _keySound = 'kiosk_soundId';
  static const _keyVolume = 'kiosk_volume';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      storeId: prefs.getString(_keyStoreId),
      tableNo: prefs.getString(_keyTableNo),
      soundId: prefs.getString(_keySound),
      volume: prefs.getDouble(_keyVolume) ?? 0.5,
    );
  }

  Future<void> setStoreId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStoreId, value);
    state = state.copyWith(storeId: value);
  }

  Future<void> setTableNo(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTableNo, value);
    state = state.copyWith(tableNo: value);
  }

  Future<void> clearStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStoreId);
    state = state.copyWith(clearStoreId: true);
  }

  Future<void> clearTableNo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTableNo);
    state = state.copyWith(clearTableNo: true);
  }

  Future<void> setSoundId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySound, value);
    state = state.copyWith(soundId: value);
  }

  Future<void> clearSoundId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySound);
    state = state.copyWith(clearSoundId: true);
  }

  Future<void> setVolume(double v) async {
    final clamped = v.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVolume, clamped);
    state = state.copyWith(volume: clamped);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsController, AppSettings>(
  (ref) => AppSettingsController(),
);
