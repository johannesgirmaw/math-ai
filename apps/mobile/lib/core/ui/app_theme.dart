import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MATH SI teal, gold, charcoal, and white. Shared with the web app.
abstract final class AxiomColors {
  static const paper = Color(0xFFF4F8F9);
  static const ink = Color(0xFF2B2D42);
  static const accent = Color(0xFF005F73);
  static const gold = Color(0xFFD4AF37);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFD3E2E6);
  static const success = Color(0xFF1F7A4D);
  static const miss = Color(0xFF8C3A32);
}

/// Light theme for the learning app.
abstract final class AppTheme {
  static ThemeData light() {
    final body = GoogleFonts.interTextTheme().apply(
      bodyColor: AxiomColors.ink,
      displayColor: AxiomColors.ink,
    );
    const scheme = ColorScheme.light(
      primary: AxiomColors.accent,
      secondary: AxiomColors.gold,
      onSecondary: AxiomColors.ink,
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
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: IconThemeData(color: AxiomColors.ink),
        shape: Border(
          bottom: BorderSide(color: AxiomColors.gold, width: 2),
        ),
      ),
      textTheme: body.copyWith(
        headlineLarge: GoogleFonts.montserrat(
          fontSize: 40,
          height: 1.1,
          fontWeight: FontWeight.w700,
          color: AxiomColors.ink,
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontSize: 28,
          height: 1.15,
          fontWeight: FontWeight.w700,
          color: AxiomColors.ink,
        ),
        headlineSmall: GoogleFonts.montserrat(
          fontSize: 22,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: AxiomColors.accent,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 18,
          height: 1.1,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: AxiomColors.ink,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          height: 1.25,
          fontWeight: FontWeight.w600,
          color: AxiomColors.ink,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          height: 1.4,
          color: AxiomColors.ink,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          height: 1.4,
          color: AxiomColors.ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AxiomColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AxiomColors.line,
          disabledForegroundColor: AxiomColors.ink.withValues(alpha: 0.45),
          minimumSize: const Size(44, 56),
          textStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AxiomColors.ink,
          minimumSize: const Size(44, 56),
          side: const BorderSide(color: AxiomColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AxiomColors.accent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AxiomColors.accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AxiomColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AxiomColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AxiomColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AxiomColors.accent, width: 2),
        ),
      ),
    );
  }
}
