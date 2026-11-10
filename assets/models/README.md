# Voice model (F16)

Put the model zip here, unmodified, exactly as downloaded:

```
assets/models/vosk-model-small-en-us-0.15.zip
```

Download from https://alphacephei.com/vosk/models (the small English model,
~40 MB). `lib/features/voice/voice_screen.dart` unzips it on first use via
`ModelLoader().loadFromAssets(...)`.

Until the zip is here, `flutter run`/`flutter build` will fail with a
missing-asset error (it's declared in `pubspec.yaml`), and the voice screen
shows "ভয়েস মডেল পাওয়া যাচ্ছে না" if it's missing at runtime on an
already-built APK.
