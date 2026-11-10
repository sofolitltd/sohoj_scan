# FloatingBubble

The always-there button over every app. Built natively (Kotlin `Service` + `WindowManager`), not in Flutter.

- Dark `bubble` disc with a 3px `signal` ring and the scan icon in lime: it reads on light and dark apps alike. Shadow `shadow-bubble`.
- Sizes 56 / 64 (default) / 76 dp, set in Settings.
- Drag anywhere; on release it snaps to the nearest side edge, 16dp in. Idle for 4 s: fades to 70% opacity, never smaller.
- Drag to the bottom centre to reveal a "বন্ধ" target; dropping there hides it until the app is opened again.
- Tap: haptic `light`, open the scanner. Long-press: open history.
