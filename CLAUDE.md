# Sohoj Scan — instructions for Claude

## What this is

An Android app (Flutter + a little native Kotlin) for one shopkeeper with
low vision. He points the camera at a handwritten note, a feature phone
screen or a smartphone screen. The app finds a Bangladeshi mobile number,
shows it huge, reads it aloud and copies it in one tap. He then pastes it
into bKash, Nagad, Rocket, flexiload or an admin app.

The owner (who talks to you) is a Flutter developer and writes in Bangla.
Reply in Bangla with English technical terms, unless asked otherwise.

## Read first

| File | What it holds |
|---|---|
| `docs/PRD.md` | Features F01–F15 with acceptance criteria, flow, parsing rules, permissions, milestones |
| `docs/design-system/README.md` | The Sohoj design system: principles, colour, type, sound/haptics, do/don't |
| `docs/design-system/components/<Name>/README.md` | Rules for each component |
| `design/screens.html` | Every screen, pixel-level reference (open in a browser; `screens.png` is a snapshot) |
| `android_native/README.md` | Native bubble, tile and warm-engine code, and where it goes |

## Hard rules

1. **No INTERNET permission** in the release manifest. No analytics, no crash
   upload, no network calls. Fonts are bundled in `assets/fonts/`.
2. **Every colour, size, radius and text style comes from tokens**:
   `lib/theme/sohoj_tokens.dart` (generated) via `buildSohojTheme()` and
   `context.sohoj`. Never hard-code a hex or a font size in a widget.
   To change a token: edit `docs/design-system/tokens.json`, then run
   `python3 tool/gen_tokens.py`.
3. **Never copy or paste on the user's behalf without a tap.** Lock and TTS are
   automatic; copy is always a human tap. Phase 2 paste needs an explicit confirm.
4. Accessibility floor: text ≥ 18sp (body 20), tap targets ≥ 64dp, primary
   buttons 88dp tall, contrast 7:1 for text. Every state change has colour +
   icon + words + sound/haptic. Respect system font scale and "Remove animations".
5. UI strings are Bangla (see the screens for exact wording). Numbers and TTS
   are English digits, grouped 3-4-4. The clipboard gets the plain 11 digits.
6. The bubble and the Quick Settings tile are native Kotlin, not Flutter.
   Do not add `flutter_overlay_window`: it starts a second engine (RAM).
7. Keep `lib/core/` pure Dart (no Flutter imports) and covered by tests.

## Layout

```
lib/
  core/        number_parser.dart, vote_buffer.dart, operator.dart  (pure Dart)
  theme/       sohoj_tokens.dart (GENERATED), sohoj_theme.dart
  features/    one folder per screen: scanner/, result/, choose/, history/, setup/, settings/
  main.dart
test/          unit + widget tests; fixtures/number_cases.json
android_native/  Kotlin reference to merge in Milestone 5
docs/ design/ tool/ assets/fonts/
```

State management: plain `ChangeNotifier` / `ValueNotifier` unless the owner
asks for his usual package. No code generation.

## Commands

```bash
flutter pub get
flutter test                      # must stay green
flutter analyze
flutter run                       # on the brother's phone over USB
python3 tool/gen_tokens.py        # after editing tokens.json
flutter build apk --release       # sideload this APK
```

## Status and next steps

Milestones are in `docs/PRD.md`. Done in the starter: 0 (docs), 1 (tokens +
theme), 2 (parser + vote buffer + tests). Started: 4 (`ResultScreen`, no TTS
yet), 5 (Kotlin reference only).

Work one milestone per session. After each, run `flutter test` and
`flutter analyze`, and tell the owner exactly what to check on the phone.

**Milestone 3 — scanner** (`lib/features/scanner/`):
- `camera` with `ImageFormatGroup.nv21`, back camera, `ResolutionPreset.high`,
  continuous autofocus, tap-to-focus, torch toggle.
- Throttle: process at most one frame every 400 ms; drop frames while busy.
- Crop to the scan box (300×180dp, centred slightly above the middle) before
  OCR when practical; otherwise filter `TextBlock`s whose bounding box centre
  lies inside the box.
- `TextRecognizer(script: TextRecognitionScript.latin)` → `findNumbers()` →
  `VoteBuffer.add()`. One locked number → result screen; two or more →
  choose screen.
- Lock feedback: freeze preview 300 ms, soft beep, `HapticFeedback.lightImpact`.
- Searching UI: amber `ScanFrame` + `StatusPill` "খুঁজছি…"; locked: lime + "পেয়েছি".

**Milestone 4 — result**: wire `flutter_tts` (en-IN or en-US, rate 0.85×
default, speak group by group, update `readingGroup`), multi-number choose
screen, after copy `SystemNavigator.pop()` so the previous app comes back,
toast via the native side or a short-lived overlay.

**Milestone 5 — native**: follow `android_native/README.md`.

**Milestone 6**: setup guide (one step at a time, re-check on resume,
brand-specific autostart intents), history (last 10, 24 h expiry,
`shared_preferences`), settings (theme, number size, TTS speed, sound, bubble).

**Milestone 3b — voice input (F16)** (`lib/features/voice/`):
- Engine: Vosk small English model, OFFLINE, with a fixed grammar from
  `lib/core/spoken_digits.dart` (`kVoskGrammar`). Never use a big Vosk
  model: runtime grammar works only with small models.
- Model: `assets/models/vosk-model-small-en-us-0.15.zip` (the owner downloads
  it from alphacephei.com/vosk/models and puts it there). Add it to pubspec assets.
- Package: `vosk_flutter_service` (^0.1.3+), not `vosk_flutter` — same API
  (`VoskFlutterPlugin`, `ModelLoader`, `Recognizer.setWords`/`createRecognizer(...,
  grammar: ...)`, `SpeechService.onPartial`/`onResult`), but `vosk_flutter`
  0.3.48 pins `permission_handler ^10.2.0` (pulls the removed v1-embedding
  `PluginRegistry.Registrar`, a hard compile error) and its Android module
  has no `namespace` (AGP refuses to configure it). `vosk_flutter_service`
  fixes both and adds iOS/macOS. It needs `permission_handler ^13.0.2` and
  `compileSdk 37` in `android/app/build.gradle.kts` (its `permission_handler_android`
  requires 37). Re-check this pick if a future session hits new breakage —
  don't fall back to `vosk_flutter` without re-verifying it's fixed upstream.
  If neither package works, write a small native bridge instead: Kotlin with
  `com.alphacephei:vosk-android`, `Recognizer(model, 16000f, grammarJson)` +
  `SpeechService`, exposed over the existing MethodChannel("scanner") plus
  an EventChannel for partials.
- Pipeline: partial result → `digitsFromSpeech()` → show in 11 slots.
  Final/partial → `numberFromSpeech()`; when it returns a number and no new
  word arrives for 1.0 s → stop, light haptic, open ResultScreen.
  Hard stop at 12 s. Enable word timings/confidence on the final result and
  mark digits whose word confidence < 0.60.
- Keep `lib/core/spoken_digits.dart` pure Dart; tests in
  `test/spoken_digits_test.dart` must stay green.
- UI follows the Sohoj design system: StatusPill amber "শুনছি…", digits in
  `numberHero` stacked 3-4-4 with empty slots as `ink-muted` underscores,
  a 120dp round mic button (signal fill when listening), Secondary
  "আবার বলুন". No hard-coded colours or sizes.
- Release manifest gets `RECORD_AUDIO`; still NO internet permission.

## Testing on the device

Ask the owner for 20–30 real photos from the shop (paper and phone screens).
Put them in `test_data/` with a `ground_truth.csv` (`file,expected_number`) and
add a small benchmark that runs OCR + parser on them and prints accuracy.
