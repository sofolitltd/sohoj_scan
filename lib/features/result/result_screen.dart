import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/number_parser.dart';
import '../../core/operator.dart';
import '../../theme/sohoj_theme.dart';
import '../../theme/sohoj_tokens.dart';

/// Screen 3 in design/screens.html. Speaks the number group by group on
/// open (F07); [onCopied] fires after the clipboard write so the caller can
/// leave the app (`SystemNavigator.pop`).
class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.number,
    this.onRescan,
    this.onClose,
    this.onCopied,
    this.ttsRate = 0.85,
    this.numberScale = 1.0,
    this.soundEnabled = true,
  });

  /// 11 plain digits, e.g. 01712345678.
  final String number;
  final VoidCallback? onRescan;
  final VoidCallback? onClose;
  final VoidCallback? onCopied;

  /// F14 "পড়ার গতি": 0.85 ধীরে (default), 1.0 স্বাভাবিক.
  final double ttsRate;

  /// F14 "নাম্বারের আকার": multiplies the 72sp hero text.
  final double numberScale;
  final bool soundEnabled;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final FlutterTts _tts = FlutterTts();
  int? _readingGroup;

  @override
  void initState() {
    super.initState();
    _speak();
  }

  Future<void> _speak() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(widget.ttsRate * 0.5); // flutter_tts rate is 0–1; 0.5 is its "normal".
      final groups = groupNumber(widget.number);
      for (var i = 0; i < groups.length; i++) {
        if (!mounted) return;
        setState(() => _readingGroup = i);
        await _tts.speak(groups[i].split('').join(' '));
        await Future<void>.delayed(const Duration(milliseconds: 550));
      }
      if (mounted) setState(() => _readingGroup = null);
    } catch (_) {
      // No TTS engine available (e.g. in tests); the number is still on screen.
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.number));
    if (widget.soundEnabled) {
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 90));
      await HapticFeedback.mediumImpact();
    }
    if (mounted) {
      // ignore: deprecated_member_use
      SemanticsService.announce('কপি হয়েছে', TextDirection.ltr);
      widget.onCopied?.call();
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    final number = widget.number;
    final readingGroup = _readingGroup;
    final groups = groupNumber(number);
    final op = Operator.fromNumber(number);
    final heroStyle = SohojType.numberHero.copyWith(
        color: p.ink, fontSize: SohojType.numberHero.fontSize! * widget.numberScale);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: SohojSize.space4, vertical: SohojSize.space2),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onClose,
                    tooltip: 'বন্ধ করুন',
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(width: SohojSize.space4),
                  _LockedPill(palette: p),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: SohojSize.space6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('এই নাম্বারটা ঠিক আছে কি?',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: SohojSize.space2),
                    Semantics(
                      label: spokenNumber(number),
                      excludeSemantics: true,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < 3; i++)
                              Container(
                                padding: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      width: 5,
                                      color: readingGroup == i
                                          ? p.signalInk
                                          : Colors.transparent,
                                    ),
                                  ),
                                ),
                                child: Text(groups[i], style: heroStyle),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: SohojSize.space4),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: SohojSize.space4,
                      runSpacing: SohojSize.space2,
                      children: [
                        if (op != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: SohojSize.space4, vertical: SohojSize.space2),
                            decoration: BoxDecoration(
                              color: p.surfaceRaised,
                              borderRadius: BorderRadius.circular(SohojSize.radiusSm),
                            ),
                            child: Text(op.label,
                                style: SohojType.caption.copyWith(
                                    color: p.ink, fontWeight: FontWeight.w600)),
                          ),
                        TextButton.icon(
                          onPressed: _speak,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, SohojSize.sizeTouch),
                            backgroundColor: p.surfaceRaised,
                            foregroundColor: p.ink,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: SohojSize.space6),
                            textStyle: SohojType.bodyLg.copyWith(fontWeight: FontWeight.w700),
                          ),
                          icon: const Icon(Icons.volume_up_rounded, size: SohojSize.sizeIcon),
                          label: const Text('শুনুন'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  SohojSize.space6, SohojSize.space4, SohojSize.space6, SohojSize.space8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _copy,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('কপি করুন'),
                  ),
                  const SizedBox(height: SohojSize.space4),
                  OutlinedButton.icon(
                    onPressed: widget.onRescan,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('আবার স্ক্যান'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedPill extends StatelessWidget {
  const _LockedPill({required this.palette});
  final SohojPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: SohojSize.space4, right: SohojSize.space6),
      decoration: ShapeDecoration(color: palette.signal, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, color: palette.onSignal, size: 24),
          const SizedBox(width: SohojSize.space2),
          Text('পেয়েছি',
              style: SohojType.body.copyWith(color: palette.onSignal, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
