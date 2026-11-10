// GENERATED from docs/design-system/tokens.json — do not edit by hand.
// Regenerate with: python3 tool/gen_tokens.py

import 'package:flutter/painting.dart';

/// One colour palette per theme (dark is the default).
class SohojPalette {
  const SohojPalette({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.lineStrong,
    required this.signal,
    required this.onSignal,
    required this.signalInk,
    required this.accent,
    required this.onAccent,
    required this.scan,
    required this.scanInk,
    required this.danger,
    required this.scrim,
    required this.bubble,
  });

  /// App background behind every screen. Dark is the default theme.
  final Color bg;
  /// Cards, sheets, the result panel.
  final Color surface;
  /// Chips, icon buttons, pressed rows.
  final Color surfaceRaised;
  /// All primary text and the phone number. 13:1 or more on bg, surface and surface-raised in every theme.
  final Color ink;
  /// Secondary text (time in history, helper lines). Still 8:1 or more on every surface; never lighter.
  final Color inkMuted;
  /// Decorative dividers only. Never the only edge of a control.
  final Color line;
  /// Borders of controls (secondary button, cards you tap). 3:1 or more on bg.
  final Color lineStrong;
  /// The brand lime. Fill for 'number locked' and success: status pill, copied toast, bubble ring. Text on it is on-signal. On light it is a fill only, never text.
  final Color signal;
  /// Text and icons on a signal fill (15:1).
  final Color onSignal;
  /// Lime used as text or icon on bg/surface: the check mark, 'locked' label, focus ring. 7:1 or more.
  final Color signalInk;
  /// Primary button fill. Lime on dark, ink on light (lime on a light page has no edge).
  final Color accent;
  /// Label and icon on the primary button (15:1).
  final Color onAccent;
  /// Amber fill for 'searching' state: status pill and scan-frame corners while nothing is locked. Text on it is on-signal.
  final Color scan;
  /// Amber as text/icon on bg (searching hints).
  final Color scanInk;
  /// Errors (camera blocked, permission missing). Always with an icon and words.
  final Color danger;
  /// Darkens the camera image outside the scan box so the box reads first.
  final Color scrim;
  /// Floating bubble body. Always dark so it stands out over any app.
  final Color bubble;
}

const SohojPalette sohojDark = SohojPalette(
  bg: Color(0xFF0B0C0A),
  surface: Color(0xFF161814),
  surfaceRaised: Color(0xFF22251F),
  ink: Color(0xFFF4F2EA),
  inkMuted: Color(0xFFBDBBB1),
  line: Color(0xFF2E312A),
  lineStrong: Color(0xFF80837A),
  signal: Color(0xFFC6F432),
  onSignal: Color(0xFF0B0C0A),
  signalInk: Color(0xFFC6F432),
  accent: Color(0xFFC6F432),
  onAccent: Color(0xFF0B0C0A),
  scan: Color(0xFFFFB23F),
  scanInk: Color(0xFFFFB23F),
  danger: Color(0xFFFF9A8D),
  scrim: Color(0x9E000000),
  bubble: Color(0xFF0B0C0A),
);

const SohojPalette sohojLight = SohojPalette(
  bg: Color(0xFFF4F2EB),
  surface: Color(0xFFFFFFFF),
  surfaceRaised: Color(0xFFE9E6DC),
  ink: Color(0xFF0E0F0C),
  inkMuted: Color(0xFF43423D),
  line: Color(0xFFD6D2C6),
  lineStrong: Color(0xFF6E6B62),
  signal: Color(0xFFC6F432),
  onSignal: Color(0xFF0B0C0A),
  signalInk: Color(0xFF3B5000),
  accent: Color(0xFF0E0F0C),
  onAccent: Color(0xFFC6F432),
  scan: Color(0xFFFFB23F),
  scanInk: Color(0xFF6A3C00),
  danger: Color(0xFF8E2316),
  scrim: Color(0x9E000000),
  bubble: Color(0xFF0B0C0A),
);

const SohojPalette sohojContrast = SohojPalette(
  bg: Color(0xFF000000),
  surface: Color(0xFF000000),
  surfaceRaised: Color(0xFF141414),
  ink: Color(0xFFFFFFFF),
  inkMuted: Color(0xFFE8E8E8),
  line: Color(0xFF8A8A8A),
  lineStrong: Color(0xFFFFFFFF),
  signal: Color(0xFFFFE500),
  onSignal: Color(0xFF000000),
  signalInk: Color(0xFFFFE500),
  accent: Color(0xFFFFE500),
  onAccent: Color(0xFF000000),
  scan: Color(0xFFFFFFFF),
  scanInk: Color(0xFFFFFFFF),
  danger: Color(0xFFFF8A80),
  scrim: Color(0xCC000000),
  bubble: Color(0xFF000000),
);

/// Spacing, radius and size tokens in logical pixels (dp).
abstract final class SohojSize {
  /// Icon-to-text nudge.
  static const double space1 = 4.0;
  /// Inside chips.
  static const double space2 = 8.0;
  /// Between a label and its helper line.
  static const double space3 = 12.0;
  /// Gap between number groups; minimum gap between two tap targets.
  static const double space4 = 16.0;
  /// Screen side padding; card padding.
  static const double space6 = 24.0;
  /// Between sections.
  static const double space8 = 32.0;
  /// Above the action area.
  static const double space12 = 48.0;
  /// Top safe breathing room on result.
  static const double space16 = 64.0;
  /// Chips, small tags.
  static const double radiusSm = 12.0;
  /// Rows, setup steps, scan-frame corner bend.
  static const double radiusMd = 20.0;
  /// Cards, sheets, the result panel.
  static const double radiusLg = 28.0;
  /// Buttons, status pills, toast, bubble.
  static const double radiusPill = 999.0;
  /// Minimum tap target (Android asks 48; we use 64).
  static const double sizeTouch = 64.0;
  /// Height of the primary and secondary buttons.
  static const double sizeButton = 88.0;
  /// Floating bubble diameter (setting: 56 / 64 / 76).
  static const double sizeBubble = 64.0;
  /// Icons inside buttons; 24 only in chips.
  static const double sizeIcon = 32.0;
}

/// Text style tokens (sizes in sp).
abstract final class SohojType {
  static const String ui = 'AtkinsonHyperlegibleNext';
  static const String bangla = 'NotoSansBengali';
  static const String numeric = 'AtkinsonHyperlegibleMono';
  /// The locked number on the result screen, stacked one group per line (017 / 1234 / 5678) so each group is huge and checked on its own. Steps down to 64, then 56 if the system font scale is very large.
  static const TextStyle numberHero = TextStyle(fontFamily: numeric, fontSize: 72.0, height: 1.111, fontWeight: FontWeight.w700, letterSpacing: 1.44);
  /// Number on a choice card, one line, groups 3-4-4.
  static const TextStyle numberCard = TextStyle(fontFamily: numeric, fontSize: 32.0, height: 1.25, fontWeight: FontWeight.w700, letterSpacing: 0.64);
  /// History rows and the bubble's last-number preview.
  static const TextStyle numberRow = TextStyle(fontFamily: numeric, fontSize: 28.0, height: 1.286, fontWeight: FontWeight.w600, letterSpacing: 0.56);
  /// One per screen at most: the state headline.
  static const TextStyle display = TextStyle(fontFamily: ui, fontFamilyFallback: [bangla], fontSize: 34.0, height: 1.294, fontWeight: FontWeight.w700);
  /// Screen titles, card headers.
  static const TextStyle title = TextStyle(fontFamily: ui, fontFamilyFallback: [bangla], fontSize: 28.0, height: 1.357, fontWeight: FontWeight.w700);
  /// Button labels. Verb first, one or two words.
  static const TextStyle label = TextStyle(fontFamily: ui, fontFamilyFallback: [bangla], fontSize: 24.0, height: 1.333, fontWeight: FontWeight.w700);
  /// Instructions and hints over the camera.
  static const TextStyle bodyLg = TextStyle(fontFamily: ui, fontFamilyFallback: [bangla], fontSize: 22.0, height: 1.455, fontWeight: FontWeight.w500);
  /// Default running text. Nothing smaller except caption.
  static const TextStyle body = TextStyle(fontFamily: ui, fontFamilyFallback: [bangla], fontSize: 20.0, height: 1.5, fontWeight: FontWeight.w400);
  /// The floor: times, operator chip, metadata. Never below 18.
  static const TextStyle caption = TextStyle(fontFamily: ui, fontFamilyFallback: [bangla], fontSize: 18.0, height: 1.444, fontWeight: FontWeight.w500);
}
