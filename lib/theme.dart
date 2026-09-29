import 'package:flutter/material.dart';

/// Color tokens from docs/SPEC.md §5.4.
@immutable
class LucentColors extends ThemeExtension<LucentColors> {
  const LucentColors({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.hairline,
    required this.track,
    required this.accent,
    required this.onAccent,
    required this.caution,
    required this.over,
    required this.categories,
  });

  final Color background, surface, textPrimary, textSecondary, textTertiary;
  final Color hairline, track, accent, onAccent, caution, over;

  /// Muted category swatches (slate, teal, olive, ochre, clay, rose, violet, graphite).
  final List<Color> categories;

  Color category(int i) => categories[i % categories.length];

  static const light = LucentColors(
    background: Color(0xFFFAFAF9),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF16161A),
    textSecondary: Color(0xFF5E5E66),
    textTertiary: Color(0xFF8A8A93),
    hairline: Color(0xFFE7E7E4),
    track: Color(0xFFEDEDEA),
    accent: Color(0xFF2F5BD3),
    onAccent: Color(0xFFFFFFFF),
    caution: Color(0xFF9A6200),
    over: Color(0xFFA8472C),
    categories: [
      Color(0xFF4F72A8), Color(0xFF2F7F79), Color(0xFF6C7A2E), Color(0xFF95701F),
      Color(0xFFA65A3F), Color(0xFFA34F6D), Color(0xFF6E58A6), Color(0xFF62666D),
    ],
  );

  static const dark = LucentColors(
    background: Color(0xFF0F0F10),
    surface: Color(0xFF18181A),
    textPrimary: Color(0xFFF3F3F1),
    textSecondary: Color(0xFFA3A3AB),
    textTertiary: Color(0xFF76767F),
    hairline: Color(0xFF2A2A2E),
    track: Color(0xFF252528),
    accent: Color(0xFF8EA8FF),
    onAccent: Color(0xFF0F0F10),
    caution: Color(0xFFD8A64A),
    over: Color(0xFFE58E73),
    categories: [
      Color(0xFF8FA9D6), Color(0xFF6FB8B1), Color(0xFFA9B866), Color(0xFFD2AE5E),
      Color(0xFFDE9679), Color(0xFFD98FA9), Color(0xFFAC9BDB), Color(0xFFA2A6AD),
    ],
  );

  @override
  LucentColors copyWith() => this;

  @override
  LucentColors lerp(ThemeExtension<LucentColors>? other, double t) =>
      (other is LucentColors && t > 0.5) ? other : this;
}

/// Type scale from docs/SPEC.md §5.3. Amount styles always use tabular figures.
@immutable
class LucentText extends ThemeExtension<LucentText> {
  const LucentText({
    required this.displayAmount,
    required this.headlineAmount,
    required this.title,
    required this.body,
    required this.bodyAmount,
    required this.label,
    required this.caption,
  });

  final TextStyle displayAmount, headlineAmount, title, body, bodyAmount, label, caption;

  static const _tnum = [FontFeature.tabularFigures()];

  factory LucentText.of(LucentColors c) => LucentText(
        displayAmount: TextStyle(
            fontFamily: 'InterDisplay', fontWeight: FontWeight.w600, fontSize: 40,
            height: 48 / 40, letterSpacing: -0.8, color: c.textPrimary, fontFeatures: _tnum),
        headlineAmount: TextStyle(
            fontFamily: 'InterDisplay', fontWeight: FontWeight.w500, fontSize: 28,
            height: 36 / 28, letterSpacing: -0.4, color: c.textPrimary, fontFeatures: _tnum),
        title: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 20,
            height: 28 / 20, letterSpacing: -0.2, color: c.textPrimary),
        body: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 16,
            height: 24 / 16, color: c.textPrimary),
        bodyAmount: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16,
            height: 24 / 16, color: c.textPrimary, fontFeatures: _tnum),
        label: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14,
            height: 20 / 14, letterSpacing: 0.1, color: c.textPrimary, fontFeatures: _tnum),
        caption: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 13,
            height: 18 / 13, letterSpacing: 0.1, color: c.textSecondary, fontFeatures: _tnum),
      );

  @override
  LucentText copyWith() => this;

  @override
  LucentText lerp(ThemeExtension<LucentText>? other, double t) =>
      (other is LucentText && t > 0.5) ? other : this;
}

extension LucentThemeX on BuildContext {
  LucentColors get colors => Theme.of(this).extension<LucentColors>()!;
  LucentText get text => Theme.of(this).extension<LucentText>()!;
}

ThemeData buildTheme(Brightness b) {
  final c = b == Brightness.light ? LucentColors.light : LucentColors.dark;
  final t = LucentText.of(c);
  final scheme = ColorScheme(
    brightness: b,
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.accent,
    onSecondary: c.onAccent,
    error: c.over,
    onError: c.onAccent,
    surface: c.background,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    outline: c.hairline,
    outlineVariant: c.hairline,
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: c.surface,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surface,
    surfaceContainerHighest: c.track,
  );
  const r8 = BorderRadius.all(Radius.circular(8));
  const r12 = BorderRadius.all(Radius.circular(12));
  final hair = BorderSide(color: c.hairline, width: 1);
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: c.background,
    extensions: [c, t],
    splashFactory: InkRipple.splashFactory,
    textTheme: TextTheme(
      titleLarge: t.title,
      titleMedium: t.body.copyWith(fontWeight: FontWeight.w500),
      bodyLarge: t.body,
      bodyMedium: t.label.copyWith(fontWeight: FontWeight.w400),
      bodySmall: t.caption,
      labelLarge: t.label,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: t.title,
    ),
    dividerTheme: DividerThemeData(color: c.hairline, thickness: 0, space: 0),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: c.accent.withValues(alpha: 0.14),
      labelTextStyle: WidgetStatePropertyAll(t.caption.copyWith(color: c.textPrimary)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.accent,
      foregroundColor: c.onAccent,
      elevation: b == Brightness.light ? 2 : 0,
      highlightElevation: b == Brightness.light ? 2 : 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: const RoundedRectangleBorder(borderRadius: r8),
        textStyle: t.label,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        side: hair,
        shape: const RoundedRectangleBorder(borderRadius: r8),
        textStyle: t.label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: const RoundedRectangleBorder(borderRadius: r8),
        textStyle: t.label,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        side: hair,
        selectedBackgroundColor: c.accent.withValues(alpha: 0.14),
        selectedForegroundColor: c.textPrimary,
        textStyle: t.label,
        shape: const RoundedRectangleBorder(borderRadius: r8),
      ),
    ),
    chipTheme: ChipThemeData(
      side: hair,
      shape: const RoundedRectangleBorder(borderRadius: r8),
      backgroundColor: c.background,
      selectedColor: c.accent.withValues(alpha: 0.14),
      labelStyle: t.label,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      labelStyle: t.label.copyWith(color: c.textSecondary),
      hintStyle: t.body.copyWith(color: c.textTertiary),
      border: OutlineInputBorder(borderRadius: r8, borderSide: hair),
      enabledBorder: OutlineInputBorder(borderRadius: r8, borderSide: hair),
      focusedBorder: OutlineInputBorder(
          borderRadius: r8, borderSide: BorderSide(color: c.accent, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: b == Brightness.light ? 2 : 0,
      shape: const RoundedRectangleBorder(borderRadius: r12),
      titleTextStyle: t.title,
      contentTextStyle: t.body,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: b == Brightness.light ? 2 : 0,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: r12),
    ),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      titleTextStyle: t.body,
      subtitleTextStyle: t.caption,
      iconColor: c.textSecondary,
    ),
    iconTheme: IconThemeData(color: c.textSecondary, size: 24),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: r8),
    ),
  );
}
