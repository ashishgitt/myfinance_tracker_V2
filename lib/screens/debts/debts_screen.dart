import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../providers/debt_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/models.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Feature 5: Khatabook-style Debt Tracker
// ═══════════════════════════════════════════════════════════════════════════════

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});
  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PersonModel> get _filtered {
    final people = context.read<DebtProvider>().people;
    if (_query.isEmpty) return people;
    return people
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final debtP = context.watch<DebtProvider>();
    final currency = context.watch<SettingsProvider>().currency;
    final cs = Theme.of(context).colorScheme;

    final filtered = _filtered;
    final totalOwedToMe = debtP.totalOwedToMe;
    final totalIOwe = debtP.totalIOwe;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Tracker'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search people…',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        })
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPersonSheet(context),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Person'),
      ),
      body: Column(
        children: [
          // Summary header
          if (totalOwedToMe > 0 || totalIOwe > 0)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem(context, 'Owed to Me',
                      '$currency${totalOwedToMe.toStringAsFixed(0)}',
                      Colors.green),
                  Container(width: 1, height: 40,
                      color: cs.outlineVariant),
                  _summaryItem(context, 'I Owe',
                      '$currency${totalIOwe.toStringAsFixed(0)}', cs.error),
                  Container(width: 1, height: 40,
                      color: cs.outlineVariant),
                  _summaryItem(context, 'People',
                      '${debtP.pendingPeopleCount}', cs.primary),
                ],
              ),
            ),
          // People list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64,
                            color: cs.outlineVariant),
                        const SizedBox(height: 16),
                        Text(_query.isNotEmpty
                            ? 'No results for "$_query"'
                            : 'No people added yet',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        if (_query.isEmpty)
                          FilledButton.tonal(
                            onPressed: () => _showAddPersonSheet(context),
                            child: const Text('Add First Person'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final person = filtered[i];
                      final nb = debtP.netBalance(person.id);
                      final txns = debtP.txnsForPerson(person.id);
                      final lastDate = txns.isNotEmpty
                          ? txns.last.date
                          : null;
                      return _PersonCard(
                        person: person,
                        netBalance: nb,
                        lastDate: lastDate,
                        currency: currency,
                        cs: cs,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PersonDetailScreen(
                              personId: person.id,
                            ),
                          ),
                        ),
                        onDelete: () => _confirmDelete(context, person, debtP),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(BuildContext ctx, String label, String val, Color c) =>
      Column(children: [
        Text(val,
            style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 16)),
        Text(label,
            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
      ]);

  void _showAddPersonSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Person',
                  style: Theme.of(ctx).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Name *',
                    prefixIcon: Icon(Icons.person_outline)),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.notes_outlined)),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  await context.read<DebtProvider>().addPerson(
                    nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isEmpty
                        ? null
                        : phoneCtrl.text.trim(),
                    notes: notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                child: const Text('Add Person'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, PersonModel p, DebtProvider debtP) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${p.name}?'),
        content: const Text(
            'All debt transactions with this person will be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await debtP.deletePerson(p.id);
    }
  }
}

// ─── Person Card ──────────────────────────────────────────────────────────────
class _PersonCard extends StatelessWidget {
  final PersonModel person;
  final double netBalance;
  final String? lastDate;
  final String currency;
  final ColorScheme cs;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PersonCard({
    required this.person,
    required this.netBalance,
    required this.lastDate,
    required this.currency,
    required this.cs,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOwedToMe = netBalance > 0;
    final isOwedByMe = netBalance < 0;
    final balanceColor = isOwedToMe
        ? Colors.green
        : isOwedByMe
            ? cs.error
            : cs.onSurfaceVariant;
    final balanceLabel = isOwedToMe
        ? 'owes you $currency${netBalance.abs().toStringAsFixed(0)}'
        : isOwedByMe
            ? 'you owe $currency${netBalance.abs().toStringAsFixed(0)}'
            : 'Settled ✓';

    return Dismissible(
      key: Key(person.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: cs.error, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // Let the callback handle it
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: isOwedToMe
                ? Colors.green.withOpacity(0.2)
                : isOwedByMe
                    ? cs.errorContainer
                    : cs.surfaceVariant,
            child: Text(
              person.name.isNotEmpty
                  ? person.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isOwedToMe
                      ? Colors.green
                      : isOwedByMe
                          ? cs.error
                          : cs.onSurfaceVariant),
            ),
          ),
          title: Text(person.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (person.phone != null)
                Text(person.phone!,
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 12)),
              if (lastDate != null)
                Text('Last: $lastDate',
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 11)),
            ],
          ),
          isThreeLine: person.phone != null,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                netBalance == 0
                    ? 'Settled'
                    : '$currency${netBalance.abs().toStringAsFixed(0)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: balanceColor,
                    fontSize: 15),
              ),
              Text(
                isOwedToMe
                    ? 'owes you'
                    : isOwedByMe
                        ? 'you owe'
                        : '✓',
                style: TextStyle(fontSize: 10, color: balanceColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Person Detail Screen — Ledger View
// ═══════════════════════════════════════════════════════════════════════════════
class PersonDetailScreen extends StatelessWidget {
  final String personId;
  const PersonDetailScreen({super.key, required this.personId});

  @override
  Widget build(BuildContext context) {
    final debtP = context.watch<DebtProvider>();
    final currency = context.watch<SettingsProvider>().currency;
    final cs = Theme.of(context).colorScheme;

    final person = debtP.findById(personId);
    if (person == null) {
      return const Scaffold(body: Center(child: Text('Person not found')));
    }

    final txns = debtP.txnsForPerson(personId);
    final nb = debtP.netBalance(personId);

    // Running balance
    double running = 0;
    final List<(DebtTransactionModel, double)> entries = [];
    for (final t in txns) {
      if (t.type == 'lent') running += t.amount;
      if (t.type == 'received') running -= t.amount;
      if (t.type == 'borrowed') running -= t.amount;
      if (t.type == 'paid') running += t.amount;
      entries.add((t, running));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditPerson(context, person, debtP),
          ),
          if (person.phone != null)
            IconButton(
              icon: const Icon(Icons.sms_outlined),
              onPressed: () => _sendReminderSms(context, person, currency, nb),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransaction(context, person, currency),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
      body: Column(
        children: [
          // Summary card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: nb >= 0
                    ? [Colors.green.shade700, Colors.green.shade500]
                    : [cs.error, cs.error.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: [
              Text(
                nb >= 0
                    ? '${person.name} owes you'
                    : 'You owe ${person.name}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                '$currency${nb.abs().toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              if (nb != 0) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _settleUp(context, person, debtP, nb, currency),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white)),
                  child: const Text('Settle Up'),
                ),
              ],
            ]),
          ),
          // Transaction list
          Expanded(
            child: txns.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48, color: cs.outlineVariant),
                        const SizedBox(height: 12),
                        Text('No transactions yet',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) {
                      final (t, balance) = entries[i];
                      return _LedgerEntry(
                        txn: t,
                        runningBalance: balance,
                        currency: currency,
                        cs: cs,
                        onDelete: () async {
                          await debtP.deleteDebtTransaction(t.id, personId);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEditPerson(
      BuildContext context, PersonModel p, DebtProvider debtP) {
    final nameCtrl = TextEditingController(text: p.name);
    final phoneCtrl = TextEditingController(text: p.phone ?? '');
    final notesCtrl = TextEditingController(text: p.notes ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit ${p.name}',
                  style: Theme.of(ctx).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await debtP.updatePerson(p.copyWith(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isEmpty
                        ? null
                        : phoneCtrl.text.trim(),
                    notes: notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim(),
                  ));
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
    );
  }

  void _showAddTransaction(
      BuildContext context, PersonModel person, String currency) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String type = 'lent'; // default: I lent them
    DateTime date = DateTime.now();

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
                Text('Add Entry — ${person.name}',
                    style: Theme.of(ctx).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                // Type
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'lent', label: Text('I Lent')),
                    ButtonSegment(
                        value: 'borrowed', label: Text('I Borrowed')),
                    ButtonSegment(
                        value: 'received', label: Text('Received')),
                    ButtonSegment(
                        value: 'paid', label: Text('I Paid')),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) =>
                      setSt(() => type = s.first),
                  multiSelectionEnabled: false,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '$currency '),
                ),
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
                    child: Text(DateFormat('dd MMM yyyy').format(date)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Note (optional)')),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    final amt = double.tryParse(amtCtrl.text);
                    if (amt == null || amt <= 0) return;
                    final txn = await context
                        .read<DebtProvider>()
                        .addDebtTransaction(
                          personId: person.id,
                          amount: amt,
                          type: type,
                          date: DateFormat('yyyy-MM-dd').format(date),
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                    // Feature 4: SMS reminder when lending
                    if (type == 'lent' && ctx.mounted) {
                      _promptSms(ctx, person, currency, amt,
                          DateFormat('dd MMM yyyy').format(date));
                    }
                  },
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  child: const Text('Save Entry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _settleUp(BuildContext context, PersonModel person,
      DebtProvider debtP, double nb, String currency) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Settle Up?'),
        content: Text(
          nb > 0
              ? '${person.name} paid you back $currency${nb.abs().toStringAsFixed(2)}'
              : 'You paid ${person.name} $currency${nb.abs().toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await debtP.settleUp(personId);
    }
  }

  // Feature 4: SMS reminder
  Future<void> _promptSms(BuildContext context, PersonModel person,
      String currency, double amount, String dateStr) async {
    if (person.phone == null) {
      // Ask for number
      final phoneCtrl = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Send SMS to ${person.name}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Send a payment reminder for $currency${amount.toStringAsFixed(0)}?'),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    prefixText: '+91 '),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Skip')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Send SMS')),
          ],
        ),
      );
      if (confirmed == true && phoneCtrl.text.isNotEmpty && context.mounted) {
        await _openSms(
            phoneCtrl.text.trim(), person.name, currency, amount, dateStr);
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Send reminder to ${person.name}?'),
          content: Text(
              'Send payment reminder SMS to ${person.phone}?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Skip')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Send SMS')),
          ],
        ),
      );
      if (confirmed == true && context.mounted) {
        await _openSms(
            person.phone!, person.name, currency, amount, dateStr);
      }
    }
  }

  Future<void> _openSms(String phone, String name, String currency,
      double amount, String dateStr) async {
    final msg = Uri.encodeComponent(
        'Hi $name, this is a reminder that you owe me '
        '$currency${amount.toStringAsFixed(2)} (added on $dateStr). '
        'Please settle at your earliest convenience. '
        '- Sent via MyFinance Tracker');
    final uri = Uri.parse('sms:$phone?body=$msg');
    try {
      await launchUrl(uri);
    } catch (e) {
      debugPrint('SMS launch error (non-fatal): $e');
    }
  }

  Future<void> _sendReminderSms(BuildContext context, PersonModel person,
      String currency, double nb) async {
    if (nb <= 0) return;
    final phone = person.phone;
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number saved for this person')));
      return;
    }
    final msg = Uri.encodeComponent(
        'Hi ${person.name}, this is a reminder that you owe me '
        '$currency${nb.toStringAsFixed(2)}. '
        'Please settle at your earliest convenience. '
        '- Sent via MyFinance Tracker');
    final uri = Uri.parse('sms:$phone?body=$msg');
    try {
      await launchUrl(uri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open SMS: $e')));
      }
    }
  }
}

// ─── Ledger Entry ─────────────────────────────────────────────────────────────
class _LedgerEntry extends StatelessWidget {
  final DebtTransactionModel txn;
  final double runningBalance;
  final String currency;
  final ColorScheme cs;
  final VoidCallback onDelete;

  const _LedgerEntry({
    required this.txn,
    required this.runningBalance,
    required this.currency,
    required this.cs,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isGiving = txn.type == 'lent' || txn.type == 'paid';
    final label = switch (txn.type) {
      'lent'     => 'You Lent',
      'borrowed' => 'You Borrowed',
      'received' => 'Received Back',
      'paid'     => 'You Paid Back',
      _          => txn.type,
    };
    final amtColor = (txn.type == 'lent' || txn.type == 'received')
        ? Colors.green
        : cs.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: amtColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                isGiving ? Icons.arrow_upward : Icons.arrow_downward,
                color: amtColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (txn.note != null)
                    Text(txn.note!,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12)),
                  Text(txn.date,
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${txn.type == 'lent' || txn.type == 'borrowed' ? '+' : '-'}'
                  '$currency${txn.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: amtColor,
                      fontSize: 15),
                ),
                Text(
                  'Bal: $currency${runningBalance.abs().toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 10,
                      color: runningBalance >= 0
                          ? Colors.green
                          : cs.error),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
