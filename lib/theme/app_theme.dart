import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class AppTheme {
  // Colors
  static const Color backgroundColor = Color(0xFF191919);
  static const Color primaryColor = Color(0xFF944B79);
  static const Color textColor = Color(0xFFEBEBEB);
  static const Color cardColor = Color(0xFF2A2A2A);
  static const Color dividerColor = Color(0xFF3A3A3A);

  // Cohesive typography: Montserrat for headings/titles, Open Sans for body/labels
  static TextTheme _buildDarkTextTheme() {
    // Sizes follow a mobile-friendly Material 3 scale
    return TextTheme(
      // Display/Headline/Title use Montserrat with tighter leading
      displayLarge: GoogleFonts.montserrat(
        fontSize: 32, fontWeight: FontWeight.w600, height: 1.20, color: textColor,
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 28, fontWeight: FontWeight.w600, height: 1.22, color: textColor,
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: 24, fontWeight: FontWeight.w600, height: 1.22, color: textColor,
      ),
      headlineLarge: GoogleFonts.montserrat(
        fontSize: 22, fontWeight: FontWeight.w600, height: 1.25, color: textColor,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 20, fontWeight: FontWeight.w600, height: 1.28, color: textColor,
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: 18, fontWeight: FontWeight.w600, height: 1.30, color: textColor,
      ),
      titleLarge: GoogleFonts.montserrat(
        fontSize: 16, fontWeight: FontWeight.w600, height: 1.30, color: textColor,
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: 14, fontWeight: FontWeight.w600, height: 1.30, color: textColor,
      ),
      titleSmall: GoogleFonts.montserrat(
        fontSize: 12, fontWeight: FontWeight.w600, height: 1.30, color: textColor,
      ),

      // Body/Label use Open Sans with comfortable leading for readability
      bodyLarge: GoogleFonts.openSans(
        fontSize: 16, fontWeight: FontWeight.w400, height: 1.50, color: textColor,
      ),
      bodyMedium: GoogleFonts.openSans(
        fontSize: 14, fontWeight: FontWeight.w400, height: 1.50, color: textColor,
      ),
      bodySmall: GoogleFonts.openSans(
        fontSize: 12, fontWeight: FontWeight.w400, height: 1.45, color: textColor,
      ),
      labelLarge: GoogleFonts.openSans(
        fontSize: 14, fontWeight: FontWeight.w600, height: 1.30, color: textColor,
      ),
      labelMedium: GoogleFonts.openSans(
        fontSize: 12, fontWeight: FontWeight.w600, height: 1.30, color: textColor,
      ),
      labelSmall: GoogleFonts.openSans(
        fontSize: 11, fontWeight: FontWeight.w600, height: 1.25, color: textColor,
      ),
    );
  }

  // Theme Data
  static ThemeData get darkTheme {
    final textTheme = _buildDarkTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: cardColor,
        error: Colors.red,
        onPrimary: textColor,
        onSecondary: textColor,
        onSurface: textColor,
        onError: textColor,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        titleTextStyle: textTheme.titleLarge,
      ),

      // Text Theme
      textTheme: textTheme,

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: TextStyle(color: textColor.withAlpha(200)),
        hintStyle: TextStyle(color: textColor.withAlpha(150)),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        
        // --- SEÇİLİ OLAN (Selected) -> Kırık Beyaz ---
        selectedItemColor: const Color(0xFFdbdbdb), // Kırık beyaz
        selectedIconTheme: const IconThemeData(color: Color(0xFFdbdbdb)),

        // --- SEÇİLİ OLMAYAN (Unselected) -> Primary Color ---
        unselectedItemColor: primaryColor, // Direkt ana renk
        unselectedIconTheme: const IconThemeData(color: primaryColor),
        
        // --- YAZI STİLLERİ ---
        selectedLabelStyle: GoogleFonts.openSans(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.openSans(fontWeight: FontWeight.w400, fontSize: 12),
        type: BottomNavigationBarType.fixed,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: textColor,
        size: 24,
      ),
    );
  }
}