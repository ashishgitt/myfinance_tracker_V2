import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/services/notification_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../about/about_screen.dart';
import '../export/export_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        _header(context, 'Preferences'),
        // Currency
        ListTile(
          leading: const Icon(Icons.currency_exchange),
          title: const Text('Default Currency'),
          trailing: Text(settings.currency,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: cs.primary)),
          onTap: () => _showCurrencyPicker(context, settings),
        ),
        // Theme
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Theme'),
          trailing: DropdownButton<String>(
            value: settings.theme,
            underline: const SizedBox(),
            items: AppConstants.themeOptions
                .map((t) =>
                    DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => settings.setTheme(v!),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.date_range_outlined),
          title: const Text('First Day of Week'),
          trailing: DropdownButton<String>(
            value: settings.weekStart,
            underline: const SizedBox(),
            items: AppConstants.weekStartOptions
                .map((t) =>
                    DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => settings.setWeekStart(v!),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today_outlined),
          title: const Text('Month Start Day'),
          subtitle: Text('Day ${settings.monthStartDay}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              _showMonthStartPicker(context, settings),
        ),
        const Divider(),
        _header(context, 'Notifications'),
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: const Text('Daily Reminder'),
          subtitle: const Text('Remind me to log transactions'),
          value: settings.dailyReminder,
          onChanged: (v) async {
            await settings.setDailyReminder(v);
            if (v) {
              await NotificationService.scheduleDailyReminder(
                settings.reminderTime.hour,
                settings.reminderTime.minute,
              );
            } else {
              await NotificationService.cancelDailyReminder();
            }
          },
        ),
        if (settings.dailyReminder)
          ListTile(
            leading: const Icon(Icons.access_time_outlined),
            title: const Text('Reminder Time'),
            trailing: Text(settings.reminderTime.format(context),
                style: TextStyle(color: cs.primary)),
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: settings.reminderTime,
              );
              if (t != null && context.mounted) {
                await settings.setReminderTime(t);
                await NotificationService.scheduleDailyReminder(
                    t.hour, t.minute);
              }
            },
          ),
        const Divider(),
        _header(context, 'Security'),
        SwitchListTile(
          secondary: const Icon(Icons.fingerprint),
          title: const Text('App Lock'),
          subtitle:
              const Text('Use fingerprint / face to unlock'),
          value: settings.appLockEnabled,
          onChanged: (v) async {
            if (v) {
              try {
                final auth = LocalAuthentication();
                final supported =
                    await auth.canCheckBiometrics ||
                        await auth.isDeviceSupported();
                if (supported) {
                  final ok = await auth.authenticate(
                    localizedReason: 'Enable app lock',
                    options: const AuthenticationOptions(
                        biometricOnly: false,
                        stickyAuth: true),
                  );
                  if (ok) await settings.setAppLock(true);
                } else {
                  await settings.setAppLock(true);
                }
              } catch (e) {
                debugPrint('biometric error: $e');
                await settings.setAppLock(true);
              }
            } else {
              await settings.setAppLock(false);
            }
          },
        ),
        const Divider(),
        _header(context, 'Export'),
        ListTile(
          leading: const Icon(Icons.upload_file_outlined),
          title: const Text('Export & Share'),
          subtitle: const Text('PDF or Excel with date filter'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const ExportScreen())),
        ),
        const Divider(),
        _header(context, 'Data Management'),
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: const Text('Export Backup (JSON)'),
          onTap: () => _exportBackup(context),
        ),
        ListTile(
          leading: const Icon(Icons.restore_outlined),
          title: const Text('Restore from Backup'),
          onTap: () => _importBackup(context),
        ),
        ListTile(
          leading:
              Icon(Icons.delete_forever_outlined, color: cs.error),
          title: Text('Clear All Data',
              style: TextStyle(color: cs.error)),
          onTap: () => _confirmClearData(context),
        ),
        const Divider(),
        _header(context, 'App'),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About MyFinance Tracker'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const AboutScreen())),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _header(BuildContext context, String title) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            )),
      );

  void _showCurrencyPicker(
      BuildContext ctx, SettingsProvider settings) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Select Currency'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.currencies
              .map((c) => ChoiceChip(
                    label: Text(c,
                        style: const TextStyle(fontSize: 18)),
                    selected: settings.currency == c,
                    onSelected: (_) {
                      settings.setCurrency(c);
                      Navigator.pop(ctx);
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _showMonthStartPicker(
      BuildContext ctx, SettingsProvider settings) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Month Start Day'),
        content: SizedBox(
          width: 200,
          height: 300,
          child: GridView.builder(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4),
            itemCount: 28,
            itemBuilder: (_, i) {
              final day = i + 1;
              final selected = settings.monthStartDay == day;
              return GestureDetector(
                onTap: () {
                  settings.setMonthStartDay(day);
                  Navigator.pop(ctx);
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(ctx).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$day',
                      style: TextStyle(
                          color: selected
                              ? Colors.white
                              : null)),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final db = DatabaseHelper();
      final txns = await db.getAllTransactions();
      final cats = await db.getAllCategories();
      final data = json.encode({
        'transactions': txns,
        'categories': cats,
        'exported_at': DateTime.now().toIso8601String(),
      });
      Directory dir;
      try {
        dir = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      } catch (_) {
        dir = await getApplicationDocumentsDirectory();
      }
      final file = File(
          '${dir.path}/myfinance_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(data);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Backup saved: ${file.path}'),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.first.path;
      if (path == null) return;
      final content = await File(path).readAsString();
      final data = json.decode(content) as Map<String, dynamic>;
      final db = DatabaseHelper();
      for (final t in (data['transactions'] as List? ?? [])) {
        await db.insertTransaction(
            Map<String, dynamic>.from(t as Map));
      }
      if (context.mounted) {
        await context.read<TransactionProvider>().loadAll();
        await context.read<CategoryProvider>().loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Backup restored!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restore failed: $e')));
      }
    }
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
            'ALL transactions, budgets and goals will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final db = DatabaseHelper();
      final database = await db.database;
      await database.delete('transactions');
      await database.delete('budgets');
      await database.delete('savings_goals');
      await database.delete('debts');
      if (context.mounted) {
        await context.read<TransactionProvider>().loadAll();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All data cleared')));
      }
    }
  }
}
