import 'package:flutter/material.dart';

import '../../theme/sohoj_theme.dart';
import '../../theme/sohoj_tokens.dart';
import 'settings_controller.dart';

/// F14. See screen 10 in design/screens.html.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings, this.onClose});

  final SettingsController settings;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SohojSize.space2, vertical: SohojSize.space2),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onClose,
                      tooltip: 'ফিরে যান',
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text('সেটিংস',
                          textAlign: TextAlign.center,
                          style: SohojType.title.copyWith(color: p.ink)),
                    ),
                    const SizedBox(width: SohojSize.sizeTouch),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: SohojSize.space6, vertical: SohojSize.space4),
                  children: [
                    _Group(
                      label: 'থিম',
                      child: _Segmented(
                        labels: const ['ডার্ক', 'লাইট', 'কনট্রাস্ট'],
                        selected: settings.themeMode.index,
                        onChanged: (i) => settings.setThemeMode(SohojThemeMode.values[i]),
                      ),
                    ),
                    _Group(
                      label: 'নাম্বারের আকার',
                      child: _Segmented(
                        labels: const ['বড়', 'আরও বড়', 'সবচেয়ে বড়'],
                        selected: settings.numberSize,
                        onChanged: settings.setNumberSize,
                      ),
                    ),
                    _Group(
                      label: 'পড়ার গতি',
                      child: _Segmented(
                        labels: const ['ধীরে', 'স্বাভাবিক'],
                        selected: settings.ttsSlow ? 0 : 1,
                        onChanged: (i) => settings.setTtsSlow(i == 0),
                      ),
                    ),
                    _ToggleGroup(
                      label: 'শব্দ ও কাঁপুনি',
                      value: settings.soundEnabled,
                      onChanged: settings.setSoundEnabled,
                    ),
                    _ToggleGroup(
                      label: 'বাবল দেখাও',
                      value: settings.bubbleEnabled,
                      onChanged: settings.setBubbleEnabled,
                    ),
                    const SizedBox(height: SohojSize.space6),
                    Text('নমুনা', style: SohojType.caption.copyWith(color: p.inkMuted)),
                    const SizedBox(height: SohojSize.space2),
                    Text('017 1234 5678',
                        style: SohojType.numberRow.copyWith(
                            color: p.ink, fontSize: SohojType.numberRow.fontSize! * settings.numberScale)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    return Padding(
      padding: const EdgeInsets.only(bottom: SohojSize.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: SohojType.caption.copyWith(color: p.ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: SohojSize.space2),
          child,
        ],
      ),
    );
  }
}

class _ToggleGroup extends StatelessWidget {
  const _ToggleGroup({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    return Padding(
      padding: const EdgeInsets.only(bottom: SohojSize.space6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: SohojType.caption.copyWith(color: p.ink, fontWeight: FontWeight.w700)),
          ),
          Switch(value: value, onChanged: onChanged, activeTrackColor: p.signal),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.labels, required this.selected, required this.onChanged});

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(SohojSize.radiusPill),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  height: SohojSize.sizeTouch - 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? p.signal : Colors.transparent,
                    borderRadius: BorderRadius.circular(SohojSize.radiusPill),
                  ),
                  child: Text(
                    labels[i],
                    style: SohojType.caption.copyWith(
                      color: i == selected ? p.onSignal : p.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
