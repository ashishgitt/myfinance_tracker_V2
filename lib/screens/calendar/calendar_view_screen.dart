import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/transaction_model.dart';
import '../../widgets/transaction_card.dart';
import '../transactions/add_transaction_screen.dart';

class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({super.key});
  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<TransactionModel> _getEventsForDay(
      List<TransactionModel> all, DateTime day) {
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return all.where((t) => t.date == key).toList();
  }

  @override
  Widget build(BuildContext context) {
    final txnProvider = context.watch<TransactionProvider>();
    final catProvider = context.watch<CategoryProvider>();
    final currency = context.watch<SettingsProvider>().currency;
    final cs = Theme.of(context).colorScheme;

    final selectedTxns = _selectedDay != null
        ? _getEventsForDay(txnProvider.all, _selectedDay!)
        : <TransactionModel>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          TableCalendar<TransactionModel>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2035),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            eventLoader: (day) =>
                _getEventsForDay(txnProvider.all, day),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (ctx, day, events) {
                if (events.isEmpty) return null;
                final hasIncome = events.any((e) => e.type == 'income');
                final hasExpense = events.any((e) => e.type == 'expense');
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasExpense)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                            color: cs.error, shape: BoxShape.circle),
                      ),
                    if (hasIncome)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                            color: Colors.green, shape: BoxShape.circle),
                      ),
                  ],
                );
              },
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                  color: cs.primary, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                  color: cs.primaryContainer, shape: BoxShape.circle),
              todayTextStyle: TextStyle(color: cs.onPrimaryContainer),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const Divider(height: 1),
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    DateFormat('EEEE, dd MMM yyyy').format(_selectedDay!),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (selectedTxns.isNotEmpty) ...[
                    Icon(Icons.circle, size: 8, color: cs.error),
                    const SizedBox(width: 4),
                    Text(
                      currency +
                          selectedTxns
                              .where((t) => t.type == 'expense')
                              .fold(0.0, (s, t) => s + t.amount)
                              .toStringAsFixed(0),
                      style: TextStyle(
                          color: cs.error, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.circle, size: 8, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      currency +
                          selectedTxns
                              .where((t) => t.type == 'income')
                              .fold(0.0, (s, t) => s + t.amount)
                              .toStringAsFixed(0),
                      style: const TextStyle(
                          color: Colors.green, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: selectedTxns.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note_outlined,
                            size: 48, color: cs.outlineVariant),
                        const SizedBox(height: 8),
                        Text(
                          _selectedDay == null
                              ? 'Select a date'
                              : 'No transactions on this day',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: selectedTxns.length,
                    itemBuilder: (ctx, i) {
                      final t = selectedTxns[i];
                      return TransactionCard(
                        transaction: t,
                        category: catProvider.findById(t.categoryId),
                        currency: currency,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    AddTransactionScreen(existing: t))),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
