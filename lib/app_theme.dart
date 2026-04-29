import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────
//  CARBON THEME — Dark + Light
//  Accent: #C8FF00 (electric lime)
//  Font: Outfit + DM Mono
// ─────────────────────────────────────────────────────

class AppColors {
  // ── Accent ──
  static const accent       = Color(0xFFC8FF00);
  static const accentDark   = Color(0xFF9FCC00);
  static const danger       = Color(0xFFFF4444);
  static const success      = Color(0xFFC8FF00);
  static const warning      = Color(0xFFFFB300);

  // ── Dark Mode ──
  static const darkBg       = Color(0xFF0A0A0A);
  static const darkSurface  = Color(0xFF111111);
  static const darkSurface2 = Color(0xFF1A1A1A);
  static const darkBorder   = Color(0xFF1E1E1E);
  static const darkBorder2  = Color(0xFF2A2A2A);
  static const darkText     = Color(0xFFFFFFFF);
  static const darkTextSec  = Color(0xFF888888);
  static const darkTextMut  = Color(0xFF444444);

  // ── Light Mode ──
  static const lightBg      = Color(0xFFF2F2F0);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurface2= Color(0xFFE8E8E4);
  static const lightBorder  = Color(0xFFE5E5E0);
  static const lightBorder2 = Color(0xFFD0D0CA);
  static const lightText    = Color(0xFF111111);
  static const lightTextSec = Color(0xFF444444);
  static const lightTextMut = Color(0xFF666666);

  // ── Gradients ──
  static const accentGradient = LinearGradient(
    colors: [Color(0xFFC8FF00), Color(0xFF9FCC00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF111111)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color accentOrBlack(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.accent
        : Colors.black;
  }
  static Color WhiteOrBlack(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
  ? Colors.white
      : Colors.black;
  }
}

// ─────────────────────────────────────────────────────
//  Theme Extension — gives access to colors anywhere
// ─────────────────────────────────────────────────────
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color border2;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const AppThemeColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.border2,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  AppThemeColors copyWith({
    Color? bg, Color? surface, Color? surface2,
    Color? border, Color? border2,
    Color? textPrimary, Color? textSecondary, Color? textMuted,
  }) => AppThemeColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    surface2: surface2 ?? this.surface2,
    border: border ?? this.border,
    border2: border2 ?? this.border2,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
  );

  @override
  AppThemeColors lerp(AppThemeColors? other, double t) {
    if (other == null) return this;
    return AppThemeColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      border: Color.lerp(border, other.border, t)!,
      border2: Color.lerp(border2, other.border2, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }

  static const dark = AppThemeColors(
    bg: AppColors.darkBg,
    surface: AppColors.darkSurface,
    surface2: AppColors.darkSurface2,
    border: AppColors.darkBorder,
    border2: AppColors.darkBorder2,
    textPrimary: AppColors.darkText,
    textSecondary: AppColors.darkTextSec,
    textMuted: AppColors.darkTextMut,
  );

  static const light = AppThemeColors(
    bg: AppColors.lightBg,
    surface: AppColors.lightSurface,
    surface2: AppColors.lightSurface2,
    border: AppColors.lightBorder,
    border2: AppColors.lightBorder2,
    textPrimary: AppColors.lightText,
    textSecondary: AppColors.lightTextSec,
    textMuted: AppColors.lightTextMut,
  );
}

// ─────────────────────────────────────────────────────
//  Helper to get theme colors anywhere
// ─────────────────────────────────────────────────────
AppThemeColors tc(BuildContext context) =>
    Theme.of(context).extension<AppThemeColors>()!;

// ─────────────────────────────────────────────────────
//  Text Styles — use Outfit + DM Mono
// ─────────────────────────────────────────────────────
class AppText {
  static TextStyle heading1(BuildContext context) => GoogleFonts.outfit(
    fontSize: 24, fontWeight: FontWeight.w800,
    color: tc(context).textPrimary, letterSpacing: -0.5,
  );

  static TextStyle heading2(BuildContext context) => GoogleFonts.outfit(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: tc(context).textPrimary, letterSpacing: -0.3,
  );

  static TextStyle heading3(BuildContext context) => GoogleFonts.outfit(
    fontSize: 15, fontWeight: FontWeight.w700,
    color: tc(context).textPrimary,
  );

  static TextStyle body(BuildContext context) => GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: tc(context).textPrimary,
  );

  static TextStyle bodyMed(BuildContext context) => GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: tc(context).textPrimary,
  );

  static TextStyle small(BuildContext context) => GoogleFonts.outfit(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: tc(context).textSecondary,
  );

  static TextStyle label(BuildContext context) => GoogleFonts.dmMono(
    fontSize: 10, fontWeight: FontWeight.w500,
    color: tc(context).textMuted, letterSpacing: 1.5,
  );

  static TextStyle mono(BuildContext context) => GoogleFonts.dmMono(
    fontSize: 12, fontWeight: FontWeight.w500,
    color: tc(context).textSecondary,
  );

  static TextStyle accent(BuildContext context) => GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.w700,
    color: AppColors.accent,
  );

  // Static versions (no context needed)
  static TextStyle get headingStatic => GoogleFonts.outfit(
    fontSize: 24, fontWeight: FontWeight.w800,
    color: Colors.white, letterSpacing: -0.5,
  );

  static TextStyle get labelStatic => GoogleFonts.dmMono(
    fontSize: 10, fontWeight: FontWeight.w500,
    color: const Color(0xFF444444), letterSpacing: 1.5,
  );
}

// ─────────────────────────────────────────────────────
//  Dark Theme
// ─────────────────────────────────────────────────────
ThemeData get darkTheme => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkBg,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.accent,
    surface: AppColors.darkSurface,
    error: AppColors.danger,
  ),
  extensions: const [AppThemeColors.dark],
  textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkBg,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkSurface,
    hintStyle: GoogleFonts.outfit(color: const Color(0xFF444444), fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.darkBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.darkBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.darkSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.darkBorder),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((s) =>
    s.contains(WidgetState.selected) ? AppColors.darkBg : AppColors.darkTextMut),
    trackColor: WidgetStateProperty.resolveWith((s) =>
    s.contains(WidgetState.selected) ? AppColors.accent : AppColors.darkBorder2),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    selectedItemColor: AppColors.accent,
    unselectedItemColor: Color(0xFF444444),
    elevation: 0,
  ),
);

// ─────────────────────────────────────────────────────
//  Light Theme
// ─────────────────────────────────────────────────────
ThemeData get lightTheme => ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightBg,
  colorScheme: const ColorScheme.light(
    primary: AppColors.lightText,
    surface: AppColors.lightSurface,
    error: AppColors.danger,
  ),
  extensions: const [AppThemeColors.light],
  textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.lightBg,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.lightText),
    titleTextStyle: TextStyle(
      color: AppColors.lightText, fontSize: 16, fontWeight: FontWeight.w700,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightSurface,
    hintStyle: GoogleFonts.outfit(color: const Color(0xFFAAAAAA), fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.lightBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.lightBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.lightText, width: 1.5),
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.lightSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.lightBorder),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((s) =>
    s.contains(WidgetState.selected) ? AppColors.lightBg : AppColors.lightTextMut),
    trackColor: WidgetStateProperty.resolveWith((s) =>
    s.contains(WidgetState.selected) ? AppColors.lightText : AppColors.lightBorder2),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.lightSurface,
    selectedItemColor: AppColors.lightText,
    unselectedItemColor: AppColors.lightTextMut,
    elevation: 0,
  ),
);

// ─────────────────────────────────────────────────────
//  Legacy support — keeps old code working
//  Screens will be migrated to use tc(context) instead
// ─────────────────────────────────────────────────────
class AppTextStyles {
  static TextStyle get heading1 => GoogleFonts.outfit(
    fontSize: 24, fontWeight: FontWeight.w800,
    color: Colors.white, letterSpacing: -0.5,
  );
  static TextStyle get heading2 => GoogleFonts.outfit(
    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
  );
  static TextStyle get bodySmall => GoogleFonts.outfit(
    fontSize: 13, color: const Color(0xFF888888),
  );
  static TextStyle get label => GoogleFonts.dmMono(
    fontSize: 10, fontWeight: FontWeight.w500,
    color: const Color(0xFF444444), letterSpacing: 1.5,
  );
}