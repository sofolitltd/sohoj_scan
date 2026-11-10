import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/choose/choose_screen.dart';
import 'features/history/history_screen.dart';
import 'features/history/history_store.dart';
import 'features/result/result_screen.dart';
import 'features/scanner/scanner_screen.dart';
import 'features/settings/settings_controller.dart';
import 'features/settings/settings_screen.dart';
import 'features/setup/setup_screen.dart';
import 'features/voice/voice_screen.dart';
import 'native/scanner_channel.dart';
import 'theme/sohoj_theme.dart';

const _kSetupDone = 'setup_done';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SohojApp());
}

class SohojApp extends StatefulWidget {
  const SohojApp({super.key});

  @override
  State<SohojApp> createState() => _SohojAppState();
}

class _SohojAppState extends State<SohojApp> {
  final _settings = SettingsController();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _settings.load().then((_) async {
      if (_settings.bubbleEnabled && await ScannerChannel.canDrawOverlays()) {
        await ScannerChannel.startBubble();
      }
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settings,
      builder: (context, _) => MaterialApp(
        title: 'Sohoj Scan',
        debugShowCheckedModeBanner: false,
        theme: buildSohojTheme(_ready ? _settings.themeMode : SohojThemeMode.dark),
        home: _ready ? _AppShell(settings: _settings) : const SizedBox.shrink(),
      ),
    );
  }
}

enum _Stage { setup, scanning, voice, choosing, result, history, settings }

/// F03: home shortcut goes straight to the scanner (after first-run setup),
/// no menu in between. Swaps between stages instead of pushing routes so
/// the camera is cleanly reinitialised on every rescan.
class _AppShell extends StatefulWidget {
  const _AppShell({required this.settings});

  final SettingsController settings;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  _Stage _stage = _Stage.setup;
  List<String> _numbers = const [];
  String? _picked;
  int _scanCount = 0;
  final _history = HistoryStore();

  @override
  void initState() {
    super.initState();
    _checkSetup();
    ScannerChannel.listen(onOpenScanner: _rescan, onOpenHistory: _openHistory);
  }

  Future<void> _checkSetup() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _stage = prefs.getBool(_kSetupDone) ?? false ? _Stage.scanning : _Stage.setup);
  }

  Future<void> _finishSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSetupDone, true);
    if (mounted) setState(() => _stage = _Stage.scanning);
  }

  void _rescan() => setState(() {
        _stage = _Stage.scanning;
        _scanCount++;
      });

  void _openHistory() => setState(() => _stage = _Stage.history);
  void _openSettings() => setState(() => _stage = _Stage.settings);
  void _openVoice() => setState(() => _stage = _Stage.voice);

  void _onLocked(List<String> numbers) => setState(() {
        _numbers = numbers;
        _stage = numbers.length == 1 ? _Stage.result : _Stage.choosing;
        _picked = numbers.length == 1 ? numbers.first : null;
      });

  void _onVoiceNumber(String number) => setState(() {
        _picked = number;
        _stage = _Stage.result;
      });

  void _onPicked(String number) => setState(() {
        _picked = number;
        _stage = _Stage.result;
      });

  Future<void> _onCopied() async {
    final picked = _picked;
    if (picked != null) await _history.add(picked);
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    switch (_stage) {
      case _Stage.setup:
        return SetupScreen(onDone: _finishSetup);
      case _Stage.scanning:
        return ScannerScreen(
          key: ValueKey(_scanCount),
          onLocked: _onLocked,
          onHistory: _openHistory,
          onVoice: _openVoice,
          soundEnabled: settings.soundEnabled,
        );
      case _Stage.voice:
        return VoiceScreen(onNumber: _onVoiceNumber, onClose: _rescan);
      case _Stage.choosing:
        return ChooseScreen(numbers: _numbers, onPicked: _onPicked, onClose: _rescan);
      case _Stage.result:
        return ResultScreen(
          number: _picked!,
          onRescan: _rescan,
          onClose: _rescan,
          onCopied: _onCopied,
          ttsRate: settings.ttsRate,
          numberScale: settings.numberScale,
          soundEnabled: settings.soundEnabled,
        );
      case _Stage.history:
        return HistoryScreen(onClose: _rescan, onOpenSettings: _openSettings);
      case _Stage.settings:
        return SettingsScreen(settings: settings, onClose: _openHistory);
    }
  }
}
