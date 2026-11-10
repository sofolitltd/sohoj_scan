# Button

The 88px pill that does the screen's one job. **Primary** (accent fill) once per screen: on the result screen it is always "কপি করুন". **Secondary** (2px line-strong border) for the way back: "আবার স্ক্যান". **Quiet** (surface-raised) for helpers like "শুনুন".

- Height `size-button` (88px), full width on phones (`block`), label style `label` (24px bold), 32px icon before the word.
- Verb first, one or two Bangla words. No "OK", no "Submit".
- Primary sits lowest on the screen, inside the bottom 40%, so the thumb reaches it without moving the grip.
- Pressed state: scale 0.97 + haptic `light`. Never disable a primary; hide it until it can work.
- Flutter: `FilledButton` with `minimumSize: Size.fromHeight(88)`, `shape: StadiumBorder()`.
