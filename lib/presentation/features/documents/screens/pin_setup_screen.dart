import 'package:flutter/material.dart';

import '../../../../data/services/app_lock_service.dart';
import '../widgets/authentication_errorcard.dart';
import '../widgets/authentictaion_card.dart';
import '../widgets/pinsetup_content.dart';
import '../widgets/security_header.dart';
import '../widgets/security_infocard.dart';

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

    final canAuthenticate = await _appLockService.canAuthenticateWithDevice();

    if (!mounted) return;

    setState(() {
      _hasExistingPin = hasPin;
      _isLoading = false;
    });

    if (!canAuthenticate) {
      setState(() {
        _errorText =
            'Device authentication is required. Set up fingerprint, face unlock, or a device PIN/password in your device settings first.';
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
            'Device authentication failed. Your security settings were not changed.';
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
      setState(() {
        _errorText = null;
      });
    }

    if (!_isConfirming && _pinController.text.length == 5) {
      setState(() {
        _isConfirming = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _confirmPinFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _savePin() async {
    if (_isSaving || _isAuthenticating) return;

    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    if (pin.length != 5) {
      setState(() {
        _errorText = 'Enter a 5-digit PIN.';
      });
      return;
    }

    if (confirmPin.length != 5) {
      setState(() {
        _errorText = 'Confirm your 5-digit PIN.';
      });
      return;
    }

    if (pin != confirmPin) {
      setState(() {
        _errorText = 'The PINs do not match.';
      });
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
        _errorText = 'Could not save your PIN. Please try again.';
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
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    final isChangingPin = _hasExistingPin;

    final deviceAuthUnavailable =
        _errorText != null &&
        !_isSaving &&
        !_isAuthenticating &&
        _pinController.text.isEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: Text(isChangingPin ? 'Change PIN' : 'Set up PIN')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            SecurityHeader(isChangingPin: isChangingPin),

            const SizedBox(height: 24),

            if (_isAuthenticating)
              AuthenticationCard(colorScheme: colorScheme)
            else if (deviceAuthUnavailable)
              AuthenticationErrorCard(
                message: _errorText!,
                onRetry: _authenticateForSecurityChange,
              )
            else
              PinSetupContent(
                isChangingPin: isChangingPin,
                pinController: _pinController,
                confirmPinController: _confirmPinController,
                pinFocusNode: _pinFocusNode,
                confirmPinFocusNode: _confirmPinFocusNode,
                obscurePin: _obscurePin,
                obscureConfirmPin: _obscureConfirmPin,
                isConfirming: _isConfirming,
                isSaving: _isSaving,
                errorText: _errorText,
                onTogglePinVisibility: () {
                  setState(() {
                    _obscurePin = !_obscurePin;
                  });
                },
                onToggleConfirmVisibility: () {
                  setState(() {
                    _obscureConfirmPin = !_obscureConfirmPin;
                  });
                },
                onSave: _savePin,
              ),

            const SizedBox(height: 24),

            SecurityInfoCard(colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }
}

