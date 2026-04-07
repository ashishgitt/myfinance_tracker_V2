import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/transaction_model.dart';
import '../../widgets/transaction_card.dart';
import '../transactions/add_transaction_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  List<TransactionModel> _results = [];
  bool _searched = false;
  bool _loading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    setState(() => _loading = true);
    final results =
        await context.read<TransactionProvider>().search(query.trim());
    if (!mounted) return;
    setState(() {
      _results = results;
      _searched = true;
      _loading = false;
    });
  }

  // Feature Fix 10: Overview panel for search results
  Widget _buildOverviewPanel(
      List<TransactionModel> results, String currency, ColorScheme cs) {
    if (results.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    // Week: Monday to today
    final weekStart =
        now.subtract(Duration(days: now.weekday - 1));
    final weekStartStr =
        '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    final monthPrefix =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final weekTotal = results
        .where((t) =>
            t.type == 'expense' &&
            t.date.compareTo(weekStartStr) >= 0)
        .fold(0.0, (s, t) => s + t.amount);

    final monthTotal = results
        .where((t) =>
            t.type == 'expense' &&
            t.date.startsWith(monthPrefix))
        .fold(0.0, (s, t) => s + t.amount);

    final totalIncome = results
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      color: cs.primaryContainer.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search Overview',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
              children: [
                _overviewStat(context, 'This Week',
                    '$currency${weekTotal.toStringAsFixed(0)}',
                    cs.primary),
                _overviewStat(context, 'This Month',
                    '$currency${monthTotal.toStringAsFixed(0)}',
                    cs.error),
                _overviewStat(context, 'Count',
                    '${results.length}', cs.secondary),
              ],
            ),
            if (totalIncome > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _overviewStat(context, 'Total Income',
                    '+$currency${totalIncome.toStringAsFixed(0)}',
                    Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  Widget _overviewStat(BuildContext ctx, String label,
      String val, Color c) =>
      Column(children: [
        Text(val,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: c,
                fontSize: 15)),
        Text(label,
            style: Theme.of(ctx)
                .textTheme
                .bodySmall
                ?.copyWith(
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurfaceVariant)),
      ]);

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    final currency =
        context.watch<SettingsProvider>().currency;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText:
                'Search by note, amount, category, label...',
            border: InputBorder.none,
            filled: false,
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      _search('');
                    },
                  )
                : null,
          ),
          onChanged: _search,
          onSubmitted: _search,
        ),
      ),
      body: !_searched
          ? Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(Icons.search,
                      size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 12),
                  Text('Search your transactions',
                      style: TextStyle(
                          color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text(
                      'Note, amount, category or label',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: cs.outlineVariant)),
                ],
              ),
            )
          : _loading
              ? const Center(
                  child: CircularProgressIndicator())
              : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64,
                              color: cs.outlineVariant),
                          const SizedBox(height: 12),
                          Text(
                              'No results for "${_searchCtrl.text}"',
                              style: TextStyle(
                                  color:
                                      cs.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : Column(children: [
                      // Fix 10: Overview panel
                      _buildOverviewPanel(
                          _results, currency, cs),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            16, 4, 16, 4),
                        child: Row(children: [
                          Text(
                              '${_results.length} result${_results.length != 1 ? 's' : ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color:
                                          cs.onSurfaceVariant)),
                        ]),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                              bottom: 16),
                          itemCount: _results.length,
                          itemBuilder: (ctx, i) {
                            final t = _results[i];
                            return TransactionCard(
                              transaction: t,
                              category: catProvider
                                  .findById(t.categoryId),
                              currency: currency,
                              onTap: () =>
                                  Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              AddTransactionScreen(
                                                  existing: t))),
                            );
                          },
                        ),
                      ),
                    ]),
    );
  }
}
