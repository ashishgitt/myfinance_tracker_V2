import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/constants/app_constants.dart';
import '../main/main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  String _selectedCurrency = '₹';
  final _budgetCtrl = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  void _done() async {
    final settings = context.read<SettingsProvider>();
    await settings.setCurrency(_selectedCurrency);
    if (_budgetCtrl.text.isNotEmpty) {
      final budget = double.tryParse(_budgetCtrl.text);
      if (budget != null) await settings.setInitialBudget(budget);
    }
    await settings.setOnboardingDone();
    await context.read<CategoryProvider>().loadCategories();
    await context.read<TransactionProvider>().loadAll();
    if (mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()));
    }
  }

  void _skip() async {
    final settings = context.read<SettingsProvider>();
    await settings.setOnboardingDone();
    await context.read<CategoryProvider>().loadCategories();
    await context.read<TransactionProvider>().loadAll();
    if (mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _page = i),
              children: [_page0(cs), _page1(cs), _page2(cs)],
            ),
            // Skip button
            Positioned(
              top: 8, right: 16,
              child: TextButton(onPressed: _skip, child: const Text('Skip')),
            ),
            // Dots + Continue
            Positioned(
              bottom: 24, left: 24, right: 24,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _page == i ? cs.primary : cs.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _page < 2 ? _next : _done,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52)),
                    child: Text(_page < 2 ? 'Continue' : 'Get Started'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page0(ColorScheme cs) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_balance_wallet_rounded,
                  size: 80, color: cs.primary),
            ),
            const SizedBox(height: 40),
            Text('MyFinance Tracker',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
            const SizedBox(height: 16),
            Text(
              'Take control of your money.\nTrack expenses, set budgets,\nand achieve your financial goals.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Chip(
              avatar: const Icon(Icons.lock_outline, size: 16),
              label: const Text('100% Offline • No Ads • Private'),
            ),
          ],
        ),
      );

  Widget _page1(ColorScheme cs) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 80, 32, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.tune_rounded, size: 48, color: cs.primary),
            const SizedBox(height: 24),
            Text('Set Your Preferences',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('You can change these anytime in Settings.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 32),
            // Currency picker
            Text('Default Currency',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.currencies.map((c) => ChoiceChip(
                    label: Text(c, style: const TextStyle(fontSize: 18)),
                    selected: _selectedCurrency == c,
                    onSelected: (_) => setState(() => _selectedCurrency = c),
                  )).toList(),
            ),
            const SizedBox(height: 28),
            // Monthly budget
            Text('Monthly Budget (optional)',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 50000',
                prefixText: '$_selectedCurrency ',
              ),
            ),
          ],
        ),
      );

  Widget _page2(ColorScheme cs) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 80, 32, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 48, color: cs.primary),
            const SizedBox(height: 24),
            Text("You're All Set!",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              "Start by adding your first transaction.\nEvery rupee tracked is a step toward\nfinancial freedom.",
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            ...[
              ('🏠', 'Dashboard', 'Overview of your finances'),
              ('📋', 'Transactions', 'All income & expenses'),
              ('📊', 'Reports', 'Charts & analytics'),
              ('💰', 'Budget', 'Set & track budgets'),
              ('⚙️', 'More', 'Goals, debts & settings'),
            ].map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(item.$1, style: const TextStyle(fontSize: 28)),
                  title: Text(item.$2,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(item.$3),
                )),
          ],
        ),
      );
}
