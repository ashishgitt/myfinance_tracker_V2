import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../providers/budget_savings_debt_providers.dart';
import '../../providers/settings_provider.dart';
import '../../models/models.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});
  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debtProvider = context.watch<DebtProvider>();
    final currency = context.watch<SettingsProvider>().currency;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Tracker'),
        bottom: TabBar(
          controller: _tc,
          tabs: const [
            Tab(text: '💸 I Owe'),
            Tab(text: '🤝 Owed to Me'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDebtSheet(context, currency),
        icon: const Icon(Icons.add),
        label: const Text('Add Debt'),
      ),
      body: TabBarView(
        controller: _tc,
        children: [
          _DebtList(
            debts: debtProvider.iOwe,
            settled: debtProvider.debts
                .where((d) => d.type == 'owe' && d.isSettled)
                .toList(),
            currency: currency,
            type: 'owe',
            cs: cs,
          ),
          _DebtList(
            debts: debtProvider.owedToMe,
            settled: debtProvider.debts
                .where((d) => d.type == 'owed' && d.isSettled)
                .toList(),
            currency: currency,
            type: 'owed',
            cs: cs,
          ),
        ],
      ),
    );
  }

  void _showAddDebtSheet(BuildContext context, String currency) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String type = 'owe';
    DateTime? dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Debt',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'owe', label: Text('I Owe')),
                    ButtonSegment(value: 'owed', label: Text('Owed to Me')),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) => setSt(() => type = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Person Name',
                      prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: 'Amount', prefixText: '$currency '),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      prefixIcon: Icon(Icons.notes_outlined)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate:
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2035),
                    );
                    if (d != null) setSt(() => dueDate = d);
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(dueDate != null
                      ? 'Due: ${DateFormat('dd MMM yyyy').format(dueDate!)}'
                      : 'Set Due Date (optional)'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty) return;
                    final amt = double.tryParse(amtCtrl.text);
                    if (amt == null || amt <= 0) return;
                    final debt = DebtModel(
                      id: const Uuid().v4(),
                      personName: nameCtrl.text.trim(),
                      amount: amt,
                      type: type,
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim(),
                      dueDate: dueDate != null
                          ? DateFormat('yyyy-MM-dd').format(dueDate!)
                          : null,
                      createdAt: DateTime.now().toIso8601String(),
                    );
                    await context.read<DebtProvider>().addDebt(debt);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DebtList extends StatelessWidget {
  final List<DebtModel> debts;
  final List<DebtModel> settled;
  final String currency;
  final String type;
  final ColorScheme cs;

  const _DebtList({
    required this.debts,
    required this.settled,
    required this.currency,
    required this.type,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty && settled.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake_outlined, size: 64, color: cs.outlineVariant),
            const SizedBox(height: 16),
            Text(type == 'owe'
                ? "You don't owe anyone"
                : 'Nobody owes you'),
          ],
        ),
      );
    }

    final total = debts.fold(0.0, (s, d) => s + d.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        if (debts.isNotEmpty)
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      type == 'owe'
                          ? 'Total I Owe'
                          : 'Total Owed to Me',
                      style: TextStyle(color: cs.onPrimaryContainer)),
                  Text(
                    '$currency${total.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: cs.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        ...debts.map((d) => _DebtCard(
              debt: d,
              currency: currency,
              cs: cs,
              onSettle: () =>
                  context.read<DebtProvider>().markSettled(d.id),
              onDelete: () =>
                  context.read<DebtProvider>().deleteDebt(d.id),
            )),
        if (settled.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Settled',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          ...settled.map((d) => _DebtCard(
                debt: d,
                currency: currency,
                cs: cs,
                isSettled: true,
                onDelete: () =>
                    context.read<DebtProvider>().deleteDebt(d.id),
              )),
        ],
      ],
    );
  }
}

class _DebtCard extends StatelessWidget {
  final DebtModel debt;
  final String currency;
  final ColorScheme cs;
  final VoidCallback? onSettle;
  final VoidCallback? onDelete;
  final bool isSettled;

  const _DebtCard({
    required this.debt,
    required this.currency,
    required this.cs,
    this.onSettle,
    this.onDelete,
    this.isSettled = false,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? due;
    if (debt.dueDate != null) {
      try { due = DateTime.parse(debt.dueDate!); } catch (_) {}
    }
    final isOverdue = due != null && due.isBefore(DateTime.now()) && !isSettled;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSettled
              ? Colors.green.withOpacity(0.15)
              : (isOverdue
                  ? cs.errorContainer
                  : cs.primaryContainer),
          child: Text(
            debt.personName.isNotEmpty
                ? debt.personName[0].toUpperCase()
                : '?',
            style: TextStyle(
                color: isSettled
                    ? Colors.green
                    : (isOverdue ? cs.error : cs.onPrimaryContainer)),
          ),
        ),
        title: Text(debt.personName,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: isSettled
                    ? TextDecoration.lineThrough
                    : null)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (debt.note != null) Text(debt.note!),
            if (due != null)
              Text(
                isOverdue
                    ? '⚠️ Overdue: ${DateFormat('dd MMM').format(due)}'
                    : 'Due: ${DateFormat('dd MMM yyyy').format(due)}',
                style: TextStyle(
                    color: isOverdue ? cs.error : cs.onSurfaceVariant,
                    fontSize: 12),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$currency${debt.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (!isSettled && onSettle != null)
              GestureDetector(
                onTap: onSettle,
                child: Text('Settle',
                    style: TextStyle(
                        color: cs.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        onLongPress: onDelete,
      ),
    );
  }
}
