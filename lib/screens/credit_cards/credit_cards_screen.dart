import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/credit_card_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/models.dart';
import '../../core/constants/app_constants.dart';

class CreditCardsScreen extends StatelessWidget {
  const CreditCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ccP = context.watch<CreditCardProvider>();
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currency;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Credit Cards')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditCard(context, currency, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
      ),
      body: ccP.cards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card_outlined,
                      size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 16),
                  const Text('No credit cards added'),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () =>
                        _showAddEditCard(context, currency, null),
                    child: const Text('Add First Card'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Summary header
                _SummaryHeader(
                    ccP: ccP, currency: currency, cs: cs),
                const SizedBox(height: 16),
                ...ccP.cards.map((card) => _CardTile(
                      card: card,
                      ccP: ccP,
                      currency: currency,
                      cs: cs,
                      onEdit: () =>
                          _showAddEditCard(context, currency, card),
                      onAddTxn: () =>
                          _showAddTransaction(context, card, currency),
                      onDelete: () =>
                          _confirmDelete(context, card, ccP),
                    )),
              ],
            ),
    );
  }

  void _showAddEditCard(
      BuildContext context, String currency, CreditCardModel? existing) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final bankCtrl = TextEditingController(text: existing?.bank);
    final lastFourCtrl =
        TextEditingController(text: existing?.lastFour);
    final limitCtrl = TextEditingController(
        text: existing?.creditLimit.toStringAsFixed(0));
    int billDate = existing?.billDate ?? 1;
    int dueDate = existing?.dueDate ?? 15;
    int selectedColor =
        existing?.color ?? AppConstants.categoryColors.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing != null ? 'Edit Card' : 'Add Credit Card',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Card Name',
                        hintText: 'e.g. HDFC Regalia')),
                const SizedBox(height: 12),
                TextField(
                    controller: bankCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Bank Name',
                        hintText: 'e.g. HDFC')),
                const SizedBox(height: 12),
                TextField(
                    controller: lastFourCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(
                        labelText: 'Last 4 digits',
                        counterText: '')),
                const SizedBox(height: 12),
                TextField(
                    controller: limitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'Credit Limit',
                        prefixText: '$currency ')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                          labelText: 'Bill Date'),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: billDate,
                          isExpanded: true,
                          items: List.generate(28, (i) => i + 1)
                              .map((d) => DropdownMenuItem(
                                  value: d, child: Text('$d')))
                              .toList(),
                          onChanged: (v) =>
                              setSt(() => billDate = v!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                          labelText: 'Due Date'),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: dueDate,
                          isExpanded: true,
                          items: List.generate(28, (i) => i + 1)
                              .map((d) => DropdownMenuItem(
                                  value: d, child: Text('$d')))
                              .toList(),
                          onChanged: (v) =>
                              setSt(() => dueDate = v!),
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Text('Card Color',
                    style:
                        Theme.of(ctx).textTheme.labelLarge),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        AppConstants.categoryColors.length,
                    itemBuilder: (_, i) {
                      final c = AppConstants.categoryColors[i];
                      return GestureDetector(
                        onTap: () =>
                            setSt(() => selectedColor = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(
                              right: 8),
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: selectedColor == c
                                ? Border.all(
                                    width: 3,
                                    color: Colors.white)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final limit =
                        double.tryParse(limitCtrl.text) ?? 0;
                    final card = CreditCardModel(
                      id: existing?.id ?? const Uuid().v4(),
                      name: nameCtrl.text.trim(),
                      bank: bankCtrl.text.trim(),
                      lastFour: lastFourCtrl.text.trim(),
                      creditLimit: limit,
                      billDate: billDate,
                      dueDate: dueDate,
                      color: selectedColor,
                      createdAt: existing?.createdAt ??
                          DateTime.now().toIso8601String(),
                    );
                    final ccP =
                        context.read<CreditCardProvider>();
                    if (existing != null) {
                      await ccP.updateCard(card);
                    } else {
                      await ccP.addCard(card);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  child: Text(
                      existing != null ? 'Update' : 'Add Card'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTransaction(
      BuildContext context, CreditCardModel card, String currency) {
    final amtCtrl = TextEditingController();
    final merchantCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? categoryId;
    DateTime date = DateTime.now();
    bool isRecoverable = false;
    final recoverCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Transaction — ${card.name}',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                    controller: amtCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '$currency ')),
                const SizedBox(height: 12),
                TextField(
                    controller: merchantCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Merchant',
                        hintText: 'e.g. Amazon')),
                const SizedBox(height: 12),
                // Category
                Builder(builder: (ctx2) {
                  final catP =
                      context.read<CategoryProvider>();
                  return InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Category'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: categoryId,
                        isExpanded: true,
                        hint: const Text('Select'),
                        items: catP.expenseCategories
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Row(children: [
                                    Text(c.emoji),
                                    const SizedBox(width: 8),
                                    Text(c.name),
                                  ]),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setSt(() => categoryId = v),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                // Date
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setSt(() => date = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Date',
                        suffixIcon: Icon(Icons.chevron_right)),
                    child: Text(
                        DateFormat('dd MMM yyyy').format(date)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Note (optional)')),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Recoverable?'),
                  subtitle: const Text(
                      'Someone else will reimburse this'),
                  value: isRecoverable,
                  onChanged: (v) =>
                      setSt(() => isRecoverable = v),
                ),
                if (isRecoverable) ...[
                  TextField(
                      controller: recoverCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Recover from (person)',
                          prefixIcon:
                              Icon(Icons.person_outline))),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    final amt = double.tryParse(amtCtrl.text);
                    if (amt == null || amt <= 0) return;
                    if (categoryId == null) return;
                    final txn = CreditCardTransactionModel(
                      id: const Uuid().v4(),
                      cardId: card.id,
                      amount: amt,
                      date: DateFormat('yyyy-MM-dd')
                          .format(date),
                      merchant: merchantCtrl.text.trim()
                              .isEmpty
                          ? null
                          : merchantCtrl.text.trim(),
                      categoryId: categoryId!,
                      isRecoverable: isRecoverable,
                      recoverFrom: isRecoverable &&
                              recoverCtrl.text.trim().isNotEmpty
                          ? recoverCtrl.text.trim()
                          : null,
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim(),
                      createdAt:
                          DateTime.now().toIso8601String(),
                    );
                    await context
                        .read<CreditCardProvider>()
                        .addTransaction(txn);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  child: const Text('Save Transaction'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context,
      CreditCardModel card, CreditCardProvider ccP) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${card.name}?'),
        content: const Text(
            'All transactions for this card will also be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await ccP.deleteCard(card.id);
  }
}

// ─── Summary Header ───────────────────────────────────────────────────────────
class _SummaryHeader extends StatelessWidget {
  final CreditCardProvider ccP;
  final String currency;
  final ColorScheme cs;
  const _SummaryHeader(
      {required this.ccP, required this.currency, required this.cs});

  @override
  Widget build(BuildContext context) {
    final totalLimit = ccP.totalLimit;
    final totalUsed = ccP.totalUsed;
    final available = totalLimit - totalUsed;
    final pct = totalLimit > 0
        ? (totalUsed / totalLimit).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      color: cs.primaryContainer.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            _stat(context, 'Total Limit',
                '$currency${_fmt(totalLimit)}', cs.primary),
            _stat(context, 'Used',
                '$currency${_fmt(totalUsed)}', cs.error),
            _stat(context, 'Available',
                '$currency${_fmt(available)}', Colors.green),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: cs.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                  pct > 0.8 ? cs.error : cs.primary),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stat(BuildContext ctx, String label, String val, Color c) =>
      Column(children: [
        Text(val,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: c, fontSize: 15)),
        Text(label,
            style: Theme.of(ctx)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
      ]);

  String _fmt(double v) => v >= 100000
      ? '${(v / 100000).toStringAsFixed(1)}L'
      : v >= 1000
          ? '${(v / 1000).toStringAsFixed(1)}K'
          : v.toStringAsFixed(0);
}

// ─── Card Tile ────────────────────────────────────────────────────────────────
class _CardTile extends StatelessWidget {
  final CreditCardModel card;
  final CreditCardProvider ccP;
  final String currency;
  final ColorScheme cs;
  final VoidCallback onEdit, onAddTxn, onDelete;

  const _CardTile({
    required this.card,
    required this.ccP,
    required this.currency,
    required this.cs,
    required this.onEdit,
    required this.onAddTxn,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final used = ccP.usedForCard(card.id);
    final available = card.creditLimit - used;
    final pct = card.creditLimit > 0
        ? (used / card.creditLimit).clamp(0.0, 1.0)
        : 0.0;
    final isDue = ccP.isDueSoon(card);
    final txns = ccP.txnsForCard(card.id);

    // Category breakdown for pie chart
    final catBreakdown = <String, double>{};
    for (final t in txns) {
      catBreakdown[t.categoryId] =
          (catBreakdown[t.categoryId] ?? 0) + t.amount;
    }
    final catP = context.read<CategoryProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        // Card header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(card.color),
                Color(card.color).withOpacity(0.7)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16)),
          ),
          child: Column(children: [
            Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(card.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(card.bank,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8))),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                Text('•••• ${card.lastFour}',
                    style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 2)),
                if (isDue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Bill Due Soon!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10)),
                  ),
              ]),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Text('Used: $currency${used.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white)),
              Text(
                  'Limit: $currency${card.creditLimit.toStringAsFixed(0)}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8))),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                    pct > 0.8 ? Colors.red.shade300 : Colors.white),
              ),
            ),
          ]),
        ),
        // Actions + details
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: Text(
                    'Bill: ${card.billDate}th | Due: ${card.dueDate}th',
                    style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12)),
              ),
              Text('Available: $currency${available.toStringAsFixed(0)}',
                  style: TextStyle(
                      color: available < card.creditLimit * 0.2
                          ? cs.error
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            // Spending chart if txns exist
            if (catBreakdown.isNotEmpty) ...[
              const Divider(),
              SizedBox(
                height: 80,
                child: Row(children: [
                  SizedBox(
                    width: 80,
                    child: PieChart(PieChartData(
                      sections: catBreakdown.entries.take(5).map((e) {
                        final cat = catP.findById(e.key);
                        return PieChartSectionData(
                          value: e.value,
                          color: cat != null
                              ? Color(cat.color)
                              : Colors.grey,
                          title: '',
                          radius: 30,
                        );
                      }).toList(),
                      sectionsSpace: 1,
                      centerSpaceRadius: 15,
                    )),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: catBreakdown.entries
                          .take(3)
                          .map((e) {
                        final cat = catP.findById(e.key);
                        return Row(children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: cat != null
                                    ? Color(cat.color)
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              )),
                          const SizedBox(width: 4),
                          Text(
                              '${cat?.name ?? '?'}: $currency${e.value.toStringAsFixed(0)}',
                              style:
                                  const TextStyle(fontSize: 11)),
                        ]);
                      }).toList(),
                    ),
                  ),
                ]),
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _actionBtn(
                    context, Icons.add, 'Add Txn', onAddTxn),
                _actionBtn(
                    context, Icons.edit_outlined, 'Edit', onEdit),
                _actionBtn(context, Icons.list_alt_outlined,
                    'History',
                    () => _showHistory(context, card)),
                _actionBtn(context, Icons.delete_outline, 'Delete',
                    onDelete,
                    color: cs.error),
              ],
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _actionBtn(BuildContext ctx, IconData icon, String label,
      VoidCallback onTap,
      {Color? color}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            Icon(icon, size: 20, color: color),
            Text(label,
                style: TextStyle(fontSize: 10, color: color)),
          ]),
        ),
      );

  void _showHistory(BuildContext context, CreditCardModel card) {
    final txns = ccP.txnsForCard(card.id);
    final catP = context.read<CategoryProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, sc) => Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('${card.name} — Transactions',
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (txns.isEmpty)
            const Expanded(
                child: Center(
                    child: Text('No transactions yet')))
          else
            Expanded(
              child: ListView.builder(
                controller: sc,
                itemCount: txns.length,
                itemBuilder: (_, i) {
                  final t = txns[i];
                  final cat = catP.findById(t.categoryId);
                  return ListTile(
                    leading: Text(cat?.emoji ?? '💳',
                        style: const TextStyle(fontSize: 24)),
                    title: Text(t.merchant ?? cat?.name ?? '?'),
                    subtitle: Text(t.date),
                    trailing: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                            '$currency${t.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.error)),
                        if (t.isRecoverable)
                          Text('Recover: ${t.recoverFrom ?? '?'}',
                              style:
                                  const TextStyle(fontSize: 10)),
                      ],
                    ),
                    onLongPress: () async {
                      await context
                          .read<CreditCardProvider>()
                          .deleteTransaction(t.id, t.cardId);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
        ]),
      ),
    );
  }
}
