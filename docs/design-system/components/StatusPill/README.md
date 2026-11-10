# StatusPill

One pill at the top of the camera that says what the scanner is doing. State is told four ways at once: colour, shape inside (dot / check / alert), the word, and a sound or haptic.

| State | Fill | Word | Sound / haptic |
|---|---|---|---|
| searching | `scan` amber, dot pulses | খুঁজছি… | none |
| locked | `signal` lime, check | পেয়েছি | soft beep + short vibration |
| error | `surface-raised`, `danger` border | the problem in 2 words | one long vibration |

Text on amber and lime is `on-signal` (black), 10:1 and 15:1.
