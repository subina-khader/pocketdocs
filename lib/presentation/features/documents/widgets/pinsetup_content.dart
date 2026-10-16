import 'package:flutter/material.dart';

class PinSetupContent extends StatelessWidget {
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

  const PinSetupContent({
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
              child: CircularProgressIndicator(strokeWidth: 2.2),
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
                  isChangingPin ? 'Change PIN' : 'Enable PIN Lock',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
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
          tooltip: obscureText ? 'Show PIN' : 'Hide PIN',
          onPressed: enabled ? onToggleVisibility : null,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.7),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    );
  }
}
