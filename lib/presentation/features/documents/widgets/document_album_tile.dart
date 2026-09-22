import 'package:flutter/material.dart';

import '../../../../domain/entities/category.dart';

class DocumentAlbumTile extends StatelessWidget {
  final Category category;
  final int count;
  final VoidCallback onTap;

  const DocumentAlbumTile({
    super.key,
    required this.category,
    required this.count,
    required this.onTap,
  });

  String get label {
    final name = category.name.trim();

    if (name.isEmpty) {
      return 'Uncategorized';
    }

    // Keep the existing display style for ID Card.
    if (name.toLowerCase() == 'idcard') {
      return 'ID Card';
    }

    // Convert names such as:
    // receipt -> Receipt
    // vehicle -> Vehicle
    // travel -> Travel
    //
    // Also handles names such as:
    // id card -> Id card
    return name[0].toUpperCase() + name.substring(1);
  }

  IconData get icon {
    switch (category.name.toLowerCase()) {
      case 'receipt':
        return Icons.receipt_long_rounded;

      case 'idcard':
      case 'id card':
        return Icons.badge_rounded;

      case 'vehicle':
        return Icons.directions_car_rounded;

      case 'certificate':
        return Icons.workspace_premium_rounded;

      case 'warranty':
        return Icons.shield_rounded;

      case 'bill':
        return Icons.receipt_rounded;

      case 'travel':
        return Icons.flight_rounded;

      case 'other':
        return Icons.folder_rounded;

      default:
        // Custom user-created categories
        // don't have a predefined icon.
        return Icons.folder_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '$count ${count == 1 ? 'item' : 'items'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
