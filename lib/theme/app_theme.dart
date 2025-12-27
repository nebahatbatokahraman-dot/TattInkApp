import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- YENİ RENK PALETİ (Midnight Navy & Gold) ---
  
  // Ana Renkler (Brand Colors)
  static const Color primaryColor = Color(0xFFdb677c);      // Buton 1 (Tok Altın)
  static const Color primaryLightColor = Color(0xFFDA8594); // Buton 2 (Açık Altın)
  // Arka Planlar (Atmosphere)
  static const Color backgroundColor = Color(0xFF0a0e17);
  static const Color backgroundSecondaryColor = Color(0xFF121620);   // Background (Derin Lacivert)
  static const Color cardColor = Color(0xFF121620);         // Card 1 (Kart Zemini)
  static const Color cardLightColor = Color(0xFF20232A);    // Card 2 (Daha açık alanlar / Borderlar)
  
  // Metinler (Typography)
  static const Color textColor = Color(0xFFFBEFEF);         // Text 1 (Ana Başlıklar)
  static const Color textSecondaryColor = Color(0xFFFCF8F8);// Text 2 (Alt Metinler)
  static const Color textAccentColor = Color(0xFFFCF9EA);   // Text 3 (Altın ışıltılı beyaz)
  static const Color textDarkColor = Color(0xFF0a0e17);
  static const Color textGreyColor = Color(0xFF4a4a4a);     // Text 4 (Dark Metin)


  // Diğer
  static const Color dividerColor = Color(0xFF20232A);      // Ayırıcılar için Card 2 rengini kullandık
  static const Color errorColor = Color(0xFFCF6679);

 

  // Reflect Gradient //

  // 1. ORTA (YANSIMA) RENGİ
  // Yansımanın en parlak, en "vuran" noktası burası olacak.
  // Mevcut backgroundColor'dan biraz daha açık, hafif morumsu gri.
  static const Color atmosphericHighlightColor = Color(0x8028324a); // Biraz daha açıldı (Highlight)

  // 2. KENAR (ZEMİN) RENGİ
  // Yansımanın sönümlendiği, karanlık kısım.
  static const Color atmosphericBaseColor = backgroundColor; 

  // --- REFLECT (YANSIMA) GRADYAN TANIMI ---
  static const LinearGradient atmosphericBackgroundGradient = LinearGradient(
    // Sol üstten sağ alta doğru vuran bir ışık yansıması (Diyagonal Reflect)
    begin: Alignment.topLeft, 
    end: Alignment.bottomRight,
    
    // REFLECT MANTIĞI: Karanlık -> Aydınlık -> Karanlık
    // Bu sıralama ekrana "bombeli" veya ortası ışıklı bir derinlik katar.
    colors: [
      atmosphericBaseColor,      // Başlangıç (Karanlık)
      atmosphericHighlightColor, // Orta Nokta (Yansıma/Işık)
      atmosphericBaseColor,      // Bitiş (Karanlık)
    ],
    
    // Durak Noktaları (Stops):
    // 0.0 -> Başlangıç
    // 0.5 -> Tam orta (Işığın en yoğun olduğu yer)
    // 1.0 -> Bitiş
    stops: [0.3, 0.4, 0.5], 
  );












  // --- TİPOGRAFİ ---
  static TextTheme _buildDarkTextTheme() {
    return TextTheme(
      // Başlıklar (Montserrat)
      displayLarge: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w600, height: 1.20, color: textColor),
      displayMedium: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w600, height: 1.22, color: textColor),
      displaySmall: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w600, height: 1.22, color: textColor),
      headlineLarge: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w600, height: 1.25, color: textColor),
      headlineMedium: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w600, height: 1.28, color: textColor),
      headlineSmall: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600, height: 1.30, color: textColor),
      titleLarge: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, height: 1.30, color: textColor),
      titleMedium: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, height: 1.30, color: textSecondaryColor),
      titleSmall: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, height: 1.30, color: textSecondaryColor),

      // İçerik (Open Sans)
      bodyLarge: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.w400, height: 1.50, color: textColor),
      bodyMedium: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.w400, height: 1.50, color: textSecondaryColor),
      bodySmall: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w400, height: 1.45, color: textSecondaryColor.withOpacity(0.7)),
      labelLarge: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.w600, height: 1.30, color: textColor),
      labelMedium: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w600, height: 1.30, color: textColor),
      labelSmall: GoogleFonts.openSans(fontSize: 11, fontWeight: FontWeight.w600, height: 1.25, color: textAccentColor),
    );
  }

  // --- THEME DATA ---
  static ThemeData get darkTheme {
    final textTheme = _buildDarkTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      
      // Renk Şeması
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryLightColor,
        surface: cardColor,
        error: errorColor,
        onPrimary: backgroundColor,
        onSecondary: backgroundColor,
        onSurface: textColor,
        onError: backgroundColor,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textColor),
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: primaryColor),
      ),

      // Text Theme
      textTheme: textTheme,

      // Input (TextField) Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardLightColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardLightColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: TextStyle(color: textSecondaryColor.withOpacity(0.7)),
        hintStyle: TextStyle(color: textSecondaryColor.withOpacity(0.5)),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardLightColor.withOpacity(0.5), width: 1),
        ),
      ),

      // ElevatedButton Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4),
        ),
      ),

      // OutlinedButton Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // TextButton Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLightColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: backgroundColor.withOpacity(0.95),
        elevation: 10,
        selectedItemColor: primaryColor, 
        selectedIconTheme: const IconThemeData(color: primaryColor, size: 26),
        selectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedItemColor: Colors.grey.shade600,
        unselectedIconTheme: IconThemeData(color: Colors.grey.shade600, size: 24),
        unselectedLabelStyle: GoogleFonts.openSans(fontWeight: FontWeight.w400, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: cardLightColor,
        thickness: 1,
        space: 24,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: textColor,
        size: 24,
      ),
      
      // 🔥 DÜZELTİLEN KISIM: DialogTheme -> DialogThemeData
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: primaryColor, width: 1),
        ),
        titleTextStyle: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
        contentTextStyle: GoogleFonts.openSans(fontSize: 16, color: textSecondaryColor),
      ),
    );
  }
}