import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/budget_savings_debt_providers.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/summary_widgets.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  DateTime _viewMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().loadBudgets(
          _viewMonth.month, _viewMonth.year);
    });
  }

  void _showBudgetDialog({String? catId, String? catName, String? emoji,
      double? existing, required bool isOverall}) {
    final ctrl = TextEditingController(
        text: existing != null ? existing.toStringAsFixed(0) : '');
    final currency = context.read<SettingsProvider>().currency;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isOverall ? 'Set Monthly Budget' : 'Budget for ${emoji ?? ''} $catName'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '$currency ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () async {
                final amount = double.tryParse(ctrl.text.trim());
                if (amount == null || amount <= 0) return;
                final budgetProvider = context.read<BudgetProvider>();
                if (isOverall) {
                  await budgetProvider.setOverallBudget(
                      amount, _viewMonth.month, _viewMonth.year);
                } else {
                  await budgetProvider.setCategoryBudget(
                      catId!, amount, _viewMonth.month, _viewMonth.year);
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budProvider = context.watch<BudgetProvider>();
    final txnProvider = context.watch<TransactionProvider>();
    final catProvider = context.watch<CategoryProvider>();
    final currency = context.watch<SettingsProvider>().currency;
    final cs = Theme.of(context).colorScheme;

    final txns = txnProvider.all.where((t) {
      return t.date.startsWith(
          '${_viewMonth.year}-${_viewMonth.month.toString().padLeft(2, '0')}');
    }).toList();
    final totalExpense = txnProvider.totalExpense(txns);
    final catBreakdown = txnProvider.categoryBreakdown(txns, 'expense');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showBudgetDialog(
                isOverall: true,
                existing: budProvider.overallBudget?.amount),
            tooltip: 'Set Monthly Budget',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Month navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() => _viewMonth =
                        DateTime(_viewMonth.year, _viewMonth.month - 1));
                    budProvider.loadBudgets(
                        _viewMonth.month, _viewMonth.year);
                  },
                ),
                Text(DateFormat('MMMM yyyy').format(_viewMonth),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final next =
                        DateTime(_viewMonth.year, _viewMonth.month + 1);
                    if (!next.isAfter(DateTime.now())) {
                      setState(() => _viewMonth = next);
                      budProvider.loadBudgets(next.month, next.year);
                    }
                  },
                ),
              ],
            ),
          ),
          // Overall budget
          if (budProvider.overallBudget != null)
            BudgetProgressCard(
              title: 'Monthly Overall',
              emoji: '💰',
              spent: totalExpense,
              budget: budProvider.overallBudget!.amount,
              currency: currency,
              color: cs.primary,
            )
          else
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Set Monthly Budget'),
                subtitle: const Text('Tap to define your overall budget'),
                onTap: () => _showBudgetDialog(isOverall: true),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Category Budgets',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _showAddCategoryBudget(catProvider, budProvider),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          // Category-wise budgets
          if (budProvider.categoryBudgets.isEmpty &&
              catBreakdown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.pie_chart_outline,
                        size: 56, color: cs.outlineVariant),
                    const SizedBox(height: 12),
                    Text('No category budgets set',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          // Show budgeted categories
          ...budProvider.categoryBudgets.map((b) {
            final cat = catProvider.findById(b.categoryId!);
            final spent = catBreakdown[b.categoryId] ?? 0;
            return BudgetProgressCard(
              title: cat?.name ?? 'Unknown',
              emoji: cat?.emoji ?? '?',
              spent: spent,
              budget: b.amount,
              currency: currency,
              color: cat != null ? Color(cat.color) : cs.primary,
            );
          }),
          // Show unbudgeted spending categories
          const SizedBox(height: 8),
          ...catBreakdown.entries.where((e) =>
              !budProvider.categoryBudgets.any((b) => b.categoryId == e.key))
              .map((e) {
            final cat = catProvider.findById(e.key);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Text(cat?.emoji ?? '?',
                    style: const TextStyle(fontSize: 24)),
                title: Text(cat?.name ?? 'Unknown'),
                subtitle: Text('Spent: $currency${e.value.toStringAsFixed(0)} — No budget set'),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showBudgetDialog(
                    catId: e.key,
                    catName: cat?.name,
                    emoji: cat?.emoji,
                    isOverall: false,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAddCategoryBudget(
      CategoryProvider catProvider, BudgetProvider budProvider) {
    final currency = context.read<SettingsProvider>().currency;
    String? selectedId;
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Category Budget',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (ctx2, setSt) => Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedId,
                      decoration: const InputDecoration(
                          labelText: 'Category'),
                      items: catProvider.expenseCategories
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Row(children: [
                                  Text(c.emoji),
                                  const SizedBox(width: 8),
                                  Text(c.name),
                                ]),
                              ))
                          .toList(),
                      onChanged: (v) => setSt(() => selectedId = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Budget Amount',
                        prefixText: '$currency ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        if (selectedId == null) return;
                        final amt = double.tryParse(ctrl.text);
                        if (amt == null || amt <= 0) return;
                        await budProvider.setCategoryBudget(
                            selectedId!, amt, _viewMonth.month, _viewMonth.year);
                        if (mounted) Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      child: const Text('Save Budget'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
