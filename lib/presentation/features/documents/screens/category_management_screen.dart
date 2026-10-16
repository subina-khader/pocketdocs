import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/document_provider.dart';
import '../../../../domain/entities/category.dart';
import '../widgets/category_dialog.dart';
import '../widgets/category_tile.dart';
Future<Category?> showCategoryDialog(
    BuildContext context, {
      Category? category,
    }) async {
  return showDialog<Category>(
    context: context,
    builder: (_) {
      return CategoryDialog(category: category);
    },
  );
}
class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'Add category',
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              showCategoryDialog(context);
            },
          ),
        ],
      ),
      body: provider.categories.isEmpty
          ? EmptyCategories(
              onAdd: () {
                showCategoryDialog(context);
              },
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              itemCount: provider.categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final category = provider.categories[index];

                return CategoryTile(
                  category: category,
                  onEdit: () {
                    showCategoryDialog(context, category: category);
                  },
                  onDelete: () {
                    _deleteCategory(context, category);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showCategoryDialog(context);
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }




  Future<void> _deleteCategory(BuildContext context, Category category) async {
    final provider = context.read<DocumentProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete category?'),
          content: Text(
            'Delete "${category.name}"?\n\n'
            'Documents in this category will not be deleted. '
            'They will simply become uncategorized.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final success = await provider.deleteCategory(category.id!);

    if (!context.mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete category.')),
      );
    }
  }
}

