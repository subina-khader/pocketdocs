import 'package:flutter/material.dart';

import '../../../../data/services/app_lock_service.dart';
import 'pin_unlock_screen.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final AppLockService _appLockService = AppLockService();

  bool _isAuthenticating = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating || !mounted) return;

    setState(() {
      _isAuthenticating = true;
      _errorText = null;
    });

    try {
      final lockType = await _appLockService.getLockType();

      if (!mounted) return;

      if (lockType == AppLockType.device) {
        final authenticated =
        await _appLockService.authenticateWithDevice();

        if (!mounted) return;

        if (authenticated) {
          _unlock();
        } else {
          setState(() {
            _errorText =
            'Authentication failed. Please try again.';
          });
        }

        return;
      }

      if (lockType == AppLockType.pin) {
        final unlocked = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => const PinUnlockScreen(),
            fullscreenDialog: true,
          ),
        );

        if (!mounted) return;

        if (unlocked == true) {
          _unlock();
        } else {
          setState(() {
            _errorText = 'Enter your PIN to continue.';
          });
        }

        return;
      }

      // No valid lock type.
      _unlock();
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _unlock() {
    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 36,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'PocketDocs is locked',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Authenticate to access your documents.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),

                  if (_errorText != null) ...[
                    const SizedBox(height: 16),

                    Text(
                      _errorText!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isAuthenticating
                          ? null
                          : _authenticate,
                      icon: _isAuthenticating
                          ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                        ),
                      )
                          : const Icon(Icons.lock_open_rounded),
                      label: Text(
                        _isAuthenticating
                            ? 'Authenticating...'
                            : 'Unlock PocketDocs',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}