import 'package:flutter/material.dart';

/// Brand colors
class AppColors {
  static const Color primary = Color(0xFF1FD365); // main green
  static const Color darkBg = Color(0xFF121212); // dark background
  static const Color lightMilky = Color(
    0xFFF9F9F9,
  ); // very light gray, close to white
  static const Color lightSurface = Colors.white; // cards/surfaces (light)
  static const Color darkSurface = Color(0xFF1E1E1E); // cards/surfaces (dark)
  static const Color grey = Color(0xFF9E9E9E);

  // On-colors (text/icons) for contrast
  static const Color onLight = Color(0xFF1A1A1A);
  static const Color onDark = Colors.white;
}

/// Base text sizes you requested (Material 3 names)
const TextTheme _baseText = TextTheme(
  titleLarge: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.25,
  ), // ~headline6
  titleMedium: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.30,
  ), // ~subtitle1
  bodyMedium: TextStyle(fontSize: 14, height: 1.40), // ~bodyText2
  bodySmall: TextStyle(fontSize: 10, height: 1.15), // ~caption
);

/// LIGHT THEME (default)
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.grey,
    background: AppColors.lightMilky,
    surface: AppColors.lightSurface,
    onPrimary: Colors.white,
    onSecondary: AppColors.onLight,
    onBackground: AppColors.onLight,
    onSurface: AppColors.onLight,
  ),
  scaffoldBackgroundColor: AppColors.lightMilky,
  textTheme: _baseText.apply(
    bodyColor: AppColors.onLight,
    displayColor: AppColors.onLight,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightSurface,
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    hintStyle: const TextStyle(color: AppColors.grey),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.lightSurface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.grey,
    showUnselectedLabels: true,
  ),
  drawerTheme: const DrawerThemeData(backgroundColor: AppColors.lightSurface),
  cardTheme: CardTheme(
    color: AppColors.lightSurface,
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

/// DARK THEME
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.grey,
    background: AppColors.darkBg,
    surface: AppColors.darkSurface,
    onPrimary: Colors.white,
    onSecondary: AppColors.onDark,
    onBackground: AppColors.onDark,
    onSurface: AppColors.onDark,
  ),
  scaffoldBackgroundColor: AppColors.darkBg,
  textTheme: _baseText.apply(
    bodyColor: AppColors.onDark,
    displayColor: AppColors.onDark,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkBg,
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkSurface,
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    hintStyle: const TextStyle(color: AppColors.grey),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.grey,
    showUnselectedLabels: true,
  ),
  drawerTheme: const DrawerThemeData(backgroundColor: AppColors.darkSurface),
  cardTheme: CardTheme(
    color: AppColors.darkSurface,
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

/// OPTIONAL: Keep using old names in your widgets if you like:
extension LegacyTextNames on TextTheme {
  TextStyle? get headline6 => titleLarge; // ~20
  TextStyle? get subtitle1 => titleMedium; // ~16
  TextStyle? get bodyText2 => bodyMedium; // ~14
  TextStyle? get caption => bodySmall; // ~12
  // TextStyle? get subCaption => bodyXtraSmall; // ~10
}
