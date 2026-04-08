import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// Feature 1: Google Sign-In / Continue locally screen
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authP = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: cs.primaryContainer, shape: BoxShape.circle),
                child: Icon(Icons.account_balance_wallet_rounded,
                    size: 64, color: cs.primary),
              ),
              const SizedBox(height: 32),
              Text('MyFinance Tracker',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Sign in to back up your data to the cloud,\nor continue offline.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 48),
              // Google Sign-In button
              if (authP.loading)
                const CircularProgressIndicator()
              else
                Column(children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ok =
                            await authP.signInWithGoogle();
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                                  content: Text(
                                      'Sign-in failed or cancelled')));
                        }
                      },
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Continue with Google'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 2,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => authP.skipAndContinue(),
                    child: Text('Skip for now — use locally',
                        style: TextStyle(color: cs.primary)),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline,
                          color: cs.primary, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Cloud sync requires Firebase setup. '
                          'The app works fully offline without signing in.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ]),
                  ),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}
