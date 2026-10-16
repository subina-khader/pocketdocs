import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/entities/category.dart';
import '../providers/document_provider.dart';
class CategoryDialog extends StatefulWidget {
  final Category? category;

  const CategoryDialog({this.category});

  @override
  State<CategoryDialog> createState() => CategoryDialogState();
}

class CategoryDialogState extends State<CategoryDialog> {
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


