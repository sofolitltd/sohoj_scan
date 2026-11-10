# android_native — bubble, tile, warm engine

এগুলো reference implementation, এখনো project-এ বসানো হয়নি। `flutter create` চালানোর পর Milestone 5-এ Claude এগুলো বসাবে:

| ফাইল | কোথায় যাবে |
|---|---|
| `kotlin/MainActivity.kt` | `android/app/src/main/kotlin/com/sohoj/sohoj_scan/` (তৈরি হওয়া MainActivity-র জায়গায়) |
| `kotlin/BubbleService.kt` | একই folder |
| `kotlin/ScanTileService.kt` | একই folder |
| `manifest-snippet.xml` | `android/app/src/main/AndroidManifest.xml`-এ merge |
| `docs/design-system/assets/Icons/scan.svg` | Android Studio → Vector Asset → `res/drawable/ic_scan.xml` |
| `docs/design-system/assets/Logos/sohoj-mark.svg` | Vector Asset → `res/drawable/bubble_mark.xml` |

`minSdk` 26 রাখবেন (`android/app/build.gradle`)। Package নাম `com.sohoj.sohoj_scan` ধরে লেখা; `flutter create`-এ অন্য `--org` দিলে package লাইন বদলাতে হবে।

Xiaomi, Oppo, Vivo, Realme আর Infinix phone-এ Autostart চালু না করলে bubble মরে যায়। Setup screen-এ brand অনুযায়ী সঠিক settings screen খোলার intent লাগবে; Claude-কে বললে লিখে দেবে।
