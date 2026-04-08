import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/login/login_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, AuthProvider>(
      builder: (context, settings, auth, _) {
        final isAmoled = settings.theme == 'AMOLED Black';
        return MaterialApp(
          title: 'MyFinance Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: isAmoled ? AppTheme.amoled() : AppTheme.dark(),
          themeMode: settings.themeMode,
          home: _resolveHome(settings, auth),
        );
      },
    );
  }

  Widget _resolveHome(SettingsProvider settings, AuthProvider auth) {
    // 1. Onboarding first
    if (!settings.onboardingDone) return const OnboardingScreen();
    // 2. Login screen if not skipped and not signed in
    if (auth.showLoginScreen) return const LoginScreen();
    // 3. Main app
    return const MainScreen();
  }
}
