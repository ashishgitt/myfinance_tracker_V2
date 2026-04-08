import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_savings_debt_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/credit_card_provider.dart';
import '../../core/services/notification_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../transactions/transactions_screen.dart';
import '../reports/reports_screen.dart';
import '../budget/budget_screen.dart';
import '../more/more_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../app_lock/app_lock_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isLocked = false;
  bool _initialized = false;
  // Fix 2: Track app lifecycle to debounce lock triggers
  AppLifecycleState? _lastState;
  DateTime? _backgroundedAt;

  static const _pages = [
    DashboardScreen(),
    TransactionsScreen(),
    ReportsScreen(),
    BudgetScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Fix 2: Only lock when app truly went to background (not during auth prompt)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = context.read<SettingsProvider>();
    if (!settings.appLockEnabled || !_initialized) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
      _lastState = state;
    }

    if (state == AppLifecycleState.resumed) {
      // Only lock if we were truly backgrounded for > 3 seconds
      // (prevents locking during biometric prompt itself)
      if (_lastState == AppLifecycleState.paused &&
          _backgroundedAt != null &&
          DateTime.now().difference(_backgroundedAt!).inSeconds > 3) {
        if (!_isLocked) {
          setState(() => _isLocked = true);
        }
      }
      _lastState = state;
    }
  }

  Future<void> _init() async {
    final settings = context.read<SettingsProvider>();
    await context.read<CategoryProvider>().loadCategories();
    await context.read<TransactionProvider>().loadAll();
    final now = DateTime.now();
    await context.read<BudgetProvider>().loadBudgets(now.month, now.year);
    await context.read<SavingsProvider>().loadGoals();
    await context.read<DebtProvider>().loadAll();
    await context.read<CreditCardProvider>().loadCards();

    if (settings.dailyReminder) {
      await NotificationService.scheduleDailyReminder(
        settings.reminderTime.hour,
        settings.reminderTime.minute,
      );
    }

    if (!mounted) return;
    _initialized = true;

    // Show lock on cold start
    if (settings.appLockEnabled) {
      setState(() => _isLocked = true);
    }
  }

  void _onUnlocked() {
    setState(() => _isLocked = false);
    _backgroundedAt = null;
    _lastState = AppLifecycleState.resumed;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return AppLockScreen(onAuthenticated: _onUnlocked);
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      // Fix 1: Use endFloat so FAB never overlaps nav bar labels
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        heroTag: 'main_fab',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
