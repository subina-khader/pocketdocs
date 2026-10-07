import 'package:flutter/material.dart';

import '../../../../data/services/app_lock_service.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _confirmPinFocusNode = FocusNode();

  final AppLockService _appLockService = AppLockService();

  bool _isLoading = true;
  bool _isAuthenticating = false;
  bool _isConfirming = false;
  bool _isSaving = false;
  bool _hasExistingPin = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_onPinChanged);
    _confirmPinController.addListener(_onPinChanged);
    _prepareScreen();
  }

  Future<void> _prepareScreen() async {
    final hasPin = await _appLockService.hasPin();
    final canAuthenticate =
    await _appLockService.canAuthenticateWithDevice();

    if (!mounted) return;

    setState(() {
      _hasExistingPin = hasPin;
      _isLoading = false;
    });

    if (!canAuthenticate) {
      setState(() {
        _errorText =
        'Device authentication required. Set up a fingerprint, face unlock, or device PIN/password in your device settings before creating or changing a PocketDocs PIN.';
      });
      return;
    }

    await _authenticateForSecurityChange();
  }

  Future<void> _authenticateForSecurityChange() async {
    if (_isAuthenticating || !mounted) return;

    setState(() {
      _isAuthenticating = true;
      _errorText = null;
    });

    final authenticated = await _appLockService.authenticateWithDevice(
      localizedReason: 'Authenticate to change PocketDocs security settings',
    );

    if (!mounted) return;

    if (!authenticated) {
      setState(() {
        _isAuthenticating = false;
        _errorText =
        'Device authentication failed. Your PocketDocs security settings were not changed.';
      });
      return;
    }

    setState(() {
      _isAuthenticating = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pinFocusNode.requestFocus();
      }
    });
  }

  void _onPinChanged() {
    if (_errorText != null && !_isAuthenticating) {
      setState(() => _errorText = null);
    }

    if (!_isConfirming && _pinController.text.length == 5) {
      setState(() => _isConfirming = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _confirmPinFocusNode.requestFocus();
      });
    }
  }

  Future<void> _savePin() async {
    if (_isSaving || _isAuthenticating) return;

    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    if (pin.length != 5) {
      setState(() => _errorText = 'Enter a new 5-digit PIN.');
      return;
    }

    if (confirmPin.length != 5) {
      setState(() => _errorText = 'Confirm your new 5-digit PIN.');
      return;
    }

    if (pin != confirmPin) {
      setState(() => _errorText = 'PINs do not match.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      await _appLockService.enablePinLock(pin);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = 'Could not save PIN. Please try again.';
      });
    }
  }

  Future<void> _disablePin() async {
    if (_isSaving || _isAuthenticating) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable PocketDocs PIN?'),
        content: const Text(
          'PocketDocs will no longer use a PIN to unlock the app. You can enable another App Lock method from Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      await _appLockService.disableLock();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = 'Could not disable PIN. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _pinFocusNode.dispose();
    _confirmPinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isChangingPin = _hasExistingPin;
    final deviceAuthFailedOrUnavailable = _errorText != null &&
        !_isSaving &&
        !_isAuthenticating &&
        _pinController.text.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isChangingPin ? 'Change PIN' : 'Set up PIN'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Container(
              width: 68,
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isChangingPin ? Icons.lock_reset_rounded : Icons.pin_outlined,
                size: 32,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isChangingPin
                  ? 'Change your PocketDocs PIN'
                  : 'Create a PocketDocs PIN',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isChangingPin
                  ? 'Your device authentication has been verified. Create and confirm your new PIN.'
                  : 'Your device authentication has been verified. Choose a 5-digit PIN for unlocking PocketDocs.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            if (_isAuthenticating) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Text(
                'Waiting for device authentication...',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ] else if (deviceAuthFailedOrUnavailable) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: colorScheme.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorText!,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _authenticateForSecurityChange,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Try device authentication again'),
              ),
            ] else ...[
              const Text(
                'NEW PIN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 8),
              _PinField(
                controller: _pinController,
                focusNode: _pinFocusNode,
                obscureText: _obscurePin,
                enabled: !_isSaving,
                hintText: 'Enter PIN',
                onSubmitted: (_) {
                  if (_pinController.text.length == 5) {
                    _confirmPinFocusNode.requestFocus();
                  }
                },
                onToggleVisibility: () {
                  setState(() => _obscurePin = !_obscurePin);
                },
              ),
              if (_isConfirming) ...[
                const SizedBox(height: 16),
                const Text(
                  'CONFIRM PIN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 8),
                _PinField(
                  controller: _confirmPinController,
                  focusNode: _confirmPinFocusNode,
                  obscureText: _obscureConfirmPin,
                  enabled: !_isSaving,
                  hintText: 'Confirm PIN',
                  onSubmitted: (_) => _savePin(),
                  onToggleVisibility: () {
                    setState(
                          () => _obscureConfirmPin = !_obscureConfirmPin,
                    );
                  },
                ),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isSaving ? null : _savePin,
                  child: _isSaving
                      ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                      : Text(
                    isChangingPin ? 'Change PIN' : 'Enable PIN Lock',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (isChangingPin) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: _isSaving ? null : _disablePin,
                    child: const Text('Disable PocketDocs PIN'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Only one App Lock method is active at a time. Device authentication is required to change security settings.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscureText;
  final bool enabled;
  final String hintText;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onToggleVisibility;

  const _PinField({
    required this.controller,
    required this.focusNode,
    required this.obscureText,
    required this.enabled,
    required this.hintText,
    required this.onSubmitted,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      maxLength: 5,
      onSubmitted: onSubmitted,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 8,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        counterText: '',
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        suffixIcon: IconButton(
          onPressed: enabled ? onToggleVisibility : null,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    );
  }
}
