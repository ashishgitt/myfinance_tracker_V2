import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main/main_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isAmoled = settings.theme == 'AMOLED Black';
        return MaterialApp(
          title: 'MyFinance Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme:
              isAmoled ? AppTheme.amoled() : AppTheme.dark(),
          themeMode: settings.themeMode,
          home: settings.onboardingDone
              ? const MainScreen()
              : const OnboardingScreen(),
        );
      },
    );
  }
}
