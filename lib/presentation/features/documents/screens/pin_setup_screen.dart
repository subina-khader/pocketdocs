
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
localizedReason:
'Authenticate to change PocketDocs security settings',
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
child: CircularProgressIndicator(
color: colorScheme.primary,
),
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
appBar: AppBar(
title: Text(
isChangingPin ? 'Change PIN' : 'Set up PIN',
),
),
body: SafeArea(
child: ListView(
padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
keyboardDismissBehavior:
ScrollViewKeyboardDismissBehavior.onDrag,
children: [
_SecurityHeader(
isChangingPin: isChangingPin,
),

const SizedBox(height: 24),

if (_isAuthenticating)
_AuthenticationCard(
colorScheme: colorScheme,
)
else if (deviceAuthUnavailable)
_AuthenticationErrorCard(
message: _errorText!,
onRetry: _authenticateForSecurityChange,
)
else
_PinSetupContent(
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
_obscureConfirmPin =
!_obscureConfirmPin;
});
},
onSave: _savePin,
),

const SizedBox(height: 24),

_SecurityInfoCard(
colorScheme: colorScheme,
),
],
),
),
);
}
}

// -----------------------------------------------------------------------------
// HEADER
// -----------------------------------------------------------------------------

class _SecurityHeader extends StatelessWidget {
final bool isChangingPin;

const _SecurityHeader({
required this.isChangingPin,
});

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
width: 64,
height: 64,
decoration: BoxDecoration(
color: colorScheme.primaryContainer,
borderRadius: BorderRadius.circular(20),
),
child: Icon(
isChangingPin
? Icons.lock_reset_rounded
    : Icons.lock_outline_rounded,
size: 30,
color: colorScheme.onPrimaryContainer,
),
),

const SizedBox(height: 20),

Text(
isChangingPin
? 'Create a new PIN'
    : 'Protect your documents',
style: theme.textTheme.headlineSmall?.copyWith(
fontWeight: FontWeight.w800,
letterSpacing: -0.5,
),
),

const SizedBox(height: 8),

Text(
isChangingPin
? 'Choose a new 5-digit PIN to keep your PocketDocs private.'
    : 'Set a 5-digit PIN as an additional way to protect your documents.',
style: theme.textTheme.bodyMedium?.copyWith(
color: colorScheme.onSurfaceVariant,
height: 1.5,
),
),

const SizedBox(height: 16),

Container(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 9,
),
decoration: BoxDecoration(
color: colorScheme.surfaceContainerLow,
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: colorScheme.outlineVariant,
),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.verified_user_outlined,
size: 18,
color: colorScheme.primary,
),
const SizedBox(width: 8),
Text(
'Device authentication verified',
style: theme.textTheme.labelMedium?.copyWith(
color: colorScheme.onSurface,
fontWeight: FontWeight.w600,
),
),
],
),
),
],
);
}
}

// -----------------------------------------------------------------------------
// AUTHENTICATION CARD
// -----------------------------------------------------------------------------

class _AuthenticationCard extends StatelessWidget {
final ColorScheme colorScheme;

const _AuthenticationCard({
required this.colorScheme,
});

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);

return Container(
padding: const EdgeInsets.all(22),
decoration: BoxDecoration(
color: colorScheme.surfaceContainerLow,
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: colorScheme.outlineVariant,
),
),
child: Column(
children: [
Container(
width: 54,
height: 54,
decoration: BoxDecoration(
color: colorScheme.primaryContainer,
shape: BoxShape.circle,
),
child: Icon(
Icons.fingerprint_rounded,
size: 28,
color: colorScheme.onPrimaryContainer,
),
),

const SizedBox(height: 16),

Text(
'Verify your identity',
style: theme.textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.w700,
),
),

const SizedBox(height: 6),

Text(
'Waiting for your device authentication…',
textAlign: TextAlign.center,
style: theme.textTheme.bodySmall?.copyWith(
color: colorScheme.onSurfaceVariant,
height: 1.4,
),
),

const SizedBox(height: 18),

SizedBox(
width: 24,
height: 24,
child: CircularProgressIndicator(
strokeWidth: 2.5,
color: colorScheme.primary,
),
),
],
),
);
}
}

// -----------------------------------------------------------------------------
// AUTHENTICATION ERROR
// -----------------------------------------------------------------------------

class _AuthenticationErrorCard extends StatelessWidget {
final String message;
final VoidCallback onRetry;

const _AuthenticationErrorCard({
required this.message,
required this.onRetry,
});

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;

return Container(
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: colorScheme.errorContainer,
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: colorScheme.error.withValues(alpha: 0.18),
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(
Icons.shield_outlined,
color: colorScheme.onErrorContainer,
),
const SizedBox(width: 12),
Expanded(
child: Text(
'Authentication required',
style: theme.textTheme.titleSmall?.copyWith(
fontWeight: FontWeight.w700,
color: colorScheme.onErrorContainer,
),
),
),
],
),

const SizedBox(height: 10),

Text(
message,
style: theme.textTheme.bodySmall?.copyWith(
color: colorScheme.onErrorContainer,
height: 1.45,
),
),

const SizedBox(height: 16),

SizedBox(
width: double.infinity,
child: OutlinedButton.icon(
onPressed: onRetry,
icon: const Icon(
Icons.fingerprint_rounded,
size: 20,
),
label: const Text('Try again'),
style: OutlinedButton.styleFrom(
foregroundColor:
colorScheme.onErrorContainer,
side: BorderSide(
color: colorScheme.onErrorContainer
    .withValues(alpha: 0.35),
),
padding: const EdgeInsets.symmetric(
vertical: 13,
),
),
),
),
],
),
);
}
}

// -----------------------------------------------------------------------------
// PIN CONTENT
// -----------------------------------------------------------------------------

class _PinSetupContent extends StatelessWidget {
final bool isChangingPin;

final TextEditingController pinController;
final TextEditingController confirmPinController;

final FocusNode pinFocusNode;
final FocusNode confirmPinFocusNode;

final bool obscurePin;
final bool obscureConfirmPin;

final bool isConfirming;
final bool isSaving;

final String? errorText;

final VoidCallback onTogglePinVisibility;
final VoidCallback onToggleConfirmVisibility;
final VoidCallback onSave;

const _PinSetupContent({
required this.isChangingPin,
required this.pinController,
required this.confirmPinController,
required this.pinFocusNode,
required this.confirmPinFocusNode,
required this.obscurePin,
required this.obscureConfirmPin,
required this.isConfirming,
required this.isSaving,
required this.errorText,
required this.onTogglePinVisibility,
required this.onToggleConfirmVisibility,
required this.onSave,
});

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Your PIN',
style: theme.textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.w700,
),
),

const SizedBox(height: 6),

Text(
'Use five digits that are easy for you to remember.',
style: theme.textTheme.bodySmall?.copyWith(
color: colorScheme.onSurfaceVariant,
),
),

const SizedBox(height: 18),

_PinField(
controller: pinController,
focusNode: pinFocusNode,
obscureText: obscurePin,
enabled: !isSaving,
hintText: 'Enter 5-digit PIN',
onSubmitted: (_) {
if (pinController.text.length == 5) {
confirmPinFocusNode.requestFocus();
}
},
onToggleVisibility: onTogglePinVisibility,
),

if (isConfirming) ...[
const SizedBox(height: 16),

_PinField(
controller: confirmPinController,
focusNode: confirmPinFocusNode,
obscureText: obscureConfirmPin,
enabled: !isSaving,
hintText: 'Confirm your PIN',
onSubmitted: (_) => onSave(),
onToggleVisibility: onToggleConfirmVisibility,
),
],

if (errorText != null) ...[
const SizedBox(height: 12),

Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(
Icons.error_outline_rounded,
size: 18,
color: colorScheme.error,
),
const SizedBox(width: 8),
Expanded(
child: Text(
errorText!,
style: theme.textTheme.bodySmall?.copyWith(
color: colorScheme.error,
fontWeight: FontWeight.w600,
height: 1.35,
),
),
),
],
),
],

const SizedBox(height: 24),

SizedBox(
width: double.infinity,
height: 52,
child: FilledButton(
onPressed: isSaving ? null : onSave,
child: isSaving
? const SizedBox(
width: 21,
height: 21,
child: CircularProgressIndicator(
strokeWidth: 2.2,
),
)
    : Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
isChangingPin
? Icons.lock_reset_rounded
    : Icons.lock_outline_rounded,
size: 20,
),
const SizedBox(width: 8),
Text(
isChangingPin
? 'Change PIN'
    : 'Enable PIN Lock',
style: const TextStyle(
fontWeight: FontWeight.w700,
),
),
],
),
),
),
],
);
}
}

// -----------------------------------------------------------------------------
// PIN FIELD
// -----------------------------------------------------------------------------

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
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;

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
style: theme.textTheme.titleLarge?.copyWith(
fontWeight: FontWeight.w800,
letterSpacing: 9,
),
decoration: InputDecoration(
hintText: hintText,
hintStyle: theme.textTheme.bodyMedium?.copyWith(
color: colorScheme.onSurfaceVariant,
letterSpacing: 0,
fontWeight: FontWeight.w500,
),
counterText: '',
filled: true,
fillColor: colorScheme.surfaceContainerLow,
contentPadding: const EdgeInsets.symmetric(
horizontal: 18,
vertical: 17,
),
suffixIcon: IconButton(
tooltip: obscureText
? 'Show PIN'
    : 'Hide PIN',
onPressed: enabled
? onToggleVisibility
    : null,
icon: Icon(
obscureText
? Icons.visibility_outlined
    : Icons.visibility_off_outlined,
),
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide: BorderSide(
color: colorScheme.outlineVariant,
),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide: BorderSide(
color: colorScheme.primary,
width: 1.7,
),
),
disabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide: BorderSide(
color: colorScheme.outlineVariant,
),
),
),
);
}
}

// -----------------------------------------------------------------------------
// SECURITY INFO
// -----------------------------------------------------------------------------

class _SecurityInfoCard extends StatelessWidget {
final ColorScheme colorScheme;

const _SecurityInfoCard({
required this.colorScheme,
});

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);

return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: colorScheme.surfaceContainerLow,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: colorScheme.outlineVariant,
),
),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(
Icons.info_outline_rounded,
size: 20,
color: colorScheme.primary,
),
const SizedBox(width: 12),
Expanded(
child: Text(
'Only one App Lock method is active at a time. '
'Device authentication is required before changing '
'your security settings.',
style: theme.textTheme.bodySmall?.copyWith(
color: colorScheme.onSurfaceVariant,
height: 1.45,
),
),
),
],
),
);
}
}
