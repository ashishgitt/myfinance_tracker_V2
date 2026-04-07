import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../providers/budget_savings_debt_providers.dart';
import '../../providers/settings_provider.dart';
import '../../models/models.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savProvider = context.watch<SavingsProvider>();
    final currency = context.watch<SettingsProvider>().currency;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalSheet(context, currency),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
      body: savProvider.goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings_outlined, size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 16),
                  const Text('No savings goals yet'),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () => _showAddGoalSheet(context, currency),
                    child: const Text('Create First Goal'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: savProvider.goals.map((g) => _GoalCard(
                    goal: g,
                    currency: currency,
                    onContribute: () => _showContributeSheet(context, g, currency),
                    onDelete: () => context.read<SavingsProvider>().deleteGoal(g.id),
                  )).toList(),
            ),
    );
  }

  void _showAddGoalSheet(BuildContext context, String currency) {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    DateTime? deadline;

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
                Text('New Savings Goal',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Goal Title',
                      hintText: 'e.g. Buy iPhone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Target Amount',
                    prefixText: '$currency ',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now()
                          .add(const Duration(days: 90)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2035),
                    );
                    if (d != null) setSt(() => deadline = d);
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(deadline != null
                      ? DateFormat('dd MMM yyyy').format(deadline!)
                      : 'Set Deadline (optional)'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (titleCtrl.text.isEmpty) return;
                    final target = double.tryParse(targetCtrl.text);
                    if (target == null || target <= 0) return;
                    final goal = SavingsGoalModel(
                      id: const Uuid().v4(),
                      title: titleCtrl.text.trim(),
                      targetAmount: target,
                      deadline: deadline != null
                          ? DateFormat('yyyy-MM-dd').format(deadline!)
                          : null,
                      createdAt: DateTime.now().toIso8601String(),
                    );
                    await context.read<SavingsProvider>().addGoal(goal);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  child: const Text('Create Goal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContributeSheet(
      BuildContext context, SavingsGoalModel goal, String currency) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add to "${goal.title}"'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              labelText: 'Amount', prefixText: '$currency '),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () async {
                final amt = double.tryParse(ctrl.text);
                if (amt == null || amt <= 0) return;
                await context
                    .read<SavingsProvider>()
                    .addContribution(goal.id, amt);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add')),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoalModel goal;
  final String currency;
  final VoidCallback onContribute;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.currency,
    required this.onContribute,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final remaining = goal.targetAmount - goal.savedAmount;
    final pct = goal.progressPercent;

    // Estimate completion
    String? etaStr;
    // Simple: if saved > 0 for some time, estimate based on daily rate
    // Just display deadline if set
    if (goal.deadline != null) {
      try {
        final dl = DateTime.parse(goal.deadline!);
        final daysLeft = dl.difference(DateTime.now()).inDays;
        etaStr = daysLeft > 0 ? '$daysLeft days left' : 'Deadline passed';
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(goal.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (goal.isCompleted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('✓ Complete',
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: cs.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                    goal.isCompleted ? Colors.green : cs.primary),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currency${goal.savedAmount.toStringAsFixed(0)} saved',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'of $currency${goal.targetAmount.toStringAsFixed(0)}',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            if (etaStr != null || remaining > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (remaining > 0)
                      Text(
                        '$currency${remaining.toStringAsFixed(0)} remaining',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                    if (etaStr != null)
                      Text(etaStr,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
            if (!goal.isCompleted) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onContribute,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Contribution'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(36)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
