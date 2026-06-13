import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();
  static const nearBlack = Color(0xFF0D0D0D);
  static const surface = Color(0xFFF5F3EE);
  static const saffron = Color(0xFFFF9933);
  static const onSurface = Color(0xFF1A1A1A);
  static const muted = Color(0xFF6B6B6B);
  static const divider = Color(0xFFE8E4DC);
  static const success = Color(0xFF2E7D32);
  static const white = Colors.white;
  static const drawerBg = Color(0xFF111111);
  static const cardBg = Color(0xFFFFFFFF);
  static const heroBg = Color(0xFF0D0D0D);
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: ColorScheme.light(
        primary: AppColors.saffron,
        onPrimary: AppColors.white,
        secondary: AppColors.nearBlack,
        onSecondary: AppColors.white,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        outline: AppColors.divider,
      ),
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.nearBlack,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        actionsIconTheme: const IconThemeData(color: AppColors.saffron),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.drawerBg,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        selectedColor: AppColors.saffron,
        iconColor: AppColors.muted,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.muted,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.muted,
        ),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.saffron, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.saffron,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.saffron,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.nearBlack,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.white,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.saffron,
      ),
    );
  }

  static TextTheme get _textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        height: 1.7,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.muted,
      ),
    );
  }
}
