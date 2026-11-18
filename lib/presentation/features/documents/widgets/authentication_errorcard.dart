import 'package:flutter/material.dart';



class AuthenticationErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AuthenticationErrorCard({
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
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: colorScheme.onErrorContainer),
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
              icon: const Icon(Icons.fingerprint_rounded, size: 20),
              label: const Text('Try again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onErrorContainer,
                side: BorderSide(
                  color: colorScheme.onErrorContainer.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
