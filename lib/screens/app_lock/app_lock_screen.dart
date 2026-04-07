import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const AppLockScreen({super.key, required this.onAuthenticated});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });
    try {
      final canAuth = await _auth.canCheckBiometrics ||
          await _auth.isDeviceSupported();
      if (!canAuth) {
        // No biometric — unlock immediately
        if (mounted) widget.onAuthenticated();
        return;
      }
      final didAuth = await _auth.authenticate(
        localizedReason:
            'Authenticate to open MyFinance Tracker',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
      if (mounted && didAuth) widget.onAuthenticated();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            'Authentication failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_outline_rounded,
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
                  'Authenticate to continue',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 40),
                if (_isAuthenticating)
                  const CircularProgressIndicator()
                else
                  Column(
                    children: [
                      Icon(Icons.fingerprint,
                          size: 56, color: cs.primary),
                      const SizedBox(height: 8),
                      Text('Use fingerprint or face unlock',
                          style: TextStyle(
                              color: cs.onSurfaceVariant)),
                    ],
                  ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_errorMessage!,
                        style:
                            TextStyle(color: cs.onErrorContainer),
                        textAlign: TextAlign.center),
                  ),
                ],
                const SizedBox(height: 32),
                if (!_isAuthenticating)
                  FilledButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: FilledButton.styleFrom(
                        minimumSize:
                            const Size(200, 48)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
