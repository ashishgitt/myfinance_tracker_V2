import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

// Fix 1: NavigationBar label font size prevents "Transactions" wrapping
NavigationBarThemeData _navBarTheme() =>
    NavigationBarThemeData(
      labelBehavior:
          NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w500),
      ),
      height: 62,
    );

class AppTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primarySeed,
          brightness: Brightness.light,
        ),
        navigationBarTheme: _navBarTheme(),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primarySeed,
          brightness: Brightness.dark,
        ),
        navigationBarTheme: _navBarTheme(),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      );

  static ThemeData amoled() {
    final base = dark();
    return base.copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme:
          base.colorScheme.copyWith(surface: Colors.black),
      navigationBarTheme: _navBarTheme().copyWith(
        backgroundColor: Colors.black,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF0A0A0A),
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
