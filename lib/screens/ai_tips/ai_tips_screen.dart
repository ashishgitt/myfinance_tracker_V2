import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';

class AiTipsScreen extends StatelessWidget {
  const AiTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txnProvider = context.watch<TransactionProvider>();
    final catProvider = context.watch<CategoryProvider>();
    final currency = context.watch<SettingsProvider>().currency;
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final txns = txnProvider.all.where((t) =>
        t.date.startsWith(
            '${now.year}-${now.month.toString().padLeft(2, '0')}')).toList();
    final income = txnProvider.totalIncome(txns);
    final expense = txnProvider.totalExpense(txns);
    final savings = income - expense;
    final savingsRate = income > 0 ? savings / income * 100 : 0.0;
    final catBreakdown = txnProvider.categoryBreakdown(txns, 'expense');

    // Build tips
    final tips = <_Tip>[];

    // Savings rate tip
    if (income > 0) {
      if (savingsRate < 10) {
        tips.add(_Tip(
          icon: '⚠️',
          color: cs.error,
          title: 'Low Savings Rate',
          body:
              'You saved ${savingsRate.toStringAsFixed(1)}% this month. Aim for at least 20% savings.',
        ));
      } else if (savingsRate >= 30) {
        tips.add(_Tip(
          icon: '🎉',
          color: Colors.green,
          title: 'Excellent Savings!',
          body:
              'You saved ${savingsRate.toStringAsFixed(1)}% this month. Keep it up!',
        ));
      } else {
        tips.add(_Tip(
          icon: '👍',
          color: cs.primary,
          title: 'Good Savings Rate',
          body:
              'You saved ${savingsRate.toStringAsFixed(1)}% this month. Try to reach 30%.',
        ));
      }
    }

    // Category-specific tips
    for (final entry in catBreakdown.entries) {
      if (expense > 0) {
        final pct = entry.value / expense * 100;
        final cat = catProvider.findById(entry.key);
        if (cat?.name.toLowerCase().contains('food') == true && pct > 40) {
          tips.add(_Tip(
            icon: '🍔',
            color: Colors.orange,
            title: 'High Food Spending',
            body:
                'You spent ${pct.toStringAsFixed(0)}% on ${cat!.name} this month. Consider reducing to 30%.',
          ));
        }
        if (cat?.name.toLowerCase().contains('entertain') == true && pct > 15) {
          tips.add(_Tip(
            icon: '🎬',
            color: Colors.orange,
            title: 'Entertainment Spending',
            body:
                '${pct.toStringAsFixed(0)}% on entertainment — consider limiting to 10-15%.',
          ));
        }
        if (cat?.name.toLowerCase().contains('subscript') == true && pct > 10) {
          tips.add(_Tip(
            icon: '📺',
            color: Colors.orange,
            title: 'Subscription Review',
            body:
                'You spent $currency${entry.value.toStringAsFixed(0)} on subscriptions. Review unused ones.',
          ));
        }
      }
    }

    if (tips.isEmpty) {
      tips.add(_Tip(
        icon: '💡',
        color: cs.primary,
        title: 'Keep Tracking',
        body: 'Add more transactions to get personalized financial tips.',
      ));
    }

    // 50/30/20 rule
    final needs = income * 0.50;
    final wants = income * 0.30;
    final savTarget = income * 0.20;

    // Health score
    int score = 50;
    if (savingsRate >= 20) score += 20;
    else if (savingsRate >= 10) score += 10;
    if (expense <= income) score += 20;
    if (catBreakdown.length >= 3) score += 10;
    score = score.clamp(0, 100);

    Color scoreColor = cs.error;
    if (score >= 70) scoreColor = Colors.green;
    else if (score >= 50) scoreColor = Colors.orange;

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Financial Health Score
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Financial Health Score',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 10,
                          backgroundColor: cs.surfaceVariant,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(scoreColor),
                        ),
                      ),
                      Column(
                        children: [
                          Text('$score',
                              style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor)),
                          Text('/100',
                              style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    score >= 70
                        ? 'Excellent Financial Health! 🌟'
                        : score >= 50
                            ? 'Good, with room to improve 📈'
                            : 'Needs attention ⚠️',
                    style: TextStyle(
                        color: scoreColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 50/30/20 Rule
          if (income > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('50/30/20 Rule Analysis',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Based on your income of $currency${income.toStringAsFixed(0)}',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    _ruleRow(context, '🏠 Needs (50%)',
                        '$currency${needs.toStringAsFixed(0)}', Colors.blue),
                    const SizedBox(height: 8),
                    _ruleRow(context, '🎭 Wants (30%)',
                        '$currency${wants.toStringAsFixed(0)}', Colors.purple),
                    const SizedBox(height: 8),
                    _ruleRow(context, '💰 Savings (20%)',
                        '$currency${savTarget.toStringAsFixed(0)}', Colors.green),
                    const Divider(height: 24),
                    Text(
                      'Your actual savings: $currency${savings.toStringAsFixed(0)} (${savingsRate.toStringAsFixed(1)}%)',
                      style: TextStyle(
                          color: savings >= savTarget
                              ? Colors.green
                              : cs.error,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Tips
          Text('Personalized Tips',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...tips.map((t) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: t.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Text(t.icon, style: const TextStyle(fontSize: 20)),
                  ),
                  title: Text(t.title,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(t.body),
                  isThreeLine: t.body.length > 50,
                ),
              )),
          const SizedBox(height: 12),
          // General tips
          Card(
            color: cs.primaryContainer.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 General Financial Tips',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  for (final tip in [
                    'Build a 3-6 month emergency fund',
                    'Invest at least 10% of income in SIP/mutual funds',
                    'Avoid impulse purchases — wait 24 hours',
                    'Review and cancel unused subscriptions monthly',
                    'Track every rupee to find hidden leaks',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(child: Text(tip)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleRow(
      BuildContext ctx, String label, String amount, Color color) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(amount,
            style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _Tip {
  final String icon, title, body;
  final Color color;
  const _Tip({required this.icon, required this.color, required this.title, required this.body});
}
