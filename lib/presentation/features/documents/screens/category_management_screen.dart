import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/document_provider.dart';
import '../../../../domain/entities/category.dart';
Future<Category?> showCategoryDialog(
    BuildContext context, {
      Category? category,
    }) async {
  return showDialog<Category>(
    context: context,
    builder: (_) {
      return _CategoryDialog(category: category);
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
          ? _EmptyCategories(
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

                return _CategoryTile(
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

// ============================================================
// ADD / EDIT CATEGORY DIALOG
// ============================================================

class _CategoryDialog extends StatefulWidget {
  final Category? category;

  const _CategoryDialog({this.category});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameController;

  late String _selectedEmoji;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.category?.name ?? '');

    _selectedEmoji = widget.category?.emoji ?? '📁';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name.')),
      );
      return;
    }

    final provider = context.read<DocumentProvider>();

    bool success;

    if (isEditing) {
      success = await provider.renameCategory(
        widget.category!.id!,
        name,
        _selectedEmoji,
      );
    } else {
      success = await provider.addCategory(name, _selectedEmoji);
    }

    if (!mounted) {
      return;
    }
    if (success) {
      final savedCategory = provider.categories.firstWhere(
            (item) =>
        item.name == name &&
            item.emoji == _selectedEmoji,
      );

      Navigator.pop(context, savedCategory);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Unable to update category.'
                : 'Unable to add category.',
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isEditing ? 'Edit Category' : 'Add Category',
      ),

      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // CATEGORY NAME
              // ------------------------------------------------

              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Category name',
                  hintText: 'e.g. Insurance',
                  prefixIcon: const Icon(
                    Icons.label_outline_rounded,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ------------------------------------------------
              // EMOJI
              // ------------------------------------------------

              const Text(
                'Choose an emoji',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                height: 250,
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: _categoryEmojis.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    // Exactly 5 rows
                    crossAxisCount: 5,

                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,

                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final emoji = _categoryEmojis[index];
                    final isSelected = _selectedEmoji == emoji;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedEmoji = emoji;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                            width: 1.5,
                          )
                              : null,
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(
                            fontSize: 24,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // PREVIEW
              // ------------------------------------------------

              Center(
                child: AnimatedBuilder(
                  animation: _nameController,
                  builder: (context, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedEmoji,
                            style: const TextStyle(
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _nameController.text.trim().isEmpty
                                  ? 'Category'
                                  : _nameController.text.trim(),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(
            isEditing ? 'Save' : 'Add',
          ),
        ),
      ],
);}}


// ============================================================
// CATEGORY TILE
// ============================================================

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(category.emoji, style: const TextStyle(fontSize: 25)),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),

            IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyCategories extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyCategories({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(height: 14),

            const Text(
              'No categories yet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 6),

            Text(
              'Create categories to organize your documents.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 18),

            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Category'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EMOJI OPTIONS
// ============================================================

const List<String> _categoryEmojis = [
  // 📄 Documents
  '📄',
  '📝',
  '📑',
  '📃',
  '📜',
  '🗒️',
  '🗂️',
  '📚',
  '📖',
  '🔖',

  // 💰 Finance
  '💰',
  '💵',
  '💳',
  '💸',
  '🧾',
  '🏦',
  '💎',
  '🪙',
  '📈',
  '📊',

  // 🪪 Identity
  '🪪',
  '👤',
  '🧑',
  '👨',
  '👩',
  '🆔',
  '🔐',
  '🔑',
  '🛂',
  '🌐',

  // 🚗 Vehicle
  '🚗',
  '🚕',
  '🚙',
  '🚘',
  '🏎️',
  '🚌',
  '🚐',
  '🏍️',
  '🚲',
  '🛞',

  // 🏠 Home & Property
  '🏠',
  '🏡',
  '🏢',
  '🏬',
  '🏗️',
  '🔑',
  '🛋️',
  '🛏️',
  '🏘️',
  '📍',

  // 🎓 Education
  '🎓',
  '📚',
  '📖',
  '✏️',
  '🖊️',
  '📝',
  '📐',
  '📏',
  '🔬',
  '🏫',

  // 💼 Work
  '💼',
  '👔',
  '🖥️',
  '💻',
  '📧',
  '📅',
  '📋',
  '📌',
  '🗃️',
  '🗄️',

  // 🏥 Medical
  '🏥',
  '💊',
  '💉',
  '🩺',
  '🩹',
  '❤️',
  '🫀',
  '🧬',
  '⚕️',
  '🚑',

  // ✈️ Travel
  '✈️',
  '🛫',
  '🛬',
  '🧳',
  '🏨',
  '🗺️',
  '🌍',
  '🌎',
  '🚆',
  '🚢',

  // 🛒 Shopping
  '🛒',
  '🛍️',
  '🏷️',
  '📦',
  '🎁',
  '👗',
  '👟',
  '👜',
  '💄',
  '🧴',

  // 🔧 Utilities
  '🔧',
  '🔨',
  '⚙️',
  '🔌',
  '💡',
  '🔋',
  '📱',
  '☎️',
  '🛠️',
  '🧰',

  // ❤️ General
  '📁',
  '📂',
  '⭐',
  '🌟',
  '❤️',
  '💙',
  '💚',
  '💜',
  '🧡',
  '🤍',
  '✨',
  '🔔',
  '📌',
  '📎',
  '🔒',
  '🔓',
];
