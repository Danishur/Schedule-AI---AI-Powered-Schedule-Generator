import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFFAFA9EC);
  static const Color primaryDark = Color(0xFF3C3489);
  static const Color secondary = Color(0xFF00B894);
  static const Color secondaryLight = Color(0xFF5DCAA5);
  static const Color accent = Color(0xFFFD79A8);
  static const Color warning = Color(0xFFEF9F27);
  static const Color danger = Color(0xFFE24B4A);
  static const Color surface = Color(0xFFF8F7FF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textMuted = Color(0xFFB2BEC3);
  static const Color borderColor = Color(0xFFE5E3FF);

  static const Color highPriority = Color(0xFFD85A30);
  static const Color highPriorityBg = Color(0xFFFAECE7);
  static const Color medPriority = Color(0xFFBA7517);
  static const Color medPriorityBg = Color(0xFFFAEEDA);
  static const Color lowPriority = Color(0xFF1D9E75);
  static const Color lowPriorityBg = Color(0xFFE1F5EE);
  static const Color breakColor = Color(0xFF636E72);
  static const Color breakBg = Color(0xFFF1F2F6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: surface,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardColor: cardBg,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
        hintStyle:
            GoogleFonts.plusJakartaSans(color: textMuted, fontSize: 14),
        labelStyle: GoogleFonts.plusJakartaSans(
            color: textSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme:
          const DividerThemeData(color: borderColor, thickness: 1),
    );
  }

  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return highPriority;
      case 'medium':
        return medPriority;
      case 'low':
        return lowPriority;
      default:
        return textMuted;
    }
  }

  static Color priorityBgColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return highPriorityBg;
      case 'medium':
        return medPriorityBg;
      case 'low':
        return lowPriorityBg;
      default:
        return breakBg;
    }
  }

  static Color blockColor(String type) {
    switch (type.toLowerCase()) {
      case 'high':
        return highPriority;
      case 'medium':
        return medPriority;
      case 'low':
        return lowPriority;
      case 'break':
        return breakColor;
      default:
        return primary;
    }
  }

  static Color blockBgColor(String type) {
    switch (type.toLowerCase()) {
      case 'high':
        return highPriorityBg;
      case 'medium':
        return medPriorityBg;
      case 'low':
        return lowPriorityBg;
      case 'break':
        return breakBg;
      default:
        return surface;
    }
  }
}