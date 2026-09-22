import 'package:flutter/material.dart';

class EmptyDocumentsView extends StatelessWidget {
  final VoidCallback onAddDocument;

  const EmptyDocumentsView({
    super.key,
    required this.onAddDocument,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 72,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
            const SizedBox(height: 20),
            Text(
              'No documents yet',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first document to get started.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddDocument,
              icon: const Icon(Icons.add),
              label: const Text('Add Document'),
            ),
          ],
        ),
      ),
    );
  }
}