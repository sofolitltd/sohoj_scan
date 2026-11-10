# Sohoj Scan

ভাইয়ের দোকানের জন্য number scanner app। এটা camera ধরলেই কাগজ বা phone-এর screen থেকে number পড়ে, বিশাল করে দেখায়, পড়ে শোনায় আর এক tap-এ copy করে দেয়।

## এই zip-এ কী আছে

| Folder / ফাইল | কী |
|---|---|
| `design/screens.html` | **App-এর সব screen-এর design** (১৩টা)। Browser-এ খুলুন। `screens.png` হলো একই জিনিসের ছবি। |
| `docs/PRD.md` | পুরো plan: feature, acceptance criteria, flow chart, parsing নিয়ম, permission, milestone |
| `docs/design-system/index.html` | **Sohoj design system**: রঙ, লেখা, component। Browser-এ খুলে Dark / Light / High contrast বদলে দেখুন। |
| `docs/design-system/README.md` | Design-এর সব নিয়ম (Claude এটা পড়বে) |
| `CLAUDE.md` | Claude-এর জন্য নির্দেশনা: নিয়ম, কোন ফাইল কোথায়, পরের ধাপ কী |
| `lib/` | Flutter-এর শুরুর কোড: theme, number parser, vote buffer, result screen |
| `test/` | Parser-এর ১৭টা test case + widget test |
| `android_native/` | Floating bubble, Quick Settings tile আর MainActivity-র Kotlin কোড (Milestone 5-এ বসবে) |
| `assets/fonts/` | Atkinson Hyperlegible + Noto Sans Bengali (offline, OFL license) |
| `tool/gen_tokens.py` | Design token বদলালে Dart file আবার তৈরি করে |

## শুরু করবেন যেভাবে

1. **Flutter install** থাকতে হবে (3.24 বা নতুন)। VS Code-এ *Flutter* আর *Claude Code* extension লাগবে।
2. Zip খুলে folder-টা VS Code-এ খুলুন।
3. Terminal-এ নিচের কমান্ডগুলো চালান:

   ```bash
   flutter create . --org com.sohoj --project-name sohoj_scan --platforms android
   flutter pub get
   flutter test
   ```

   `flutter create` শুধু `android/` folder আর যেসব ফাইল নেই সেগুলো বানাবে। আপনার `lib/`, `test/` আর `pubspec.yaml` যেমন আছে তেমনই থাকবে।
4. `android/app/build.gradle` (বা `build.gradle.kts`)-এ `minSdk = 26` করে দিন। ML Kit-এর এটা লাগে।
5. ভাইয়ের phone USB দিয়ে লাগিয়ে `flutter run` চালান। Result screen-টা দেখা যাবে। "আবার স্ক্যান"-এ চাপলে theme বদলাবে, এভাবে ভাইকে তিনটা theme দেখিয়ে নিতে পারবেন।

## তারপর Claude দিয়ে কাজ

VS Code-এ Claude Code খুলে প্রথমে লিখুন:

> CLAUDE.md, docs/PRD.md আর docs/design-system/README.md পড়ো। তারপর Milestone 3 (scanner) শুরু করো। design/screens.html-এর ১ আর ২ নম্বর screen হুবহু মেনে বানাবে।

প্রতিটা milestone শেষ হলে phone-এ চালিয়ে দেখবেন, তারপর বলবেন: "Milestone 4 করো", "Milestone 5 করো", এভাবে।

## ভাইকে দেখানোর আগে

`design/screens.html` ল্যাপটপে বড় করে, অথবা phone-এ `screens.png` খুলে ভাইকে দেখান। এই প্রশ্নগুলোর উত্তর নিয়ে নিন:

- Dark না Light, কোনটায় বেশি আরাম পান?
- Number-এর আকার ঠিক আছে কিনা
- ইংরেজিতে পড়ে শোনানো number বুঝতে পারেন কিনা

উত্তরগুলো `docs/PRD.md`-এর শেষে "Open questions"-এ লিখে রাখবেন, Claude পরে সেখান থেকে পড়বে।
