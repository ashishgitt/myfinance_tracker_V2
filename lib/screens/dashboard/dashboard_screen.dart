import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_savings_debt_providers.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/transaction_card.dart';
import '../../widgets/summary_widgets.dart';
import '../transactions/add_transaction_screen.dart';
import '../search/search_screen.dart';
import '../debts/debts_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txnP = context.watch<TransactionProvider>();
    final catP = context.watch<CategoryProvider>();
    final budP = context.watch<BudgetProvider>();
    final debtP = context.watch<DebtProvider>();
    final settings = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;
    final currency = settings.currency;
    final now = DateTime.now();

    final monthIncome = txnP.thisMonthIncome();
    final monthExpense = txnP.thisMonthExpense();
    final balance = monthIncome - monthExpense;
    final todayExp = txnP.todayExpense();
    final overall = budP.overallBudget;

    final prefix =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final txnsThisMonth =
        txnP.all.where((t) => t.date.startsWith(prefix)).toList();
    final catBreakdown =
        txnP.categoryBreakdown(txnsThisMonth, 'expense');
    final totalCatExp =
        catBreakdown.values.fold(0.0, (a, b) => a + b);

    // Debt summary (Feature 3)
    final totalOwe = debtP.iOwe.fold(0.0, (s, d) => s + d.amount);
    final totalOwed =
        debtP.owedToMe.fold(0.0, (s, d) => s + d.amount);
    final netDebt = totalOwed - totalOwe;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MyFinance Tracker',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(DateFormat('MMMM yyyy').format(now),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: txnP.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await txnP.loadAll();
                await budP.loadBudgets(now.month, now.year);
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  // Balance hero
                  _BalanceHeroCard(
                      currency: currency,
                      income: monthIncome,
                      expense: monthExpense,
                      balance: balance),
                  const SizedBox(height: 8),

                  // Today + budget summary
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Expanded(
                        child: SummaryCard(
                          label: "Today's Spending",
                          amount:
                              '$currency${todayExp.toStringAsFixed(0)}',
                          icon: Icons.today,
                          color: cs.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SummaryCard(
                          label: 'Monthly Budget',
                          amount: overall != null
                              ? '$currency${overall.amount.toStringAsFixed(0)}'
                              : 'Not Set',
                          icon: Icons.savings,
                          color: cs.primary,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),

                  // Monthly progress bar
                  if (overall != null)
                    _MonthlyProgressCard(
                        currency: currency,
                        spent: monthExpense,
                        budget: overall.amount,
                        cs: cs),
                  const SizedBox(height: 8),

                  // Feature 3: Debt Summary Card
                  if (totalOwe > 0 || totalOwed > 0)
                    _DebtSummaryCard(
                      currency: currency,
                      totalOwe: totalOwe,
                      totalOwed: totalOwed,
                      netDebt: netDebt,
                      cs: cs,
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const DebtsScreen())),
                    ),
                  const SizedBox(height: 8),

                  // Pie chart
                  if (catBreakdown.isNotEmpty && totalCatExp > 0)
                    _CategoryPieChart(
                        catBreakdown: catBreakdown,
                        catProvider: catP,
                        total: totalCatExp,
                        currency: currency),
                  const SizedBox(height: 8),

                  // Recent transactions
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Transactions',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.bold)),
                        TextButton(
                            onPressed: () {},
                            child: const Text('See All')),
                      ],
                    ),
                  ),
                  if (txnP.recentTransactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 56,
                              color: cs.outlineVariant),
                          const SizedBox(height: 12),
                          Text('No transactions yet',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          FilledButton.tonal(
                            onPressed: () => Navigator.of(context)
                                .push(MaterialPageRoute(
                                    builder: (_) =>
                                        const AddTransactionScreen())),
                            child: const Text(
                                'Add First Transaction'),
                          ),
                        ]),
                      ),
                    )
                  else
                    ...txnP.recentTransactions.map((t) =>
                        TransactionCard(
                          transaction: t,
                          category: catP.findById(t.categoryId),
                          currency: currency,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      AddTransactionScreen(
                                          existing: t))),
                        )),
                ],
              ),
            ),
    );
  }
}

// ─── Balance Hero ─────────────────────────────────────────────────────────────
class _BalanceHeroCard extends StatelessWidget {
  final String currency;
  final double income, expense, balance;
  const _BalanceHeroCard(
      {required this.currency,
      required this.income,
      required this.expense,
      required this.balance});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        Text('Net Balance',
            style:
                TextStyle(color: cs.onPrimary.withOpacity(0.8))),
        const SizedBox(height: 6),
        Text(
          '${balance < 0 ? '-' : ''}$currency${balance.abs().toStringAsFixed(2)}',
          style: TextStyle(
              color: cs.onPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: _stat(context, Icons.arrow_downward_rounded,
                  'Income',
                  '$currency${income.toStringAsFixed(0)}',
                  Colors.greenAccent)),
          Container(
              width: 1,
              height: 40,
              color: cs.onPrimary.withOpacity(0.3)),
          Expanded(
              child: _stat(context, Icons.arrow_upward_rounded,
                  'Expense',
                  '$currency${expense.toStringAsFixed(0)}',
                  Colors.redAccent.shade100)),
        ]),
      ]),
    );
  }

  Widget _stat(BuildContext ctx, IconData icon, String label,
      String val, Color c) {
    final cs = Theme.of(ctx).colorScheme;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: c, size: 16),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(color: cs.onPrimary.withOpacity(0.8))),
      ]),
      const SizedBox(height: 4),
      Text(val,
          style: TextStyle(
              color: cs.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16)),
    ]);
  }
}

// ─── Monthly Progress ─────────────────────────────────────────────────────────
class _MonthlyProgressCard extends StatelessWidget {
  final String currency;
  final double spent, budget;
  final ColorScheme cs;
  const _MonthlyProgressCard(
      {required this.currency,
      required this.spent,
      required this.budget,
      required this.cs});

  @override
  Widget build(BuildContext context) {
    final pct = (spent / budget).clamp(0.0, 1.0);
    final overBudget = spent > budget;
    final color = overBudget
        ? cs.error
        : pct >= 0.8
            ? Colors.orange
            : cs.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Monthly Budget',
                        style:
                            Theme.of(context).textTheme.titleSmall),
                    Text(
                        '${(spent / budget * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold)),
                  ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: cs.surfaceVariant,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(color)),
              ),
              const SizedBox(height: 8),
              Text(
                  '$currency${spent.toStringAsFixed(0)} of $currency${budget.toStringAsFixed(0)} spent',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Feature 3: Debt Summary Card ────────────────────────────────────────────
class _DebtSummaryCard extends StatelessWidget {
  final String currency;
  final double totalOwe, totalOwed, netDebt;
  final ColorScheme cs;
  final VoidCallback onTap;
  const _DebtSummaryCard({
    required this.currency,
    required this.totalOwe,
    required this.totalOwed,
    required this.netDebt,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Debt Overview',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                  fontWeight: FontWeight.bold)),
                      const Icon(Icons.chevron_right),
                    ]),
                const SizedBox(height: 12),
                Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      _debtStat(context, 'I Owe',
                          '$currency${totalOwe.toStringAsFixed(0)}',
                          cs.error),
                      _debtStat(
                          context,
                          'Owed to Me',
                          '$currency${totalOwed.toStringAsFixed(0)}',
                          Colors.green),
                      _debtStat(
                          context,
                          'Net Position',
                          '${netDebt >= 0 ? '+' : ''}$currency${netDebt.toStringAsFixed(0)}',
                          netDebt >= 0
                              ? Colors.green
                              : cs.error),
                    ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _debtStat(
      BuildContext ctx, String label, String val, Color c) =>
      Column(children: [
        Text(val,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: c, fontSize: 16)),
        Text(label,
            style: Theme.of(ctx)
                .textTheme
                .bodySmall
                ?.copyWith(
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurfaceVariant)),
      ]);
}

// ─── Category Pie Chart ───────────────────────────────────────────────────────
class _CategoryPieChart extends StatelessWidget {
  final Map<String, double> catBreakdown;
  final CategoryProvider catProvider;
  final double total;
  final String currency;
  const _CategoryPieChart(
      {required this.catBreakdown,
      required this.catProvider,
      required this.total,
      required this.currency});

  @override
  Widget build(BuildContext context) {
    final entries = catBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = entries.take(5).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spending by Category',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Row(children: [
                Expanded(
                  child: PieChart(PieChartData(
                    sections: top5.map((e) {
                      final cat =
                          catProvider.findById(e.key);
                      return PieChartSectionData(
                        value: e.value,
                        color: cat != null
                            ? Color(cat.color)
                            : Colors.grey,
                        title: '',
                        radius: 55,
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 35,
                  )),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: top5.map((e) {
                    final cat = catProvider.findById(e.key);
                    final pct = total > 0
                        ? (e.value / total * 100)
                            .toStringAsFixed(0)
                        : '0';
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: cat != null
                                    ? Color(cat.color)
                                    : Colors.grey,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(
                            '${cat?.emoji ?? ''} ${cat?.name ?? '?'}',
                            style:
                                const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text('$pct%',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ]),
                    );
                  }).toList(),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
