import 'package:flutter/material.dart';

import 'sohoj_tokens.dart';

enum SohojThemeMode { dark, light, contrast }

/// Sohoj colours that Material's ColorScheme has no slot for.
/// Read with `context.sohoj`.
@immutable
class SohojColors extends ThemeExtension<SohojColors> {
  const SohojColors(this.p);
  final SohojPalette p;

  @override
  SohojColors copyWith({SohojPalette? p}) => SohojColors(p ?? this.p);

  @override
  SohojColors lerp(ThemeExtension<SohojColors>? other, double t) =>
      t < 0.5 ? this : (other as SohojColors? ?? this);
}

extension SohojContext on BuildContext {
  SohojPalette get sohoj => Theme.of(this).extension<SohojColors>()!.p;
}

SohojPalette paletteFor(SohojThemeMode mode) => switch (mode) {
      SohojThemeMode.dark => sohojDark,
      SohojThemeMode.light => sohojLight,
      SohojThemeMode.contrast => sohojContrast,
    };

/// Builds the whole app theme from tokens. Widgets never hard-code values.
ThemeData buildSohojTheme(SohojThemeMode mode) {
  final p = paletteFor(mode);
  final brightness =
      mode == SohojThemeMode.light ? Brightness.light : Brightness.dark;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.signal,
    onSecondary: p.onSignal,
    error: p.danger,
    onError: p.bg,
    surface: p.surface,
    onSurface: p.ink,
    surfaceContainerHighest: p.surfaceRaised,
    onSurfaceVariant: p.inkMuted,
    outline: p.lineStrong,
    outlineVariant: p.line,
  );

  TextStyle c(TextStyle s, [Color? color]) => s.copyWith(color: color ?? p.ink);

  final pill = WidgetStatePropertyAll<OutlinedBorder>(const StadiumBorder());
  const buttonSize = WidgetStatePropertyAll(Size.fromHeight(SohojSize.sizeButton));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    fontFamily: SohojType.ui,
    fontFamilyFallback: const [SohojType.bangla],
    textTheme: TextTheme(
      displaySmall: c(SohojType.display),
      titleLarge: c(SohojType.title),
      labelLarge: c(SohojType.label),
      bodyLarge: c(SohojType.bodyLg),
      bodyMedium: c(SohojType.body),
      bodySmall: c(SohojType.caption, p.inkMuted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: buttonSize,
        shape: pill,
        backgroundColor: WidgetStatePropertyAll(p.accent),
        foregroundColor: WidgetStatePropertyAll(p.onAccent),
        textStyle: const WidgetStatePropertyAll(SohojType.label),
        iconSize: const WidgetStatePropertyAll(SohojSize.sizeIcon),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: buttonSize,
        shape: pill,
        foregroundColor: WidgetStatePropertyAll(p.ink),
        side: WidgetStatePropertyAll(BorderSide(color: p.lineStrong, width: 2)),
        textStyle: const WidgetStatePropertyAll(SohojType.label),
        iconSize: const WidgetStatePropertyAll(SohojSize.sizeIcon),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.square(SohojSize.sizeTouch)),
        backgroundColor: WidgetStatePropertyAll(p.surfaceRaised),
        foregroundColor: WidgetStatePropertyAll(p.ink),
        iconSize: const WidgetStatePropertyAll(SohojSize.sizeIcon),
      ),
    ),
    extensions: [SohojColors(p)],
  );
}
