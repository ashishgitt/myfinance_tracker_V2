import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // App logo
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 56,
                  color: cs.primary),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('MyFinance Tracker',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text('Version $_version (build $_buildNumber)',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          const SizedBox(height: 32),
          _infoTile(context, Icons.person_outline,
              'Developer', 'Ashish Khandelwal'),
          _infoTile(context, Icons.description_outlined,
              'Description',
              'A fully offline personal finance tracker to manage expenses, budgets, savings goals and debts — all on your device.'),
          _infoTile(context, Icons.code_outlined,
              'Tech Stack',
              'Flutter • SQLite (sqflite) • Material Design 3 • Provider'),
          _infoTile(context, Icons.lock_outline,
              'Privacy',
              'All data is stored locally on your device. No internet connection, no cloud, no tracking.'),
          const SizedBox(height: 24),
          // Social placeholders
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text('Connect',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                              fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.link, size: 16),
                        label: const Text('LinkedIn'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.code, size: 16),
                        label: const Text('GitHub'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Made with ❤️ in Flutter',
                style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(BuildContext ctx, IconData icon,
      String label, String value) {
    final cs = Theme.of(ctx).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13)),
        subtitle: Text(value),
        isThreeLine: value.length > 60,
      ),
    );
  }
}
