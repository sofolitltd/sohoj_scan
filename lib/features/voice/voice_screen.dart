import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vosk_flutter_service/vosk_flutter_service.dart';

import '../../core/number_parser.dart';
import '../../core/spoken_digits.dart';
import '../../theme/sohoj_theme.dart';
import '../../theme/sohoj_tokens.dart';

const _groupLengths = [3, 4, 4];
const _silence = Duration(milliseconds: 1000);
const _hardStop = Duration(seconds: 12);

enum _VoiceState { loading, listening, timeout, error }

/// F16: voice input. A customer speaks the number one digit at a time in
/// English; this screen writes it into 3-4-4 slots and hands the finished
/// number to [onNumber] once 1 s of silence follows a valid number.
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key, required this.onNumber, this.onClose});

  final ValueChanged<String> onNumber;
  final VoidCallback? onClose;

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  _VoiceState _state = _VoiceState.loading;
  String _error = '';

  Recognizer? _recognizer;
  SpeechService? _speech;
  StreamSubscription<String>? _partialSub;
  StreamSubscription<String>? _resultSub;
  Timer? _hardStopTimer;
  Timer? _silenceTimer;

  String _committedText = '';
  String _partialText = '';
  DateTime _lastChange = DateTime.now();
  final List<Map<String, dynamic>> _words = [];

  /// Non-null while the shopkeeper is re-recording just one group (tap on
  /// a group in the timeout state). The other two groups stay as they were.
  int? _editingGroup;
  List<String?> _frozenGroups = [null, null, null];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final vosk = VoskFlutterPlugin.instance();
      final modelPath =
          await ModelLoader().loadFromAssets('assets/models/vosk-model-small-en-us-0.15.zip');
      final model = await vosk.createModel(modelPath);
      final recognizer = await vosk.createRecognizer(
        model: model,
        sampleRate: 16000,
        grammar: kVoskGrammar,
      );
      await recognizer.setWords(words: true);
      final speech = await vosk.initSpeechService(recognizer);
      _recognizer = recognizer;
      _speech = speech;
      await _startListening();
    } on MicrophoneAccessDeniedException {
      if (mounted) setState(() { _state = _VoiceState.error; _error = 'মাইক্রোফোন অনুমতি নেই'; });
    } catch (_) {
      if (mounted) setState(() { _state = _VoiceState.error; _error = 'ভয়েস মডেল পাওয়া যাচ্ছে না'; });
    }
  }

  Future<void> _startListening() async {
    _committedText = '';
    _partialText = '';
    _words.clear();
    _lastChange = DateTime.now();
    await _partialSub?.cancel();
    await _resultSub?.cancel();
    final speech = _speech!;
    _partialSub = speech.onPartial().listen(_onPartial);
    _resultSub = speech.onResult().listen(_onResult);
    await speech.start();
    _hardStopTimer?.cancel();
    _hardStopTimer = Timer(_hardStop, _onHardStop);
    _silenceTimer?.cancel();
    _silenceTimer = Timer.periodic(const Duration(milliseconds: 200), (_) => _checkSilence());
    if (mounted) setState(() => _state = _VoiceState.listening);
  }

  void _onPartial(String raw) {
    final partial = (jsonDecode(raw) as Map)['partial'] as String? ?? '';
    if (partial == _partialText) return;
    setState(() {
      _partialText = partial;
      _lastChange = DateTime.now();
    });
  }

  void _onResult(String raw) {
    final json = jsonDecode(raw) as Map;
    final text = json['text'] as String? ?? '';
    final words = (json['result'] as List?)?.cast<Map>() ?? const [];
    setState(() {
      _words.addAll(words.cast<Map<String, dynamic>>());
      _committedText = '$_committedText $text'.trim();
      _partialText = '';
      _lastChange = DateTime.now();
    });
  }

  String get _liveText => '$_committedText $_partialText'.trim();

  void _checkSilence() {
    if (_state != _VoiceState.listening) return;
    if (DateTime.now().difference(_lastChange) < _silence) return;

    final editing = _editingGroup;
    if (editing == null) {
      final number = numberFromSpeech(_liveText);
      if (number != null) _finish(number);
    } else {
      final digits = digitsFromSpeech(_liveText);
      if (digits.length >= _groupLengths[editing]) {
        final groups = [..._frozenGroups];
        groups[editing] = digits.substring(0, _groupLengths[editing]);
        if (groups.every((g) => g != null)) {
          final merged = groups.join();
          if (findNumbers(merged).isNotEmpty) _finish(merged);
        }
      }
    }
  }

  Future<void> _finish(String number) async {
    _hardStopTimer?.cancel();
    _silenceTimer?.cancel();
    await _partialSub?.cancel();
    await _resultSub?.cancel();
    await _speech?.stop();
    await HapticFeedback.lightImpact();
    if (mounted) widget.onNumber(number);
  }

  Future<void> _onHardStop() async {
    _silenceTimer?.cancel();
    await _speech?.stop();
    if (mounted) setState(() => _state = _VoiceState.timeout);
  }

  void _retryGroup(int index) {
    final slots = _currentSlots();
    _frozenGroups = [
      _groupString(slots, 0),
      _groupString(slots, 1),
      _groupString(slots, 2),
    ];
    _frozenGroups[index] = null;
    _editingGroup = index;
    _startListening();
  }

  void _retryAll() {
    _editingGroup = null;
    _frozenGroups = [null, null, null];
    _startListening();
  }

  /// Confidence per digit of the committed text, aligned the same way
  /// [digitsFromSpeech] expands words ("double"/"triple") into digits.
  List<double?> _confidences() {
    final out = <double?>[];
    for (var i = 0; i < _words.length; i++) {
      final word = (_words[i]['word'] as String? ?? '').toLowerCase();
      final conf = (_words[i]['conf'] as num?)?.toDouble();
      if (word == 'double' || word == 'triple') {
        final times = word == 'double' ? 2 : 3;
        if (i + 1 < _words.length) {
          out.addAll(List.filled(times, conf));
          i++; // the digit word is consumed by this repeat marker
        }
      } else if (_isDigitWord(word)) {
        out.add(conf);
      }
    }
    return out;
  }

  bool _isDigitWord(String w) => const {
        'zero', 'oh', 'o', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
      }.contains(w);

  List<String?> _currentSlots() => slotsFromSpeech(_liveText);

  String? _groupString(List<String?> slots, int group) {
    final start = group == 0 ? 0 : (group == 1 ? 3 : 7);
    final len = _groupLengths[group];
    final part = slots.skip(start).take(len);
    if (part.any((d) => d == null)) return null;
    return part.join();
  }

  @override
  void dispose() {
    _hardStopTimer?.cancel();
    _silenceTimer?.cancel();
    _partialSub?.cancel();
    _resultSub?.cancel();
    _speech?.dispose();
    _recognizer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    // Build a straightforward 11-slot view: frozen groups shown as-is, the
    // live group shown from the current recognition.
    final display = <String?>[];
    if (_editingGroup == null) {
      display.addAll(_currentSlots());
    } else {
      for (var g = 0; g < 3; g++) {
        final len = _groupLengths[g];
        if (g == _editingGroup) {
          final liveDigits = digitsFromSpeech(_liveText);
          for (var i = 0; i < len; i++) {
            display.add(i < liveDigits.length ? liveDigits[i] : null);
          }
        } else {
          final frozen = _frozenGroups[g];
          for (var i = 0; i < len; i++) {
            display.add(frozen != null && i < frozen.length ? frozen[i] : null);
          }
        }
      }
    }
    final rawConfidences = _editingGroup == null ? _confidences() : const <double?>[];
    final slotConfidences = List<double?>.generate(
      11,
      (i) => i < rawConfidences.length ? rawConfidences[i] : null,
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SohojSize.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onClose,
                    tooltip: 'বন্ধ করুন',
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const Spacer(),
                  _Pill(
                    state: _state,
                    palette: p,
                  ),
                  const Spacer(),
                  const SizedBox(width: SohojSize.sizeTouch),
                ],
              ),
              const Spacer(),
              if (_state == _VoiceState.error)
                _ErrorBody(message: _error, palette: p)
              else ...[
                Text(
                  'Please say your number in English, one digit at a time.',
                  textAlign: TextAlign.center,
                  style: SohojType.bodyLg.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: SohojSize.space8),
                _SlotRow(
                  slots: display,
                  confidences: slotConfidences,
                  showErrors: _state == _VoiceState.timeout,
                  onTapGroup: _state == _VoiceState.timeout ? _retryGroup : null,
                  palette: p,
                ),
              ],
              const Spacer(),
              if (_state == _VoiceState.timeout)
                OutlinedButton(onPressed: _retryAll, child: const Text('আবার বলুন'))
              else if (_state == _VoiceState.loading)
                const Center(child: CircularProgressIndicator())
              else if (_state == _VoiceState.error)
                FilledButton(onPressed: widget.onClose, child: const Text('ফিরে যান'))
              else
                Container(
                  width: 120,
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: p.signal, shape: BoxShape.circle),
                  child: Icon(Icons.mic_rounded, size: 56, color: p.onSignal),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.state, required this.palette});

  final _VoiceState state;
  final SohojPalette palette;

  @override
  Widget build(BuildContext context) {
    final listening = state == _VoiceState.listening;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: SohojSize.space4),
      decoration: ShapeDecoration(
        color: listening ? palette.scan : palette.surfaceRaised,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic_rounded, size: 20, color: listening ? palette.onSignal : palette.inkMuted),
          const SizedBox(width: SohojSize.space2),
          Text(
            switch (state) {
              _VoiceState.loading => 'লোড হচ্ছে…',
              _VoiceState.listening => 'শুনছি…',
              _VoiceState.timeout => 'শোনা থেমেছে',
              _VoiceState.error => 'সমস্যা',
            },
            style: SohojType.body.copyWith(
              color: listening ? palette.onSignal : palette.inkMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.slots,
    required this.confidences,
    required this.showErrors,
    required this.onTapGroup,
    required this.palette,
  });

  final List<String?> slots;
  final List<double?> confidences;
  final bool showErrors;
  final void Function(int group)? onTapGroup;
  final SohojPalette palette;

  @override
  Widget build(BuildContext context) {
    final groupBounds = [(0, 3), (3, 7), (7, 11)];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: SohojSize.space4,
      runSpacing: SohojSize.space4,
      children: [
        for (var g = 0; g < groupBounds.length; g++)
          GestureDetector(
            onTap: onTapGroup == null ? null : () => onTapGroup!(g),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = groupBounds[g].$1; i < groupBounds[g].$2; i++)
                  _Digit(
                    slot: slots[i],
                    confidence: confidences[i],
                    showErrors: showErrors,
                    palette: palette,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Digit extends StatelessWidget {
  const _Digit({
    required this.slot,
    required this.confidence,
    required this.showErrors,
    required this.palette,
  });

  final String? slot;
  final double? confidence;
  final bool showErrors;
  final SohojPalette palette;

  @override
  Widget build(BuildContext context) {
    final lowConfidence = slot != null && confidence != null && confidence! < 0.60;
    final empty = slot == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        slot ?? '_',
        style: SohojType.numberHero.copyWith(
          fontSize: SohojType.numberHero.fontSize! * 0.7,
          color: empty
              ? (showErrors ? palette.danger : palette.inkMuted)
              : (lowConfidence ? palette.scanInk : palette.ink),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.palette});

  final String message;
  final SohojPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.error_outline_rounded, size: 56, color: palette.danger),
        const SizedBox(height: SohojSize.space4),
        Text(message, textAlign: TextAlign.center, style: SohojType.display.copyWith(color: palette.ink)),
      ],
    );
  }
}
