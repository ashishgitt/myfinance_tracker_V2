import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

/// Fix 2: Proper auth state management — no infinite loop.
/// _isAuthenticated is set to true on success and only reset
/// when the lifecycle observer triggers it externally.
class AppLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const AppLockScreen({super.key, required this.onAuthenticated});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _auth = LocalAuthentication();
  bool _isAuthenticating = false;
  bool _authenticated = false; // Fix 2: guard flag
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    // Fix 2: Never re-trigger if already authenticated in this session
    if (_isAuthenticating || _authenticated) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final supported = await _auth.canCheckBiometrics ||
          await _auth.isDeviceSupported();

      if (!supported) {
        // No biometric hardware — unlock immediately
        if (mounted) {
          _authenticated = true;
          widget.onAuthenticated();
        }
        return;
      }

      final ok = await _auth.authenticate(
        localizedReason: 'Authenticate to open MyFinance Tracker',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,   // prevents multiple prompts
          sensitiveTransaction: true,
        ),
      );

      if (mounted && ok) {
        _authenticated = true; // Fix 2: set guard BEFORE calling callback
        widget.onAuthenticated();
      } else if (mounted && !ok) {
        setState(() =>
            _errorMessage = 'Authentication failed. Tap Try Again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error: ${e.toString().split('\n').first}');
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
                Text('Authenticate to continue',
                    style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 40),
                if (_isAuthenticating)
                  Column(children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text('Waiting for authentication…',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ])
                else
                  Icon(Icons.fingerprint, size: 64, color: cs.primary),
                const SizedBox(height: 12),
                if (!_isAuthenticating)
                  Text('Use fingerprint or face unlock',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_errorMessage!,
                        style: TextStyle(color: cs.onErrorContainer),
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
                        minimumSize: const Size(200, 48)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
