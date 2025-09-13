import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Radii
  static const double radiusLarge = 20;
  static const double radiusMedium = 14;

  // Shadows
  static const List<BoxShadow> vibrantShadow = [
    BoxShadow(color: Color(0xFF6A5AE0), blurRadius: 16, offset: Offset(0, 6)),
    BoxShadow(color: Color(0xFF00C9A7), blurRadius: 24, offset: Offset(0, 10)),
  ];

  // Colors - Light Palette
  static const Color lightPrimary = Color(0xFF6A5AE0); // Purple
  static const Color lightSecondary = Color(0xFF00C9A7); // Teal
  static const Color lightAccent = Color(0xFFFF6584); // Coral Pink
  static const Color lightBackground = Color(0xFFF2F4F9);
  static final Color lightCard = Colors.white.withOpacity(0.95);

  // Colors - Dark Palette
  static const Color darkPrimary = Color(0xFF9C8CFF);
  static const Color darkSecondary = Color(0xFF34EBC3);
  static const Color darkAccent = Color(0xFFFF8FA2);
  static const Color darkBackground = Color(0xFF0C0E16);
  static final Color darkCard = Colors.white.withOpacity(0.07);

  // Typography
  static TextTheme textTheme(Brightness brightness) {
    final base = GoogleFonts.urbanistTextTheme();
    return base.apply(
      bodyColor: brightness == Brightness.light ? Colors.black87 : Colors.white,
      displayColor: brightness == Brightness.light ? Colors.black : Colors.white,
    );
  }

  static final TextStyle buttonTextStyle = GoogleFonts.urbanist(
    fontWeight: FontWeight.w700,
    fontSize: 16,
    letterSpacing: 0.5,
  );

  static TextStyle appBarTitleStyle(Brightness brightness) =>
      GoogleFonts.urbanist(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: brightness == Brightness.light ? Colors.black87 : Colors.white,
      );

  static InputDecorationTheme inputDecorationTheme(Color primary) {
    return InputDecorationTheme(
      filled: true,
      fillColor: primary.withOpacity(0.07),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: primary, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ===== Light Theme =====
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      secondary: lightSecondary,
      tertiary: lightAccent,
      background: lightBackground,
      surface: Colors.white,
      onSurface: Colors.black87,
    ),
    scaffoldBackgroundColor: lightBackground,
    textTheme: textTheme(Brightness.light),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 4,
      shadowColor: lightPrimary.withOpacity(0.2),
      iconTheme: const IconThemeData(color: lightPrimary),
      titleTextStyle: appBarTitleStyle(Brightness.light),
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 6,
      shadowColor: lightPrimary.withOpacity(0.25),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium)),
        textStyle: buttonTextStyle.copyWith(color: Colors.white),
        foregroundColor: Colors.white,
        backgroundColor: lightPrimary,
      ).copyWith(
        backgroundColor: MaterialStateProperty.resolveWith(
              (states) => states.contains(MaterialState.pressed)
              ? lightSecondary
              : lightPrimary,
        ),
      ),
    ),
    inputDecorationTheme: inputDecorationTheme(lightPrimary),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  // ===== Dark Theme =====
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      tertiary: darkAccent,
      background: darkBackground,
      surface: Color(0xFF1A1B21),
      onSurface: Colors.white70,
    ),
    scaffoldBackgroundColor: darkBackground,
    textTheme: textTheme(Brightness.dark),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black.withOpacity(0.85),
      elevation: 4,
      shadowColor: darkPrimary.withOpacity(0.3),
      iconTheme: const IconThemeData(color: darkPrimary),
      titleTextStyle: appBarTitleStyle(Brightness.dark),
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 6,
      shadowColor: darkPrimary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium)),
        textStyle: buttonTextStyle.copyWith(color: Colors.white),
        foregroundColor: Colors.white,
        backgroundColor: darkPrimary,
      ).copyWith(
        backgroundColor: MaterialStateProperty.resolveWith(
              (states) => states.contains(MaterialState.pressed)
              ? darkSecondary
              : darkPrimary,
        ),
      ),
    ),
    inputDecorationTheme: inputDecorationTheme(darkPrimary),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
