import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/number_parser.dart';
import '../../core/vote_buffer.dart';
import '../../theme/sohoj_theme.dart';
import '../../theme/sohoj_tokens.dart';
import 'widgets/scan_frame.dart';
import 'widgets/scan_scrim.dart';
import 'widgets/status_pill.dart';

/// Milestone 3. Camera + live OCR + scan box + frame voting.
///
/// [onLocked] fires once with the locked number(s): one entry for a single
/// lock, two or more for F09. The caller pushes the result or choose screen.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({
    super.key,
    required this.onLocked,
    this.onClose,
    this.onHistory,
    this.onVoice,
    this.soundEnabled = true,
  });

  final void Function(List<String> numbers) onLocked;
  final VoidCallback? onClose;
  final VoidCallback? onHistory;

  /// F16: "বলে দিন" — opens the voice-input screen.
  final VoidCallback? onVoice;
  final bool soundEnabled;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final VoteBuffer _votes = VoteBuffer();

  ScanStatus _status = ScanStatus.searching;
  String? _error;
  bool _torchOn = false;
  bool _busy = false;
  bool _locked = false;
  DateTime _lastProcessed = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _status = ScanStatus.error;
        _error = 'ক্যামেরা অনুমতি নেই';
      });
      return;
    }

    final cameras = await availableCameras();
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await controller.initialize();
      await controller.setFocusMode(FocusMode.auto);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      await controller.startImageStream(_onFrame);
    } catch (_) {
      setState(() {
        _status = ScanStatus.error;
        _error = 'ক্যামেরা চালু হয়নি';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && _controller == null && !_locked) {
      _init();
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_busy || _locked) return;
    final now = DateTime.now();
    if (now.difference(_lastProcessed) < const Duration(milliseconds: 400)) return;
    _lastProcessed = now;
    _busy = true;

    try {
      final controller = _controller;
      if (controller == null) return;
      final rotation = _rotationFor(controller);
      final inputImage = InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final result = await _recognizer.processImage(inputImage);
      final insideBoxText = _textInsideScanBox(result, image.width, image.height, rotation);
      final numbers = findNumbers(insideBoxText);
      final locked = _votes.add(numbers);
      if (locked.isNotEmpty) {
        await _lock(locked);
      } else if (mounted && _status != ScanStatus.searching) {
        setState(() => _status = ScanStatus.searching);
      }
    } catch (_) {
      // One bad frame is not worth surfacing; the next frame tries again.
    } finally {
      _busy = false;
    }
  }

  /// Image-space rotation of the sensor. The app is portrait-locked, so this
  /// skips the full device-orientation table that a rotatable app would need.
  InputImageRotation _rotationFor(CameraController controller) {
    final degrees = controller.description.sensorOrientation;
    return InputImageRotationValue.fromRawValue(degrees) ?? InputImageRotation.rotation90deg;
  }

  /// Keeps only text whose bounding box centre lies inside the scan box,
  /// mapped from screen points into the raw image's pixel space.
  String _textInsideScanBox(
    RecognizedText result,
    int imageWidth,
    int imageHeight,
    InputImageRotation rotation,
  ) {
    final rotated = rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    final rotatedW = rotated ? imageHeight.toDouble() : imageWidth.toDouble();
    final rotatedH = rotated ? imageWidth.toDouble() : imageHeight.toDouble();

    final screen = MediaQuery.of(context).size;
    // CameraPreview is shown with BoxFit.cover over the full screen.
    final scale = (screen.width / rotatedW > screen.height / rotatedH)
        ? screen.width / rotatedW
        : screen.height / rotatedH;
    final offsetX = (screen.width - rotatedW * scale) / 2;
    final offsetY = (screen.height - rotatedH * scale) / 2;

    final boxCenter = Offset(screen.width / 2, screen.height * 0.42);
    final box = Rect.fromCenter(center: boxCenter, width: scanBoxWidth, height: scanBoxHeight);

    final lines = <String>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final r = line.boundingBox;
        final imgCenter = Offset(
          (r.left + r.right) / 2 * scale + offsetX,
          (r.top + r.bottom) / 2 * scale + offsetY,
        );
        if (box.contains(imgCenter)) lines.add(line.text);
      }
    }
    return lines.join('\n');
  }

  Future<void> _lock(List<String> numbers) async {
    if (_locked) return;
    _locked = true;
    await _controller?.stopImageStream();
    if (!mounted) return;
    setState(() => _status = ScanStatus.locked);
    if (widget.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
      await HapticFeedback.lightImpact();
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) widget.onLocked(numbers);
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null) return;
    final next = !_torchOn;
    await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
    setState(() => _torchOn = next);
  }

  Future<void> _tapToFocus(TapUpDetails details, Size size) async {
    final controller = _controller;
    if (controller == null) return;
    final point = Offset(details.localPosition.dx / size.width, details.localPosition.dy / size.height);
    await controller.setFocusPoint(point);
    await controller.setExposurePoint(point);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _recognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    final controller = _controller;

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller.value.isInitialized)
            LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                onTapUp: (d) => _tapToFocus(d, constraints.biggest),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.previewSize!.height,
                    height: controller.value.previewSize!.width,
                    child: CameraPreview(controller),
                  ),
                ),
              ),
            )
          else if (_status != ScanStatus.error)
            const Center(child: CircularProgressIndicator()),
          if (controller != null && controller.value.isInitialized) _positionedScrim(context, p.scrim),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: SohojSize.space4, vertical: SohojSize.space2),
                  child: Row(
                    children: [
                      _GlassIconButton(
                        icon: Icons.close_rounded,
                        label: 'বন্ধ করুন',
                        onPressed: widget.onClose ?? () => SystemNavigator.pop(),
                      ),
                      const Spacer(),
                      StatusPill(status: _status, errorText: _error),
                      const Spacer(),
                      _GlassIconButton(
                        icon: _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        label: 'ফ্ল্যাশলাইট',
                        onPressed: controller == null ? null : _toggleTorch,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _status == ScanStatus.error
                        ? null
                        : ScanFrame(locked: _status == ScanStatus.locked),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: SohojSize.space4),
                  child: Text(
                    _status == ScanStatus.locked ? 'ধরে রাখুন…' : 'নাম্বারটা বক্সের ভেতরে ধরুন',
                    style: SohojType.bodyLg.copyWith(color: p.ink),
                  ),
                ),
                if (_status != ScanStatus.locked)
                  Padding(
                    padding: const EdgeInsets.only(bottom: SohojSize.space6),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: SohojSize.space4,
                      runSpacing: SohojSize.space2,
                      children: [
                        if (widget.onVoice != null)
                          _QuietButton(
                            icon: Icons.mic_rounded,
                            label: 'বলে দিন',
                            onPressed: widget.onVoice,
                          ),
                        if (widget.onHistory != null)
                          _QuietButton(
                            icon: Icons.history_rounded,
                            label: 'আগের নাম্বার',
                            onPressed: widget.onHistory,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _positionedScrim(BuildContext context, Color color) {
    final screen = MediaQuery.of(context).size;
    return ScanScrim(color: color, boxCenter: Offset(screen.width / 2, screen.height * 0.42));
  }
}

class _QuietButton extends StatelessWidget {
  const _QuietButton({required this.icon, required this.label, this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, SohojSize.sizeTouch),
        backgroundColor: p.surfaceRaised.withValues(alpha: 0.72),
        foregroundColor: p.ink,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: SohojSize.space6),
        textStyle: SohojType.bodyLg.copyWith(fontWeight: FontWeight.w700),
      ),
      icon: Icon(icon, size: SohojSize.sizeIcon),
      label: Text(label),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.label, this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: p.surfaceRaised.withValues(alpha: 0.72),
        foregroundColor: p.ink,
        minimumSize: const Size.square(SohojSize.sizeTouch),
      ),
    );
  }
}
