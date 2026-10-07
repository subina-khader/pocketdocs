import 'package:flutter/material.dart';

import '../../../../data/services/app_lock_service.dart';

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  final TextEditingController _pinController =
  TextEditingController();

  final FocusNode _pinFocusNode = FocusNode();

  final AppLockService _appLockService = AppLockService();

  String? _errorText;
  bool _isChecking = false;
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pinFocusNode.requestFocus();
      }
    });
  }

  Future<void> _unlock() async {
    final pin = _pinController.text;

    if (pin.length != 5) {
      setState(() {
        _errorText = 'Enter your 5-digit PIN.';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorText = null;
    });

    final isValid = await _appLockService.verifyPin(pin);

    if (!mounted) return;

    if (isValid) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isChecking = false;
      _errorText = 'Incorrect PIN. Please try again.';
      _pinController.clear();
    });

    _pinFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
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
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
              ),
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
                    'Enter your 5-digit PIN to access your documents.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 32),

                  TextField(
                    controller: _pinController,
                    focusNode: _pinFocusNode,
                    enabled: !_isChecking,
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 5,
                    textAlign: TextAlign.center,
                    onSubmitted: (_) => _unlock(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 9,
                    ),
                    decoration: InputDecoration(
                      hintText: '•••••',
                      counterText: '',
                      filled: true,
                      fillColor:
                      colorScheme.surfaceContainerLow,
                      suffixIcon: IconButton(
                        onPressed: _isChecking
                            ? null
                            : () {
                          setState(() {
                            _obscurePin = !_obscurePin;
                          });
                        },
                        icon: Icon(
                          _obscurePin
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  if (_errorText != null) ...[
                    const SizedBox(height: 10),
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

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed:
                      _isChecking ? null : _unlock,
                      child: _isChecking
                          ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                        ),
                      )
                          : const Text(
                        'Unlock',
                        style: TextStyle(
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