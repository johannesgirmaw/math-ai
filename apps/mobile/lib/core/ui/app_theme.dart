import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paper, ink, and accent colors shared with the web app.
abstract final class AxiomColors {
  static const paper = Color(0xFFF6F1E7);
  static const ink = Color(0xFF1C1915);
  static const accent = Color(0xFF2454FF);
  static const surface = Color(0xFFFFFCF7);
  static const line = Color(0xFFE4DCCF);
  static const success = Color(0xFF1F7A4D);
  static const miss = Color(0xFF8C3A32);
}

/// Light theme for the learning app.
abstract final class AppTheme {
  static ThemeData light() {
    final outfit = GoogleFonts.outfitTextTheme();
    const scheme = ColorScheme.light(
      primary: AxiomColors.accent,
      onPrimary: AxiomColors.surface,
      surface: AxiomColors.paper,
      onSurface: AxiomColors.ink,
      error: AxiomColors.miss,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AxiomColors.paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: AxiomColors.paper,
        foregroundColor: AxiomColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      textTheme: outfit.copyWith(
        headlineLarge: GoogleFonts.fraunces(
          fontSize: 40,
          height: 1.1,
          fontWeight: FontWeight.w600,
          color: AxiomColors.ink,
        ),
        headlineMedium: GoogleFonts.fraunces(
          fontSize: 28,
          height: 1.15,
          fontWeight: FontWeight.w600,
          color: AxiomColors.ink,
        ),
        headlineSmall: GoogleFonts.fraunces(
          fontSize: 22,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: AxiomColors.ink,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          height: 1.25,
          fontWeight: FontWeight.w600,
          color: AxiomColors.ink,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          height: 1.4,
          color: AxiomColors.ink,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          height: 1.4,
          color: AxiomColors.ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AxiomColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AxiomColors.line),
        ),
      ),
    );
  }
}
