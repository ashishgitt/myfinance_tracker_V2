import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // Defaults
  String _currency = '₹';
  String _theme = 'Light'; // Light | Dark | AMOLED Black
  String _weekStart = 'Monday';
  int _monthStartDay = 1;
  bool _appLockEnabled = false;
  bool _dailyReminder = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _onboardingDone = false;

  // ─── Getters ─────────────────────────────────────────────────
  String get currency => _currency;
  String get theme => _theme;
  String get weekStart => _weekStart;
  int get monthStartDay => _monthStartDay;
  bool get appLockEnabled => _appLockEnabled;
  bool get dailyReminder => _dailyReminder;
  TimeOfDay get reminderTime => _reminderTime;
  bool get onboardingDone => _onboardingDone;

  ThemeMode get themeMode {
    switch (_theme) {
      case 'Dark':
        return ThemeMode.dark;
      case 'AMOLED Black':
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }

  // ─── Load ─────────────────────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString('currency') ?? '₹';
    _theme = prefs.getString('theme') ?? 'Light';
    _weekStart = prefs.getString('week_start') ?? 'Monday';
    _monthStartDay = prefs.getInt('month_start_day') ?? 1;
    _appLockEnabled = prefs.getBool('app_lock') ?? false;
    _dailyReminder = prefs.getBool('daily_reminder') ?? true;
    _onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final h = prefs.getInt('reminder_hour') ?? 20;
    final m = prefs.getInt('reminder_minute') ?? 0;
    _reminderTime = TimeOfDay(hour: h, minute: m);
    notifyListeners();
  }

  Future<void> setCurrency(String val) async {
    _currency = val;
    final p = await SharedPreferences.getInstance();
    await p.setString('currency', val);
    notifyListeners();
  }

  Future<void> setTheme(String val) async {
    _theme = val;
    final p = await SharedPreferences.getInstance();
    await p.setString('theme', val);
    notifyListeners();
  }

  Future<void> setWeekStart(String val) async {
    _weekStart = val;
    final p = await SharedPreferences.getInstance();
    await p.setString('week_start', val);
    notifyListeners();
  }

  Future<void> setMonthStartDay(int val) async {
    _monthStartDay = val;
    final p = await SharedPreferences.getInstance();
    await p.setInt('month_start_day', val);
    notifyListeners();
  }

  Future<void> setAppLock(bool val) async {
    _appLockEnabled = val;
    final p = await SharedPreferences.getInstance();
    await p.setBool('app_lock', val);
    notifyListeners();
  }

  Future<void> setDailyReminder(bool val) async {
    _dailyReminder = val;
    final p = await SharedPreferences.getInstance();
    await p.setBool('daily_reminder', val);
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay t) async {
    _reminderTime = t;
    final p = await SharedPreferences.getInstance();
    await p.setInt('reminder_hour', t.hour);
    await p.setInt('reminder_minute', t.minute);
    notifyListeners();
  }

  Future<void> setOnboardingDone() async {
    _onboardingDone = true;
    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarding_done', true);
    notifyListeners();
  }

  Future<void> setInitialBudget(double budget) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('initial_budget', budget);
  }

  Future<double?> getInitialBudget() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble('initial_budget');
  }
}
