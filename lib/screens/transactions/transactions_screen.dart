import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/transaction_model.dart';
import '../../widgets/transaction_card.dart';
import '../transactions/add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _typeFilter = '';
  String _catFilter = '';
  String _modeFilter = '';

  void _openFilterSheet() async {
    final catProvider = context.read<CategoryProvider>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _FilterSheet(
        initialType: _typeFilter,
        initialCat: _catFilter,
        initialMode: _modeFilter,
        onApply: (type, cat, mode) {
          setState(() {
            _typeFilter = type;
            _catFilter = cat;
            _modeFilter = mode;
          });
          context.read<TransactionProvider>().applyFilter(
                type: type,
                categoryId: cat,
                paymentMode: mode,
              );
        },
        onClear: () {
          setState(() {
            _typeFilter = '';
            _catFilter = '';
            _modeFilter = '';
          });
          context.read<TransactionProvider>().clearFilter();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txnProvider = context.watch<TransactionProvider>();
    final catProvider = context.watch<CategoryProvider>();
    final currency = context.watch<SettingsProvider>().currency;
    final cs = Theme.of(context).colorScheme;
    final hasFilter = _typeFilter.isNotEmpty || _catFilter.isNotEmpty || _modeFilter.isNotEmpty;

    // Group by date
    final Map<String, List<TransactionModel>> grouped = {};
    for (final t in txnProvider.filtered) {
      grouped.putIfAbsent(t.date, () => []).add(t);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: hasFilter,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: txnProvider.filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 16),
                  Text(hasFilter
                      ? 'No transactions match the filter'
                      : 'No transactions yet'),
                  if (hasFilter)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _typeFilter = '';
                          _catFilter = '';
                          _modeFilter = '';
                        });
                        txnProvider.clearFilter();
                      },
                      child: const Text('Clear Filter'),
                    ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: sortedDates.length,
              itemBuilder: (ctx, i) {
                final date = sortedDates[i];
                final dayTxns = grouped[date]!;
                final dayTotal = dayTxns.fold(
                    0.0,
                    (s, t) =>
                        s + (t.type == 'expense' ? -t.amount : t.amount));
                DateTime? parsed;
                try { parsed = DateTime.parse(date); } catch (_) {}
                final dateLabel = parsed != null
                    ? DateFormat('EEE, dd MMM yyyy').format(parsed)
                    : date;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dateLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w600)),
                          Text(
                            '${dayTotal >= 0 ? '+' : ''}$currency${dayTotal.toStringAsFixed(0)}',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                    color: dayTotal >= 0
                                        ? Colors.green
                                        : cs.error,
                                    fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    ...dayTxns.map((t) => TransactionCard(
                          transaction: t,
                          category: catProvider.findById(t.categoryId),
                          currency: currency,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      AddTransactionScreen(existing: t))),
                          onDelete: () async {
                            await txnProvider.deleteTransaction(t.id);
                          },
                        )),
                  ],
                );
              },
            ),
    );
  }
}

// ─── Filter Sheet ─────────────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final String initialType, initialCat, initialMode;
  final void Function(String, String, String) onApply;
  final VoidCallback onClear;
  const _FilterSheet(
      {required this.initialType,
      required this.initialCat,
      required this.initialMode,
      required this.onApply,
      required this.onClear});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _type, _cat, _mode;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _cat = widget.initialCat;
    _mode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      builder: (_, sc) => ListView(
        controller: sc,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Filter Transactions',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text('Type', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final t in ['', 'expense', 'income'])
                ChoiceChip(
                  label: Text(t.isEmpty ? 'All' : t.capitalize()),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Payment Mode', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final m in ['', 'Cash', 'UPI', 'Card', 'Bank Transfer', 'Other'])
                ChoiceChip(
                  label: Text(m.isEmpty ? 'All' : m),
                  selected: _mode == m,
                  onSelected: (_) => setState(() => _mode = m),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onClear();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(_type, _cat, _mode);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension _StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
