import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../native/scanner_channel.dart';
import '../../theme/sohoj_theme.dart';
import '../../theme/sohoj_tokens.dart';

enum _Step { camera, overlay, notification, battery }

/// F13: one step at a time; re-checked whenever the app resumes (e.g. after
/// coming back from a Settings screen). See screen 9 in design/screens.html.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with WidgetsBindingObserver {
  final Map<_Step, bool> _done = {for (final s in _Step.values) s: false};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final camera = await Permission.camera.status;
    final notification = await Permission.notification.status;
    final overlay = await ScannerChannel.canDrawOverlays();
    final battery = await ScannerChannel.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    setState(() {
      _done[_Step.camera] = camera.isGranted;
      _done[_Step.overlay] = overlay;
      _done[_Step.notification] = notification.isGranted;
      _done[_Step.battery] = battery;
    });
  }

  Future<void> _runStep(_Step step) async {
    switch (step) {
      case _Step.camera:
        await Permission.camera.request();
      case _Step.notification:
        await Permission.notification.request();
      case _Step.overlay:
        await ScannerChannel.requestOverlayPermission();
      case _Step.battery:
        await ScannerChannel.requestIgnoreBatteryOptimizations();
    }
    await _check();
  }

  _Step? get _nextStep => _Step.values.cast<_Step?>().firstWhere((s) => !_done[s]!, orElse: () => null);

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    final allDone = _done.values.every((d) => d);
    final next = _nextStep;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SohojSize.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('শুরু করার আগে', style: SohojType.display.copyWith(color: p.ink)),
              const SizedBox(height: SohojSize.space2),
              Text('৪টা জিনিস চালু করতে হবে, একবারই।',
                  style: SohojType.body.copyWith(color: p.inkMuted)),
              const SizedBox(height: SohojSize.space6),
              Expanded(
                child: ListView(
                  children: [
                    _StepRow(
                      number: '১',
                      title: 'ক্যামেরা',
                      subtitle: _done[_Step.camera]! ? 'দেওয়া আছে' : 'নাম্বার পড়তে লাগবে',
                      done: _done[_Step.camera]!,
                      isNext: next == _Step.camera,
                      onPressed: () => _runStep(_Step.camera),
                    ),
                    _StepRow(
                      number: '২',
                      title: 'অন্য app-এর উপর দেখানো',
                      subtitle: 'বাবলের জন্য',
                      done: _done[_Step.overlay]!,
                      isNext: next == _Step.overlay,
                      onPressed: () => _runStep(_Step.overlay),
                    ),
                    _StepRow(
                      number: '৩',
                      title: 'নোটিফিকেশন',
                      subtitle: 'বাবল চালু রাখতে',
                      done: _done[_Step.notification]!,
                      isNext: next == _Step.notification,
                      onPressed: () => _runStep(_Step.notification),
                    ),
                    _StepRow(
                      number: '৪',
                      title: 'ব্যাটারি সেভার বাদ',
                      subtitle: 'যাতে বাবল বন্ধ না হয়',
                      done: _done[_Step.battery]!,
                      isNext: next == _Step.battery,
                      onPressed: () => _runStep(_Step.battery),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: allDone ? widget.onDone : null,
                child: const Text('চালু করুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.isNext,
    required this.onPressed,
  });

  final String number;
  final String title;
  final String subtitle;
  final bool done;
  final bool isNext;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    return Container(
      margin: const EdgeInsets.only(bottom: SohojSize.space4),
      padding: const EdgeInsets.all(SohojSize.space4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(SohojSize.radiusMd),
        border: isNext ? Border.all(color: p.lineStrong, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? p.signal : p.surfaceRaised,
              shape: BoxShape.circle,
            ),
            child: done
                ? Icon(Icons.check_rounded, color: p.onSignal, size: 20)
                : Text(number, style: SohojType.caption.copyWith(color: p.inkMuted, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: SohojSize.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: SohojType.bodyLg.copyWith(
                        color: done ? p.inkMuted : p.ink, fontWeight: FontWeight.w700)),
                Text(subtitle, style: SohojType.caption.copyWith(color: p.inkMuted)),
              ],
            ),
          ),
          if (isNext && !done)
            TextButton(onPressed: onPressed, child: const Text('চালু করুন')),
        ],
      ),
    );
  }
}
