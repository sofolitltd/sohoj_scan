import 'package:flutter/material.dart';

import '../../../theme/sohoj_theme.dart';
import '../../../theme/sohoj_tokens.dart';

/// Size of the scan box in logical pixels. OCR only reads text whose
/// bounding box centre falls inside this box (see ScannerScreen).
const double scanBoxWidth = 300;
const double scanBoxHeight = 180;

/// The box the number must sit in, centred slightly above the middle.
/// See docs/design-system/components/ScanFrame/README.md.
class ScanFrame extends StatefulWidget {
  const ScanFrame({super.key, required this.locked});

  final bool locked;

  @override
  State<ScanFrame> createState() => _ScanFrameState();
}

class _ScanFrameState extends State<ScanFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.of(context).disableAnimations && !widget.locked) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ScanFrame old) {
    super.didUpdateWidget(old);
    if (widget.locked) {
      _c.stop();
    } else if (!_c.isAnimating && !MediaQuery.of(context).disableAnimations) {
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
    final color = widget.locked ? p.signal : p.scan;

    return SizedBox(
      width: scanBoxWidth,
      height: scanBoxHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final alignment in const [
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ])
            Align(
              alignment: alignment,
              child: _Corner(alignment: alignment, color: color),
            ),
          if (!widget.locked)
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Align(
                alignment: Alignment(0, -1 + 2 * _c.value),
                child: Container(
                  width: scanBoxWidth - 2 * SohojSize.space4,
                  height: 2,
                  color: p.scan,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.alignment, required this.color});

  final Alignment alignment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    return CustomPaint(
      size: const Size(44, 44),
      painter: _CornerPainter(color: color, top: isTop, left: isLeft),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.color, required this.top, required this.left});

  final Color color;
  final bool top;
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const r = SohojSize.radiusMd;
    final x0 = left ? 0.0 : size.width;
    final xIn = left ? r : size.width - r;
    final xEnd = left ? size.width : 0.0;
    final y0 = top ? 0.0 : size.height;
    final yIn = top ? r : size.height - r;
    final yEnd = top ? size.height : 0.0;

    final path = Path()
      ..moveTo(xEnd, y0)
      ..lineTo(xIn, y0)
      ..quadraticBezierTo(x0, y0, x0, yIn)
      ..lineTo(x0, yEnd);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.top != top || oldDelegate.left != left;
}
