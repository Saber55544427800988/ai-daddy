import 'package:flutter/material.dart';

/// AI Daddy App Theme — Deep navy + glowing cyan, matching the app icon.
class AppTheme {
  // ── Brand Colors (from icon) ──
  static const Color navyDark = Color(0xFF0A1628);
  static const Color navyMid = Color(0xFF0F2140);
  static const Color navySurface = Color(0xFF132742);
  static const Color navyCard = Color(0xFF16305A);
  static const Color glowCyan = Color(0xFF00BFFF); // AI chip glow
  static const Color glowCyanLight = Color(0xFF66D9FF);
  static const Color accentBlue = Color(0xFF339DFF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFE8F0FE);
  static const Color textSecondary = Color(0xFF8DA4BF);
  static const Color successGreen = Color(0xFF00E676);
  static const Color dangerRed = Color(0xFFFF5252);
  static const Color tokenGold = Color(0xFFFFD740);
  static const Color warmOrange = Color(0xFFFFAB40);

  // ── Legacy aliases (so existing code still compiles) ──
  static const Color primaryBlue = glowCyan;
  static const Color darkText = textPrimary;
  static const Color lightGrey = navySurface;
  static const Color mediumGrey = textSecondary;
  static const Color backgroundLight = navyDark;
  static const Color chatBubbleUser = accentBlue;
  static const Color chatBubbleAI = navyCard;

  /// Gradient used across hero cards & backgrounds
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF112240)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF162D50), Color(0xFF0F2140)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glowGradient = LinearGradient(
    colors: [Color(0xFF00BFFF), Color(0xFF339DFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: glowCyan,
        secondary: accentBlue,
        surface: navySurface,
        onPrimary: navyDark,
        onSecondary: white,
        onSurface: textPrimary,
        error: dangerRed,
      ),
      scaffoldBackgroundColor: navyDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: navyMid,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: white,
          letterSpacing: 0.5,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: glowCyan,
        foregroundColor: navyDark,
      ),
      cardTheme: CardThemeData(
        color: navyCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: navySurface,
        hintStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: glowCyan,
          foregroundColor: navyDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: glowCyanLight),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? glowCyan : textSecondary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? glowCyan.withOpacity(0.35)
                : navySurface),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: glowCyan,
        inactiveTrackColor: navySurface,
        thumbColor: glowCyan,
        overlayColor: Color(0x2200BFFF),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: navyCard,
        contentTextStyle: const TextStyle(color: white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: navySurface,
        selectedColor: glowCyan.withOpacity(0.2),
        labelStyle: const TextStyle(color: textPrimary),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: glowCyan,
        linearTrackColor: navySurface,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: navyMid,
        selectedItemColor: glowCyan,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      dividerColor: navySurface,
    );
  }
}
