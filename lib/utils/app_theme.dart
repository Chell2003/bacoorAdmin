import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Professional Color Palette
const Color primaryColor = Color(0xFF1565C0);  // Deeper blue for better contrast
const Color secondaryColor = Color(0xFF424242); // Dark gray for text
const Color accentColor = Color(0xFF2E7D32);    // Professional green
const Color surfaceColor = Color(0xFFFFFFFF);   // White background

// Semantic Colors
const Color successColor = Color(0xFF43A047);   // Green
const Color warningColor = Color(0xFFFFA000);   // Amber
const Color errorColor = Color(0xFFD32F2F);     // Red
const Color infoColor = Color(0xFF1976D2);      // Blue

// Additional Colors for UI Elements
const Color cardBackgroundColor = Color(0xFFFAFAFA);  // Lighter gray for cards
const Color dividerColor = Color(0xFFEEEEEE);        // Subtle divider
const Color shadowColor = Color(0x1A000000);         // Transparent black for shadows
const Color hoverColor = Color(0x0A1565C0);         // Subtle hover effect
const Color selectedColor = Color(0x1A1565C0);      // Subtle selected state

// Elevation
const double cardElevation = 2.0;
const double dialogElevation = 24.0;
const double dropdownElevation = 8.0;

// Border Radius
const double borderRadiusSmall = 4.0;
const double borderRadiusMedium = 8.0;
const double borderRadiusLarge = 12.0;

// Spacing
const double spacingXSmall = 4.0;
const double spacingSmall = 8.0;
const double spacingMedium = 16.0;
const double spacingLarge = 24.0;
const double spacingXLarge = 32.0;

// Typography
final TextTheme appTextTheme = TextTheme(
  displayLarge: GoogleFonts.roboto(fontSize: 96, fontWeight: FontWeight.w300, letterSpacing: -1.5),
  displayMedium: GoogleFonts.roboto(fontSize: 60, fontWeight: FontWeight.w300, letterSpacing: -0.5),
  displaySmall: GoogleFonts.roboto(fontSize: 48, fontWeight: FontWeight.w400),
  headlineMedium: GoogleFonts.roboto(fontSize: 34, fontWeight: FontWeight.w400, letterSpacing: 0.25),
  headlineSmall: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.w400),
  titleLarge: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 0.15),
  titleMedium: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15),
  titleSmall: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
  bodyLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
  bodyMedium: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
  labelLarge: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.25),
  bodySmall: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
  labelSmall: GoogleFonts.roboto(fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 1.5),
);

// ThemeData
final ThemeData appTheme = ThemeData(
  primaryColor: primaryColor,
  colorScheme: ColorScheme(
    primary: primaryColor,
    secondary: accentColor,
    surface: surfaceColor,
    error: errorColor,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: secondaryColor,
    onError: Colors.white,
    brightness: Brightness.light,
  ),
  textTheme: appTextTheme,
  cardTheme: CardTheme(
    elevation: cardElevation,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
    ),
    color: cardBackgroundColor,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: spacingMedium, vertical: spacingSmall),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusSmall),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: surfaceColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusSmall),
      borderSide: const BorderSide(color: dividerColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusSmall),
      borderSide: const BorderSide(color: dividerColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusSmall),
      borderSide: BorderSide(color: primaryColor),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: spacingMedium,
      vertical: spacingSmall,
    ),
  ),
  dividerTheme: const DividerThemeData(
    space: spacingMedium,
    thickness: 1,
    color: dividerColor,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: surfaceColor,
    foregroundColor: secondaryColor,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: appTextTheme.titleLarge,
  ),
);
