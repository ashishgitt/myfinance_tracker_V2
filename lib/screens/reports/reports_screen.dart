import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/transaction_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _viewMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txnProvider = context.watch<TransactionProvider>();
    final catProvider = context.watch<CategoryProvider>();
    final currency = context.watch<SettingsProvider>().currency;

    final txns = txnProvider.all.where((t) =>
        t.date.startsWith(
            '${_viewMonth.year}-${_viewMonth.month.toString().padLeft(2, '0')}')).toList();

    final income = txnProvider.totalIncome(txns);
    final expense = txnProvider.totalExpense(txns);
    final catBreakdown = txnProvider.categoryBreakdown(txns, 'expense');
    final dailyBreakdown = txnProvider.dailyBreakdown(txns, 'expense');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
            Tab(text: 'Daily'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Month navigation
          _MonthPicker(
            month: _viewMonth,
            onPrev: () => setState(
                () => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1)),
            onNext: () {
              final next = DateTime(_viewMonth.year, _viewMonth.month + 1);
              if (!next.isAfter(DateTime.now()))
                setState(() => _viewMonth = next);
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Overview
                _OverviewTab(
                    txns: txns,
                    income: income,
                    expense: expense,
                    currency: currency,
                    viewMonth: _viewMonth,
                    txnProvider: txnProvider),
                // Tab 2: Categories Pie
                _CategoriesTab(
                    catBreakdown: catBreakdown,
                    catProvider: catProvider,
                    total: expense,
                    currency: currency),
                // Tab 3: Daily Line Chart
                _DailyTab(
                    dailyBreakdown: dailyBreakdown,
                    currency: currency,
                    viewMonth: _viewMonth),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Month Picker ─────────────────────────────────────────────────────────────
class _MonthPicker extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev, onNext;
  const _MonthPicker(
      {required this.month, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          Text(DateFormat('MMMM yyyy').format(month),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final List<TransactionModel> txns;
  final double income, expense;
  final String currency;
  final DateTime viewMonth;
  final TransactionProvider txnProvider;

  const _OverviewTab({
    required this.txns,
    required this.income,
    required this.expense,
    required this.currency,
    required this.viewMonth,
    required this.txnProvider,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avgDaily = txns.isEmpty
        ? 0.0
        : expense / DateTime(viewMonth.year, viewMonth.month + 1, 0).day;

    // Last 6 months bar data
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - i));
    final monthlyData = months.reversed.map((m) {
      final mt = txnProvider.all.where((t) => t.date.startsWith(
          '${m.year}-${m.month.toString().padLeft(2, '0')}')).toList();
      return {
        'label': DateFormat('MMM').format(m),
        'income': txnProvider.totalIncome(mt),
        'expense': txnProvider.totalExpense(mt),
      };
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Income vs Expense summary
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.arrow_downward, color: Colors.green.shade700),
                      Text('Income',
                          style: TextStyle(color: Colors.green.shade700)),
                      Text('$currency${income.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green.shade700)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.red.shade700),
                      Text('Expense',
                          style: TextStyle(color: Colors.red.shade700)),
                      Text('$currency${expense.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.red.shade700)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statChip(context, 'Net Savings',
                    '$currency${(income - expense).toStringAsFixed(0)}',
                    (income - expense) >= 0 ? Colors.green : cs.error),
                _statChip(context, 'Avg Daily Spend',
                    '$currency${avgDaily.toStringAsFixed(0)}', cs.primary),
                _statChip(context, 'Transactions',
                    '${txns.length}', cs.secondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 6-month bar chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('6-Month Overview',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(BarChartData(
                    barGroups: monthlyData.asMap().entries.map((e) {
                      final idx = e.key;
                      final d = e.value;
                      return BarChartGroupData(x: idx, barRods: [
                        BarChartRodData(
                            toY: (d['income'] as double),
                            color: Colors.green.shade400,
                            width: 8,
                            borderRadius: BorderRadius.circular(4)),
                        BarChartRodData(
                            toY: (d['expense'] as double),
                            color: Colors.red.shade400,
                            width: 8,
                            borderRadius: BorderRadius.circular(4)),
                      ], barsSpace: 2);
                    }).toList(),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) => Text(
                              monthlyData[v.toInt()]['label'] as String,
                              style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legend(Colors.green.shade400, 'Income'),
                    const SizedBox(width: 16),
                    _legend(Colors.red.shade400, 'Expense'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statChip(BuildContext ctx, String label, String val, Color c) =>
      Column(children: [
        Text(val,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: c, fontSize: 16)),
        Text(label,
            style: Theme.of(ctx)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
      ]);

  Widget _legend(Color c, String label) => Row(children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]);
}

// ─── Categories Tab ───────────────────────────────────────────────────────────
class _CategoriesTab extends StatelessWidget {
  final Map<String, double> catBreakdown;
  final catProvider;
  final double total;
  final String currency;
  const _CategoriesTab(
      {required this.catBreakdown,
      required this.catProvider,
      required this.total,
      required this.currency});

  @override
  Widget build(BuildContext context) {
    if (catBreakdown.isEmpty) {
      return const Center(child: Text('No expense data this month'));
    }
    final sorted = catBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Expense Breakdown',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(PieChartData(
                    sections: sorted.take(8).map((e) {
                      final cat = catProvider.findById(e.key);
                      return PieChartSectionData(
                        value: e.value,
                        color: cat != null ? Color(cat.color) : Colors.grey,
                        title: total > 0
                            ? '${(e.value / total * 100).toStringAsFixed(0)}%'
                            : '',
                        titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        radius: 80,
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 0,
                  )),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...sorted.map((e) {
          final cat = catProvider.findById(e.key);
          final pct = total > 0 ? e.value / total * 100 : 0.0;
          final catColor = cat != null ? Color(cat.color) : Colors.grey;
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(cat?.emoji ?? '?',
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(cat?.name ?? 'Unknown',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text('$currency${e.value.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            minHeight: 6,
                            backgroundColor:
                                catColor.withOpacity(0.15),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(catColor),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${pct.toStringAsFixed(1)}% of total',
                            style:
                                Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Daily Tab ────────────────────────────────────────────────────────────────
class _DailyTab extends StatelessWidget {
  final Map<String, double> dailyBreakdown;
  final String currency;
  final DateTime viewMonth;
  const _DailyTab(
      {required this.dailyBreakdown,
      required this.currency,
      required this.viewMonth});

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(viewMonth.year, viewMonth.month + 1, 0).day;
    final spots = <FlSpot>[];
    double maxVal = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final key =
          '${viewMonth.year}-${viewMonth.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      final val = dailyBreakdown[key] ?? 0;
      if (val > maxVal) maxVal = val;
      spots.add(FlSpot(d.toDouble(), val));
    }

    if (spots.every((s) => s.y == 0)) {
      return const Center(child: Text('No daily expense data'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Spending',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: LineChart(LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                        ),
                      ),
                    ],
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                      getDrawingHorizontalLine: (v) => FlLine(
                          color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (v, _) => Text(
                              v >= 1000
                                  ? '${(v / 1000).toStringAsFixed(0)}K'
                                  : v.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 10)),
                        ),
                      ),
                      topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 5,
                          getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: const TextStyle(fontSize: 10)),
                        ),
                      ),
                    ),
                    minX: 1,
                    maxX: daysInMonth.toDouble(),
                    minY: 0,
                  )),
                ),
              ],
            ),
          ),
        ),
        // Top spending days
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Top Spending Days',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...(dailyBreakdown.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value)))
                    .take(5)
                    .map((e) {
                  DateTime? d;
                  try { d = DateTime.parse(e.key); } catch (_) {}
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                        child: Text(d?.day.toString() ?? '?')),
                    title: Text(d != null
                        ? DateFormat('EEE, dd MMM').format(d)
                        : e.key),
                    trailing: Text('$currency${e.value.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
