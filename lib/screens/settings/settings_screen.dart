import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../about/about_screen.dart';
import '../export/export_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        // ── Google Account Header (if logged in) ─────────────
        if (auth.isLoggedIn) _buildAccountHeader(context, auth, cs),

        _header(context, 'Preferences'),
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
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Theme'),
          trailing: DropdownButton<String>(
            value: settings.theme,
            underline: const SizedBox(),
            items: AppConstants.themeOptions
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
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
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => settings.setWeekStart(v!),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today_outlined),
          title: const Text('Month Start Day'),
          subtitle: Text('Day ${settings.monthStartDay}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showMonthStartPicker(context, settings),
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
                  settings.reminderTime.hour, settings.reminderTime.minute);
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
                  context: context, initialTime: settings.reminderTime);
              if (t != null && context.mounted) {
                await settings.setReminderTime(t);
                await NotificationService.scheduleDailyReminder(t.hour, t.minute);
              }
            },
          ),
        const Divider(),

        _header(context, 'Security'),
        SwitchListTile(
          secondary: const Icon(Icons.fingerprint),
          title: const Text('App Lock'),
          subtitle: const Text('Use fingerprint / face to unlock'),
          value: settings.appLockEnabled,
          onChanged: (v) async {
            if (v) {
              try {
                final la = LocalAuthentication();
                final ok = await la.canCheckBiometrics ||
                    await la.isDeviceSupported();
                if (ok) {
                  final did = await la.authenticate(
                    localizedReason: 'Enable app lock',
                    options: const AuthenticationOptions(
                        biometricOnly: false, stickyAuth: true),
                  );
                  if (did) await settings.setAppLock(true);
                } else {
                  await settings.setAppLock(true);
                }
              } catch (e) {
                debugPrint('biometric: $e');
                await settings.setAppLock(true);
              }
            } else {
              await settings.setAppLock(false);
            }
          },
        ),
        const Divider(),

        // ── Cloud Sync (Feature 1) ────────────────────────────
        _header(context, 'Cloud Backup'),
        if (!auth.isLoggedIn)
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Sign in with Google'),
            subtitle: const Text('Back up data to the cloud'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final ok = await context.read<AuthProvider>().signInWithGoogle();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Signed in successfully' : 'Sign-in failed'),
                ));
              }
            },
          )
        else ...[
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync Now'),
            subtitle: auth.lastSynced != null
                ? Text('Last synced: ${auth.lastSynced}')
                : const Text('Never synced'),
            trailing: auth.loading
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator())
                : FilledButton.tonal(
                    onPressed: () async {
                      final db = DatabaseHelper();
                      final txns = await db.getAllTransactions();
                      await context.read<AuthProvider>().syncNow(
                          {'transactions': txns, 'sync_time': DateTime.now().toIso8601String()});
                    },
                    child: const Text('Sync'),
                  ),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: cs.error),
            title: Text('Sign Out', style: TextStyle(color: cs.error)),
            onTap: () => _confirmSignOut(context),
          ),
        ],
        const Divider(),

        _header(context, 'Export'),
        ListTile(
          leading: const Icon(Icons.upload_file_outlined),
          title: const Text('Export & Share'),
          subtitle: const Text('PDF or Excel with date filter'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ExportScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.schedule_send_outlined),
          title: const Text('Scheduled Export'),
          subtitle: const Text('Auto-export on a schedule'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ScheduledExportScreen())),
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
          leading: Icon(Icons.delete_forever_outlined, color: cs.error),
          title: Text('Clear All Data', style: TextStyle(color: cs.error)),
          onTap: () => _confirmClearData(context),
        ),
        const Divider(),

        _header(context, 'App'),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About MyFinance Tracker'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AboutScreen())),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildAccountHeader(
      BuildContext context, AuthProvider auth, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: cs.primary,
          backgroundImage: auth.userPhotoUrl != null
              ? NetworkImage(auth.userPhotoUrl!)
              : null,
          child: auth.userPhotoUrl == null
              ? Text(
                  (auth.userName ?? 'U').isNotEmpty
                      ? (auth.userName![0]).toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(auth.userName ?? 'Google User',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (auth.userEmail != null)
              Text(auth.userEmail!,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ]),
        ),
        Icon(Icons.cloud_done_outlined, color: cs.primary),
      ]),
    );
  }

  Widget _header(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(title,
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      );

  void _showCurrencyPicker(BuildContext ctx, SettingsProvider s) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Select Currency'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.currencies
              .map((c) => ChoiceChip(
                    label: Text(c, style: const TextStyle(fontSize: 18)),
                    selected: s.currency == c,
                    onSelected: (_) {
                      s.setCurrency(c);
                      Navigator.pop(ctx);
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))
        ],
      ),
    );
  }

  void _showMonthStartPicker(BuildContext ctx, SettingsProvider s) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Month Start Day'),
        content: SizedBox(
          width: 200,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, crossAxisSpacing: 4, mainAxisSpacing: 4),
            itemCount: 28,
            itemBuilder: (_, i) {
              final day = i + 1;
              final sel = s.monthStartDay == day;
              return GestureDetector(
                onTap: () {
                  s.setMonthStartDay(day);
                  Navigator.pop(ctx);
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel
                        ? Theme.of(ctx).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$day',
                      style:
                          TextStyle(color: sel ? Colors.white : null)),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
            'Your local data remains intact. Cloud sync will be unavailable until you sign in again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign Out')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backup saved: ${file.path}')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.isEmpty) return;
      final path = result.files.first.path;
      if (path == null) return;
      final content = await File(path).readAsString();
      final data = json.decode(content) as Map<String, dynamic>;
      final db = DatabaseHelper();
      for (final t in (data['transactions'] as List? ?? [])) {
        await db.insertTransaction(Map<String, dynamic>.from(t as Map));
      }
      if (context.mounted) {
        await context.read<TransactionProvider>().loadAll();
        await context.read<CategoryProvider>().loadCategories();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Backup restored!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Restore failed: $e')));
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
                backgroundColor: Theme.of(context).colorScheme.error),
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
      await database.delete('people');
      await database.delete('debt_transactions');
      if (context.mounted) {
        await context.read<TransactionProvider>().loadAll();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('All data cleared')));
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Feature 2: Scheduled Export Screen
// ═══════════════════════════════════════════════════════════════════════════════
class ScheduledExportScreen extends StatefulWidget {
  const ScheduledExportScreen({super.key});
  @override
  State<ScheduledExportScreen> createState() => _ScheduledExportScreenState();
}

class _ScheduledExportScreenState extends State<ScheduledExportScreen> {
  bool _enabled = false;
  String _frequency = 'Weekly';
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  final _emailCtrl = TextEditingController();
  String _format = 'PDF';
  String _range = 'Current Month';

  static const _freqOptions = ['Daily', 'Weekly', 'Monthly'];
  static const _formatOptions = ['PDF', 'Excel'];
  static const _rangeOptions = ['All Transactions', 'Current Month', 'Current Week'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _enabled = prefs.getBool('sched_export_enabled') ?? false;
      _frequency = prefs.getString('sched_export_freq') ?? 'Weekly';
      _format = prefs.getString('sched_export_format') ?? 'PDF';
      _range = prefs.getString('sched_export_range') ?? 'Current Month';
      _emailCtrl.text = prefs.getString('sched_export_email') ?? '';
      final h = prefs.getInt('sched_export_hour') ?? 8;
      final m = prefs.getInt('sched_export_minute') ?? 0;
      _time = TimeOfDay(hour: h, minute: m);
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sched_export_enabled', _enabled);
    await prefs.setString('sched_export_freq', _frequency);
    await prefs.setString('sched_export_format', _format);
    await prefs.setString('sched_export_range', _range);
    await prefs.setString('sched_export_email', _emailCtrl.text.trim());
    await prefs.setInt('sched_export_hour', _time.hour);
    await prefs.setInt('sched_export_minute', _time.minute);

    if (_enabled) {
      await NotificationService.scheduleExportReminder(
          _time.hour, _time.minute, _frequency);
    } else {
      await NotificationService.cancelExportReminder();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scheduled export settings saved')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Scheduled Export')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Enable Scheduled Export'),
              subtitle: const Text('Auto-generate and share reports'),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
          ),
          const SizedBox(height: 12),
          if (_enabled) ...[
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Frequency'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _frequency,
                  isExpanded: true,
                  items: _freqOptions
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => _frequency = v!),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final t = await showTimePicker(
                    context: context, initialTime: _time);
                if (t != null) setState(() => _time = t);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Delivery Time',
                    suffixIcon: Icon(Icons.chevron_right)),
                child: Text(_time.format(context)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Recipient Email',
                  hintText: 'yourname@example.com',
                  prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Format'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _format,
                  isExpanded: true,
                  items: _formatOptions
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => _format = v!),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Include'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _range,
                  isExpanded: true,
                  items: _rangeOptions
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _range = v!),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: cs.primaryContainer.withOpacity(0.4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Icon(Icons.info_outline, color: cs.primary, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'At the scheduled time, the app will generate the file and open the native share sheet so you can email it.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}
