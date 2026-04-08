import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz_zone;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'core/services/notification_service.dart';
import 'providers/settings_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/category_provider.dart';
import 'providers/budget_savings_debt_providers.dart';
import 'providers/debt_provider.dart';
import 'providers/sub_category_provider.dart';
import 'providers/credit_card_provider.dart';
import 'providers/auth_provider.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Timezone init
  tz.initializeTimeZones();
  try {
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz_zone.setLocalLocation(tz_zone.getLocation(localTz));
  } catch (_) {
    tz_zone.setLocalLocation(tz_zone.getLocation('UTC'));
  }

  // Notifications
  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => SavingsProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => SubCategoryProvider()),
        ChangeNotifierProvider(create: (_) => CreditCardProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
