import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Retro 80s/90s Retroflex Gym Color Palette
const kRetroHotPink = Color(0xFFFF007F); // Primary Neon Hot Pink
const kRetroNeonCyan = Color(0xFF00F0FF); // Secondary Electric Cyan
const kRetroElectricYellow = Color(0xFFCCFF00); // Highlight Neon Yellow
const kRetroPurpleDark = Color(0xFF130924); // Dark Synth Background
const kRetroCardDark = Color(0xFF21113B); // Dark Retro Card
const kRetroCardDarkBorder = Color(0xFF3D1F6D);
const kRetroPurpleLight = Color(0xFFF6EFF9); // Light Retro Background
const kRetroCardLight = Color(0xFFFFFFFF);
const kRetroNeonGreen = Color(0xFF00FF66);
const kRetroNeonRed = Color(0xFFFF2A6D);

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: kRetroHotPink,
    onPrimary: Colors.white,
    primaryContainer: isDark ? const Color(0xFF3B1044) : const Color(0xFFFFD6EC),
    onPrimaryContainer: isDark ? kRetroNeonCyan : const Color(0xFF500026),
    secondary: kRetroNeonCyan,
    onSecondary: Colors.black,
    secondaryContainer: isDark ? const Color(0xFF003B46) : const Color(0xFFD0F8FF),
    onSecondaryContainer: isDark ? Colors.white : const Color(0xFF00363F),
    tertiary: kRetroElectricYellow,
    onTertiary: Colors.black,
    error: kRetroNeonRed,
    onError: Colors.white,
    surface: isDark ? kRetroCardDark : kRetroCardLight,
    onSurface: isDark ? const Color(0xFFF0E6FF) : const Color(0xFF1E0A2A),
    surfaceContainerHigh: isDark ? const Color(0xFF2B164A) : const Color(0xFFF0E4F5),
    outline: isDark ? kRetroNeonCyan.withValues(alpha: 0.5) : kRetroHotPink.withValues(alpha: 0.5),
    outlineVariant: isDark ? kRetroCardDarkBorder : const Color(0xFFE2C6F0),
  );

  final baseTextTheme = GoogleFonts.chakraPetchTextTheme(
    isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
  );

  final displayFont = GoogleFonts.righteous();
  final titleFont = GoogleFonts.orbitron(fontWeight: FontWeight.bold);

  final textTheme = baseTextTheme.copyWith(
    displayLarge: displayFont.copyWith(
      color: isDark ? Colors.white : const Color(0xFF1E0A2A),
      fontSize: 32,
      letterSpacing: 1.5,
    ),
    displayMedium: displayFont.copyWith(
      color: isDark ? Colors.white : const Color(0xFF1E0A2A),
      fontSize: 28,
      letterSpacing: 1.2,
    ),
    headlineMedium: displayFont.copyWith(
      color: isDark ? kRetroNeonCyan : kRetroHotPink,
      fontSize: 22,
      letterSpacing: 1.2,
    ),
    titleLarge: titleFont.copyWith(
      color: isDark ? Colors.white : const Color(0xFF1E0A2A),
      fontSize: 18,
      letterSpacing: 1.1,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      letterSpacing: 0.8,
    ),
    labelLarge: titleFont.copyWith(
      color: isDark ? kRetroElectricYellow : kRetroHotPink,
      fontSize: 13,
      letterSpacing: 1.2,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark ? kRetroPurpleDark : kRetroPurpleLight,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: isDark ? const Color(0xFF1A0A33) : const Color(0xFFEADBEE),
      foregroundColor: isDark ? kRetroNeonCyan : kRetroHotPink,
      elevation: 0,
      scrolledUnderElevation: 4,
      titleTextStyle: GoogleFonts.righteous(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: isDark ? kRetroNeonCyan : kRetroHotPink,
      ),
      iconTheme: IconThemeData(
        color: isDark ? kRetroNeonCyan : kRetroHotPink,
      ),
    ),
    cardTheme: CardThemeData(
      color: isDark ? kRetroCardDark : kRetroCardLight,
      elevation: isDark ? 6 : 2,
      shadowColor: isDark ? kRetroHotPink.withValues(alpha: 0.3) : Colors.black26,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? kRetroCardDarkBorder : const Color(0xFFE2C6F0),
          width: 1.5,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kRetroHotPink,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.orbitron(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          fontSize: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? kRetroNeonCyan : kRetroHotPink,
        side: BorderSide(
          color: isDark ? kRetroNeonCyan : kRetroHotPink,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.orbitron(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          fontSize: 13,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? kRetroNeonCyan : kRetroHotPink,
        textStyle: GoogleFonts.chakraPetch(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark ? const Color(0xFF2C164D) : const Color(0xFFEED8F8),
      selectedColor: kRetroHotPink,
      secondarySelectedColor: kRetroNeonCyan,
      labelStyle: GoogleFonts.chakraPetch(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isDark ? kRetroElectricYellow : const Color(0xFF4A0033),
      ),
      side: BorderSide(
        color: isDark ? kRetroHotPink.withValues(alpha: 0.6) : kRetroHotPink.withValues(alpha: 0.4),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF1C0D35) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? kRetroNeonCyan : kRetroHotPink),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? kRetroNeonCyan.withValues(alpha: 0.4) : kRetroHotPink.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? kRetroNeonCyan : kRetroHotPink,
          width: 2.5,
        ),
      ),
      labelStyle: GoogleFonts.chakraPetch(
        color: isDark ? kRetroNeonCyan : kRetroHotPink,
      ),
      hintStyle: GoogleFonts.chakraPetch(
        color: isDark ? Colors.white38 : Colors.black38,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kRetroHotPink,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kRetroNeonCyan, width: 2),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? kRetroHotPink.withValues(alpha: 0.3) : kRetroHotPink.withValues(alpha: 0.2),
      thickness: 1.5,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: isDark ? kRetroCardDark : kRetroCardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? kRetroNeonCyan : kRetroHotPink, width: 2),
      ),
      titleTextStyle: GoogleFonts.righteous(
        fontSize: 20,
        color: isDark ? kRetroNeonCyan : kRetroHotPink,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? const Color(0xFF2D1040) : const Color(0xFF330B30),
      contentTextStyle: GoogleFonts.chakraPetch(
        color: kRetroElectricYellow,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: kRetroHotPink, width: 1.5),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Color upColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? kRetroElectricYellow
        : const Color(0xFF00B020);

Color downColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? kRetroNeonRed
        : const Color(0xFFE51C23);
