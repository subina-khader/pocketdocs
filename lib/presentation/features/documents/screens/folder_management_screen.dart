import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/entities/folder.dart';
import '../providers/document_provider.dart';
import 'folder_documents_screen.dart';

class FolderManagementScreen extends StatefulWidget {
  const FolderManagementScreen({super.key});

  @override
  State<FolderManagementScreen> createState() => _FolderManagementScreenState();
}

class _FolderManagementScreenState extends State<FolderManagementScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().loadFolders();
    });
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();

    final folderName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Folder'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Folder name',
              hintText: 'e.g. Personal Documents',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );


    if (folderName == null || folderName.isEmpty) {
      return;
    }

    if (!mounted) return;

    final success = await context.read<DocumentProvider>().addFolder(
      folderName,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not create folder.')));
    }
  }

  Future<void> _renameFolder(Folder folder) async {
    final controller = TextEditingController(text: folder.name);

    final folderName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Folder'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Folder name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );


    if (folderName == null || folderName.isEmpty) {
      return;
    }

    if (!mounted) return;

    await context.read<DocumentProvider>().renameFolder(folder.id!, folderName);
  }

  Future<void> _deleteFolder(Folder folder) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Folder?'),
          content: Text(
            'Delete "${folder.name}"?\n\n'
            'The documents inside this folder will not be deleted. '
            'They will simply become unassigned.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await context.read<DocumentProvider>().deleteFolder(folder.id!);
  }

  Future<void> _addDocumentsToFolder(Folder folder) async {
    final provider = context.read<DocumentProvider>();

    final selectedIds = <int>{};

    final result = await showDialog<List<int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final documents = provider.allDocuments;

            return AlertDialog(
              title: Text('Add to ${folder.name}'),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: documents.isEmpty
                    ? const Center(child: Text('No documents available.'))
                    : ListView.builder(
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          final document = documents[index];

                          if (document.id == null) {
                            return const SizedBox.shrink();
                          }

                          final isSelected = selectedIds.contains(document.id);

                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(
                              document.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              document.fileType.name.toUpperCase(),
                            ),
                            secondary: Icon(
                              document.folderId == folder.id
                                  ? Icons.folder_rounded
                                  : Icons.description_outlined,
                            ),
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedIds.add(document.id!);
                                } else {
                                  selectedIds.remove(document.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selectedIds.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context, selectedIds.toList());
                        },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || result.isEmpty || !mounted) {
      return;
    }

    final success = await provider.assignDocumentsToFolder(result, folder.id!);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.length} document(s) added to ${folder.name}.',
          ),
        ),
      );
    }
  }

  void _openFolder(Folder folder) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FolderDocumentsScreen(folder: folder)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Folders')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createFolder,
        child: const Icon(Icons.create_new_folder_rounded),
      ),
      body: provider.folders.isEmpty
          ? _EmptyFolders(onCreateFolder: _createFolder)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: provider.folders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final folder = provider.folders[index];

                final documentCount = provider.allDocuments
                    .where((document) => document.folderId == folder.id)
                    .length;

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.folder_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      folder.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '$documentCount '
                      '${documentCount == 1 ? 'document' : 'documents'}',
                    ),
                    onTap: () => _openFolder(folder),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'add':
                            _addDocumentsToFolder(folder);
                            break;

                          case 'rename':
                            _renameFolder(folder);
                            break;

                          case 'delete':
                            _deleteFolder(folder);
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'add',
                          child: Row(
                            children: [
                              Icon(Icons.add),
                              SizedBox(width: 12),
                              Text('Add documents'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 12),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline),
                              SizedBox(width: 12),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyFolders extends StatelessWidget {
  final VoidCallback onCreateFolder;

  const _EmptyFolders({required this.onCreateFolder});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No folders yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a folder to organize your documents.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreateFolder,
              icon: const Icon(Icons.create_new_folder_rounded),
              label: const Text('Create Folder'),
            ),
          ],
        ),
      ),
    );
  }
}
