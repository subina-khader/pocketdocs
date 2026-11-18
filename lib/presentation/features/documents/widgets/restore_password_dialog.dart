import 'package:flutter/material.dart';

class RestorePasswordDialog extends StatefulWidget {
  const RestorePasswordDialog();

  @override
  State<RestorePasswordDialog> createState() =>
      RestorePasswordDialogState();
}

class RestorePasswordDialogState
    extends State<RestorePasswordDialog> {
  final TextEditingController _passwordController =
  TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _restore() {
    final password = _passwordController.text;

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the backup password.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Enter backup password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter the password used when this backup was created.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofocus: true,
            onSubmitted: (_) => _restore(),
            decoration: InputDecoration(
              labelText: 'Backup password',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _restore,
          child: const Text('Restore'),
        ),
      ],
    );
  }
}
