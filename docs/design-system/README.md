# Sohoj

> Browser-এ `index.html` খুলুন: সব রঙ, লেখা আর component তিনটা theme-এ দেখা যাবে। Flutter-এ token আসে `lib/theme/sohoj_tokens.dart` থেকে, যেটা `tokens.json` থেকে তৈরি (`python3 tool/gen_tokens.py`)।

Sohoj (সহজ) হলো "Sohoj Scan" app-এর design system। App-টা camera ধরলেই হাতের লেখা বা phone screen থেকে বাংলাদেশি mobile number বের করে, বিশাল অক্ষরে দেখায়, পড়ে শোনায় আর এক tap-এ copy করে দেয়। ব্যবহারকারী চোখে কম দেখেন, তাই এখানে প্রতিটা সিদ্ধান্তের প্রথম প্রশ্ন একটাই: **চশমা ছাড়া, দোকানের আলোয়, এক হাতে এটা কি পড়া আর চাপা যায়?**

Look and feel: 2026 সালের শান্ত, আত্মবিশ্বাসী utility app। কালো ক্যানভাসের উপর একটা উজ্জ্বল lime রঙ, বড় গোল আকার, প্রচুর ফাঁকা জায়গা। কোনো gradient নেই, কোনো কার্টুন নেই, ঝকমকে রঙের মেলাও নেই। Phone number-টাই screen-এর নায়ক।

## Principles

1. **Number সবার আগে।** Result screen-এর অর্ধেক number-এর জন্য। বাকি সবকিছু তার পরে।
2. **এক screen, এক কাজ, এক primary button।** Scanner খোঁজে, result নিশ্চিত করে, toast জানায়।
3. **প্রতিটা অবস্থা চারভাবে জানানো হয়:** রঙ, আকার বা আইকন, শব্দ, আর আওয়াজ বা vibration। শুধু রঙ দিয়ে কিছু বোঝানো হয় না।
4. **বুড়ো আঙুলের নাগালে।** সব action screen-এর নিচের ৪০%-এ থাকবে।
5. **নিজে থেকে হয়, তবে চুপিচুপি না।** Lock আর পড়ে শোনানো নিজে থেকেই হয়, কিন্তু copy সবসময় মানুষের tap-এ।

## Content fundamentals

- UI-এর ভাষা বাংলা, ছোট আর চলিত, যেমন: "কপি করুন", "আবার স্ক্যান", "শুনুন", "খুঁজছি…", "পেয়েছি", "কপি হয়েছে"।
- Button-এ ক্রিয়া আগে, এক-দুই শব্দ। বিস্ময়চিহ্ন বা emoji থাকবে না, "OK" বা "Submit"-ও না।
- Number আর তার পড়া সবসময় ইংরেজি অঙ্কে, 3-4-4 ভাগে: `017 1234 5678`।
- Error message বলবে সমস্যা কী আর কী করতে হবে, দুই লাইনে: "ক্যামেরা বন্ধ। নিচের বোতামে চাপ দিয়ে অনুমতি দিন।"

## Visual foundations

**Colour.** তিনটা theme: `dark` (default; camera-ভিত্তিক app-এ সবচেয়ে আরামের), `light`, আর `contrast` (খাঁটি কালো + হলুদ)। ভাইকে দুটোই দেখিয়ে default বেছে নেবেন।
- `bg` / `surface` / `surface-raised`: তিন স্তরের পটভূমি। Shadow নেই, স্তর বোঝানো হয় রঙের ধাপ দিয়ে।
- `ink` সব লেখায়, প্রতিটা surface-এ ১৩:১ বা বেশি। `ink-muted` ৮:১-এর নিচে নামবে না।
- `signal` (lime `#C6F432`) হলো পরিচয়ের রঙ, অর্থ "পাওয়া গেছে / হয়ে গেছে"। এর উপর লেখা সবসময় `on-signal` (কালো)। Light theme-এ lime শুধু fill হিসেবে চলবে, লেখা হিসেবে না; lime রঙের লেখা লাগলে `signal-ink` ব্যবহার করবেন।
- `accent` হলো primary button-এর রঙ: dark-এ lime, light-এ কালো (তখন লেখা lime)।
- `scan` (amber) মানে "খুঁজছি"। `danger` শুধু error-এ, সাথে আইকন আর লেখা থাকবে।
- Lime আর amber আলাদা করা যায় উজ্জ্বলতা আর আকার দিয়েও (dot বনাম check), শুধু hue দিয়ে না।

**Type.** Atkinson Hyperlegible Next (Latin) + Noto Sans Bengali (বাংলা) UI-এর জন্য; number-এর জন্য Atkinson Hyperlegible Mono। Atkinson-এর নকশা Braille Institute করেছে low-vision পাঠকদের জন্য, এতে 1/l/I আর 0/O আলাদা করে চেনা যায়। সব হোস্ট করা Google Fonts থেকে আসে (Flutter-এ `google_fonts` package, অথবা font ফাইল bundle করে offline রাখবেন)।
- Body-র ন্যূনতম আকার ২০, caption ১৮। এর চেয়ে ছোট কিছু নেই।
- সব আকার sp-এ, যাতে system font scale ২০০% পর্যন্ত কাজ করে। Result-এ number তিন লাইনে ভাঙা থাকে (017 / 1234 / 5678), প্রতি লাইন ৭২px। জায়গা না পেলে ৬৪ → ৫৬ পর্যন্ত নামবে, তার নিচে না।

**Shape.** বড় আর নরম: button আর pill পুরো গোল (`radius-pill`), card `radius-lg` (২৮), row `radius-md` (২০)। Control-এর border ২px `line-strong`।

**Space.** ৪-এর grid। Screen-এর দুই পাশে `space-6` (২৪), দুই tap target-এর মাঝে অন্তত `space-4` (১৬)। Tap target ন্যূনতম ৬৪, প্রধান button ৮৮ উঁচু।

**Motion.** অল্প, আর অর্থ থাকলে তবেই। খোঁজার সময় scan line ধীরে ওঠানামা করে। Lock হলে camera ৩০০ms থামে, তারপর result sheet নিচ থেকে ওঠে (২৫০ms, ease-out)। "Remove animations" চালু থাকলে সব থেমে যায়, শুধু অবস্থা বদলায়।

**Sound & haptics** (এগুলোও design-এর অংশ):

| ঘটনা | শব্দ | Vibration |
|---|---|---|
| Number lock | নরম এক beep | ছোট একটা |
| Copy | — | ছোট দুইটা |
| Error | — | লম্বা একটা |
| Bubble tap | — | light |

## Iconography

`assets/Icons`: ২৪px grid, ২px গোল stroke, outline style। Button-এ ৩২px-এ দেখানো হয়। প্রতিটা আইকনের পাশে একটা শব্দ থাকবে; শুধু torch আর close icon button-এ শব্দ নেই, তাই ওগুলোতে TalkBack label বাধ্যতামূলক। App mark আর bubble-এর জন্য আছে `assets/Logos/sohoj-mark.svg`।

## Screens at a glance

1. **Scanner:** পুরো screen জুড়ে camera, মাঝে ScanFrame, উপরে StatusPill, নিচে বড় flashlight আর close।
2. **Result:** NumberDisplay hero (তিন লাইনে), OperatorChip, তার নিচে "শুনুন"; সবচেয়ে নিচে Primary "কপি করুন" আর Secondary "আবার স্ক্যান"।
3. **Choose:** একাধিক number পেলে NumberCard-এর তালিকা।
4. **Copied:** আগের app-এ ফেরার পর Toast।
5. **History**, **Setup**, **Settings**।

## Building it in Flutter

- `tokens.json` থেকে `ThemeData` বানাবেন, তিনটা theme-এর জন্য তিনটা `ColorScheme` + একটা `ThemeExtension<SohojColors>` (signal, scan, scrim, bubble-এর জন্য)। কোনো রঙ, আকার বা ফাঁক widget-এ hard-code করবেন না।
- Text style token থেকে `TextTheme`; number-এর style আলাদা `ThemeExtension`-এ রাখবেন।
- Bubble আর tile native Kotlin-এ, একই hex value দিয়ে (`res/values/colors.xml`)।
- প্রতিটা component একটা widget: `SjButton`, `SjIconButton`, `SjNumber`, `SjStatusPill`, `SjOperatorChip`, `SjScanFrame`, `SjNumberCard`, `SjHistoryRow`, `SjSetupStep`, `SjToast`।

## Do / Don't

- Do: number বড়, বাকি সব শান্ত। Don't: number-এর পাশে operator logo, বিজ্ঞাপন বা রঙিন ব্যাজ।
- Do: এক screen-এ একটাই lime button। Don't: lime দিয়ে সাজানো।
- Do: প্রতিটা অবস্থায় শব্দ আর vibration। Don't: শুধু রঙ বদলে অবস্থা বোঝানো।
- Do: ফাঁকা জায়গা। Don't: gradient, glassmorphism, ছোট ধূসর লেখা।
