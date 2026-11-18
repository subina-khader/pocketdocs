import 'package:flutter/material.dart';
class DocumentPlaceholder extends StatelessWidget {
  final IconData icon;
  final String? label;

  const DocumentPlaceholder({required this.icon, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary),
          if (label != null) ...[
            const SizedBox(height: 6),
            Text(label!, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}
