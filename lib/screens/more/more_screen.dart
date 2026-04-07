import 'package:flutter/material.dart';
import '../savings/savings_screen.dart';
import '../debts/debts_screen.dart';
import '../ai_tips/ai_tips_screen.dart';
import '../calendar/calendar_view_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../categories/categories_screen.dart';
import '../credit_cards/credit_cards_screen.dart';
import '../export/export_screen.dart';
import '../about/about_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = [
      _Item('Savings Goals', '🎯', Icons.savings_outlined,
          cs.primary,
          () => _go(context, const SavingsScreen())),
      _Item('Debt Tracker', '🤝', Icons.handshake_outlined,
          Colors.orange,
          () => _go(context, const DebtsScreen())),
      _Item('Credit Cards', '💳', Icons.credit_card_outlined,
          Colors.purple,
          () => _go(context, const CreditCardsScreen())),
      _Item('AI Financial Tips', '💡',
          Icons.lightbulb_outline, Colors.amber,
          () => _go(context, const AiTipsScreen())),
      _Item('Calendar View', '📅',
          Icons.calendar_month_outlined, Colors.teal,
          () => _go(context, const CalendarViewScreen())),
      _Item('Search', '🔍', Icons.search, Colors.indigo,
          () => _go(context, const SearchScreen())),
      _Item('Export & Share', '📤',
          Icons.upload_file_outlined, Colors.green,
          () => _go(context, const ExportScreen())),
      _Item('Categories', '🗂️', Icons.category_outlined,
          Colors.deepOrange,
          () => _go(context, const CategoriesScreen())),
      _Item('Settings', '⚙️', Icons.settings_outlined,
          Colors.grey,
          () => _go(context, const SettingsScreen())),
      _Item('About', 'ℹ️', Icons.info_outline,
          cs.secondary,
          () => _go(context, const AboutScreen())),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (ctx, i) {
          final item = items[i];
          return Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(item.emoji,
                    style: const TextStyle(fontSize: 20)),
              ),
              title: Text(item.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right),
              onTap: item.onTap,
            ),
          );
        },
      ),
    );
  }

  void _go(BuildContext context, Widget screen) =>
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => screen));
}

class _Item {
  final String title, emoji;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Item(this.title, this.emoji, this.icon,
      this.color, this.onTap);
}
