import 'package:flutter/material.dart';

import '../../../../domain/entities/category.dart';

class CategoryChip extends StatelessWidget {
  final Category? category;
  final bool selected;
  final VoidCallback onSelected;

  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  String get label {
    if (category == null) {
      return 'All';
    }

    return category!.name;
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}