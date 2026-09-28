import 'package:flutter/material.dart';

/// Tema oscuro Material 3 con estética gamer/CS2.
/// Esquema: naranja brillante CS como acento primario, rojo "perdido",
/// verde "completado", fondo casi-negro con tinte azul.
class AppTheme {
  // Naranjas CS (más vivos que antes).
  static const Color csOrange = Color(0xFFF59E0B);
  static const Color csOrangeBright = Color(0xFFFBA919);
  static const Color csOrangeDark = Color(0xFFB45309);
  static const Color csCyan = Color(0xFF22D3EE);
  static const Color csGreen = Color(0xFF22C55E);
  static const Color csRed = Color(0xFFEF4444);
  static const Color csBlue = Color(0xFF3B82F6);
  static const Color csPurple = Color(0xFFA855F7);
  static const Color csPink = Color(0xFFEC4899);

  // Fondos y bordes.
  static const Color bgDeep = Color(0xFF0B0E12);
  static const Color bgSurface = Color(0xFF111418);
  static const Color bgCard = Color(0xFF14171C);
  static const Color borderSubtle = Color(0xFF1F252D);
  static const Color borderStrong = Color(0xFF2A313B);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = const ColorScheme.dark(
      primary: csOrange,
      onPrimary: Colors.black,
      secondary: csCyan,
      surface: bgSurface,
      onSurface: Colors.white,
      error: csRed,
      onError: Colors.white,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: bgDeep,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: csOrange,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: borderStrong),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: csOrange, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFF1B1F25),
        labelStyle: TextStyle(color: Colors.white),
        selectedColor: csOrange,
        secondaryLabelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        side: BorderSide(color: borderStrong),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        contentTextStyle: const TextStyle(color: Colors.white70),
      ),
      dividerColor: borderStrong,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgSurface,
        selectedItemColor: csOrange,
        unselectedItemColor: Colors.white54,
      ),
    );
  }

  /// Color asociado al tier Premier (gris, celeste, azul, morado, rosa, rojo, dorado).
  static Color premierTierColor(String tierLabel) {
    switch (tierLabel) {
      case 'Dorado':
        return const Color(0xFFFFD24A);
      case 'Rojo':
        return csRed;
      case 'Rosa':
        return csPink;
      case 'Morado':
        return csPurple;
      case 'Azul':
        return csBlue;
      case 'Celeste':
        return csCyan;
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}
