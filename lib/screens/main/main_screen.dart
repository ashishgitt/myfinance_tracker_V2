import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_savings_debt_providers.dart';
import '../../providers/settings_provider.dart';
import '../../core/services/notification_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../transactions/transactions_screen.dart';
import '../reports/reports_screen.dart';
import '../budget/budget_screen.dart';
import '../more/more_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../app_lock/app_lock_screen.dart';
import '../../providers/credit_card_provider.dart';

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

  // ─── Fix 2 & 3: App lifecycle → lock on background ───────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = context.read<SettingsProvider>();
    if (!settings.appLockEnabled) return;

    if (state == AppLifecycleState.resumed && !_isLocked) {
      // Only lock after first init (so cold-start lock works too)
      if (_initialized) setState(() => _isLocked = true);
    }
  }

  Future<void> _init() async {
    final settings = context.read<SettingsProvider>();
    final cat = context.read<CategoryProvider>();
    final txn = context.read<TransactionProvider>();
    final bud = context.read<BudgetProvider>();
    final sav = context.read<SavingsProvider>();
    final dbt = context.read<DebtProvider>();

    await cat.loadCategories();
    await txn.loadAll();
    final now = DateTime.now();
    await bud.loadBudgets(now.month, now.year);
    await sav.loadGoals();
    await dbt.loadDebts();
    await context.read<CreditCardProvider>().loadCards();

    // Schedule daily reminder if enabled
    if (settings.dailyReminder) {
      await NotificationService.scheduleDailyReminder(
        settings.reminderTime.hour,
        settings.reminderTime.minute,
      );
    }

    if (!mounted) return;

    // Show app lock on cold start
    if (settings.appLockEnabled) {
      setState(() => _isLocked = true);
    }
    _initialized = true;
  }

  void _onUnlocked() => setState(() => _isLocked = false);

  @override
  Widget build(BuildContext context) {
    // Fix 2&3: Overlay lock screen on top of everything
    if (_isLocked) {
      return AppLockScreen(onAuthenticated: _onUnlocked);
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const AddTransactionScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        heroTag: 'main_fab',
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) =>
            setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',         // Fix 1: shorter labels
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions', // Fix 1: font size set in theme
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
