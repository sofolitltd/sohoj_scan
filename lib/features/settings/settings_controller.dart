import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../native/scanner_channel.dart';
import '../../theme/sohoj_theme.dart';

/// F14. Loads/saves to shared_preferences and notifies the app to rebuild.
class SettingsController extends ChangeNotifier {
  static const _kTheme = 'settings_theme';
  static const _kNumberSize = 'settings_number_size';
  static const _kTtsSlow = 'settings_tts_slow';
  static const _kSound = 'settings_sound';
  static const _kBubble = 'settings_bubble';

  SohojThemeMode themeMode = SohojThemeMode.dark;

  /// 0 বড়, 1 আরও বড় (default), 2 সবচেয়ে বড়.
  int numberSize = 1;
  double get numberScale => switch (numberSize) { 0 => 1.0, 2 => 1.3, _ => 1.15 };

  /// true = ধীরে (default, 0.85×), false = স্বাভাবিক (1.0×).
  bool ttsSlow = true;
  double get ttsRate => ttsSlow ? 0.85 : 1.0;

  bool soundEnabled = true;
  bool bubbleEnabled = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode = SohojThemeMode.values[prefs.getInt(_kTheme) ?? SohojThemeMode.dark.index];
    numberSize = prefs.getInt(_kNumberSize) ?? 1;
    ttsSlow = prefs.getBool(_kTtsSlow) ?? true;
    soundEnabled = prefs.getBool(_kSound) ?? true;
    bubbleEnabled = prefs.getBool(_kBubble) ?? false;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTheme, themeMode.index);
    await prefs.setInt(_kNumberSize, numberSize);
    await prefs.setBool(_kTtsSlow, ttsSlow);
    await prefs.setBool(_kSound, soundEnabled);
    await prefs.setBool(_kBubble, bubbleEnabled);
  }

  Future<void> setThemeMode(SohojThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _save();
  }

  Future<void> setNumberSize(int size) async {
    numberSize = size;
    notifyListeners();
    await _save();
  }

  Future<void> setTtsSlow(bool slow) async {
    ttsSlow = slow;
    notifyListeners();
    await _save();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled = enabled;
    notifyListeners();
    await _save();
  }

  /// Also starts/stops the native floating bubble (needs overlay permission).
  Future<void> setBubbleEnabled(bool enabled) async {
    bubbleEnabled = enabled;
    notifyListeners();
    await _save();
    if (enabled) {
      if (await ScannerChannel.canDrawOverlays()) await ScannerChannel.startBubble();
    } else {
      await ScannerChannel.stopBubble();
    }
  }
}
