import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Color Palette
const Color primaryColor = Color(0xFF2A65C8); // Kept as is
const Color secondaryColor = Color(0xFF333333); // Existing dark secondary, used for text/borders

// New Accent/Secondary Color
const Color yellowAccentColor = Color(0xFFFFC107);
const Color onYellowAccentColor = Colors.black; // For text/icons on yellowAccentColor

const Color errorColor = Color(0xFFDC3545);
const Color surfaceColor = Color(0xFFFFFFFF); // White background

// Typography
final TextTheme appTextTheme = TextTheme(
  headline1: GoogleFonts.roboto(fontSize: 96, fontWeight: FontWeight.w300, letterSpacing: -1.5),
  headline2: GoogleFonts.roboto(fontSize: 60, fontWeight: FontWeight.w300, letterSpacing: -0.5),
  headline3: GoogleFonts.roboto(fontSize: 48, fontWeight: FontWeight.w400),
  headline4: GoogleFonts.roboto(fontSize: 34, fontWeight: FontWeight.w400, letterSpacing: 0.25),
  headline5: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.w400),
  headline6: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 0.15),
  subtitle1: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15),
  subtitle2: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
  bodyText1: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
  bodyText2: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
  button: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.25),
  caption: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
  overline: GoogleFonts.roboto(fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 1.5),
);

// ThemeData
final ThemeData appTheme = ThemeData(
  primaryColor: primaryColor,
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: MaterialColor( // Need to provide a swatch for fromSwatch to work correctly
      primaryColor.value,
      <int, Color>{
        50: primaryColor.withOpacity(0.1),
        100: primaryColor.withOpacity(0.2),
        200: primaryColor.withOpacity(0.3),
        300: primaryColor.withOpacity(0.4),
        400: primaryColor.withOpacity(0.5),
        500: primaryColor.withOpacity(0.6),
        600: primaryColor.withOpacity(0.7),
        700: primaryColor.withOpacity(0.8),
        800: primaryColor.withOpacity(0.9),
        900: primaryColor,
      },
    ),
  ).copyWith(
    primary: primaryColor, // Ensure primary is set
    secondary: yellowAccentColor, // New yellow secondary
    onSecondary: onYellowAccentColor, // Contrast color for yellow
    tertiary: yellowAccentColor, // Using tertiary also for the new accent
    onTertiary: onYellowAccentColor, // Contrast for tertiary
    error: errorColor,
    surface: surfaceColor, // Standard surface color
    onSurface: secondaryColor, // Dark text on light surfaces
    background: surfaceColor, // App background
    onBackground: secondaryColor, // Text on app background
  ),
  scaffoldBackgroundColor: surfaceColor, // Changed to white
  textTheme: appTextTheme.apply(
    bodyColor: secondaryColor, // Default text color
    displayColor: secondaryColor,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: primaryColor, // AppBar still uses primary
    elevation: 4,
    titleTextStyle: appTextTheme.headline6?.copyWith(color: surfaceColor), // Text on primary appbar
    iconTheme: const IconThemeData(color: surfaceColor), // Icons on primary appbar
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor, // Default button is primary
      foregroundColor: surfaceColor, // Text on primary button
      textStyle: appTextTheme.button,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  // Example: If you want some buttons to use the accent color:
  // TextButtonThemeData for text buttons, OutlinedButtonThemeData for outlined ones
  // You might create specific styles in widgets or a utility class for different button types
  // e.g., success buttons would now use yellowAccentColor
  
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder( // Default border for text fields
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: secondaryColor.withOpacity(0.4)), // Lighter border
    ),
    enabledBorder: OutlineInputBorder( // Border when text field is enabled but not focused
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: secondaryColor.withOpacity(0.4)),
    ),
    focusedBorder: OutlineInputBorder( // Border when text field is focused
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: primaryColor, width: 2), // Focused uses primary
    ),
    labelStyle: appTextTheme.bodyText1?.copyWith(color: secondaryColor.withOpacity(0.8)),
    hintStyle: appTextTheme.bodyText2?.copyWith(color: secondaryColor.withOpacity(0.6)),
    errorStyle: appTextTheme.caption?.copyWith(color: errorColor),
    filled: true,
    fillColor: surfaceColor, // Background of text field
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  // Ensure other component themes are reviewed if they used the old green accent.
  // For instance, if FloatingActionButtonThemeData used accentColor, update it.
  // floatingActionButtonTheme: FloatingActionButtonThemeData(
  //   backgroundColor: yellowAccentColor,
  //   foregroundColor: onYellowAccentColor,
  // ),
  // TabBarTheme, CardTheme, DialogTheme etc. should also be checked.
  // For now, the explicit changes are made as requested.
);
