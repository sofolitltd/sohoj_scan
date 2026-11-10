import 'package:flutter/material.dart';

import '../../../theme/sohoj_theme.dart';
import '../../../theme/sohoj_tokens.dart';

enum ScanStatus { searching, locked, error }

/// One pill at the top of the camera telling the shopkeeper what the
/// scanner is doing, four ways at once: colour, icon, word, sound/haptic
/// (sound/haptic is fired by the caller on lock, not here).
/// See docs/design-system/components/StatusPill/README.md.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.errorText});

  final ScanStatus status;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    final (Color fill, Color onFill, Widget icon, String label) = switch (status) {
      ScanStatus.searching => (p.scan, p.onSignal, const _Dot(), 'খুঁজছি…'),
      ScanStatus.locked => (
          p.signal,
          p.onSignal,
          const Icon(Icons.check_rounded, size: 24),
          'পেয়েছি',
        ),
      ScanStatus.error => (
          p.surfaceRaised,
          p.danger,
          const Icon(Icons.error_outline_rounded, size: 24),
          errorText ?? 'সমস্যা হয়েছে',
        ),
    };

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: SohojSize.space4),
      decoration: ShapeDecoration(
        color: fill,
        shape: StadiumBorder(
          side: status == ScanStatus.error
              ? BorderSide(color: p.danger, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(data: IconThemeData(color: onFill), child: icon),
          const SizedBox(width: SohojSize.space2),
          Text(label, style: SohojType.body.copyWith(color: onFill, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot();

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !MediaQuery.of(context).disableAnimations) {
      _started = true;
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: p.onSignal, shape: BoxShape.circle),
      ),
    );
  }
}
