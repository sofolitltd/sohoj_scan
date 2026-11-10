# NumberDisplay

The phone number, always split 3-4-4 (`017 1234 5678`) in Atkinson Hyperlegible Mono, so 1/7, 0/8 and 5/6 never look alike and the eye can check it in three bites.

- `hero` 72px on the result screen, **stacked one group per line** (017 / 1234 / 5678): 11 digits at 64px do not fit a 360dp phone on one line, and a stacked number lets the eye and the voice check one group at a time. While TTS reads a group, that line is underlined in `signal-ink`.
- `card` 32px on one line on choice cards, `row` 28px in history.
- Gaps between groups are real spacing (`space-4`), not space characters: copy always puts the plain 11 digits on the clipboard.
- TalkBack and TTS read it digit by digit with a pause per group: set `Semantics(label: "0 1 7, 1 2 3 4, 5 6 7 8")`.
- Never truncate, never wrap inside a group. If 72px does not fit (narrow phone + big system font), step down to 64, then 56, never lower.
