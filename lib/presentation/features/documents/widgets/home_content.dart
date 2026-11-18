import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/document_provider.dart';
import '../screens/category_management_screen.dart';
import '../screens/document_details_screen.dart';
import '../screens/folder_documents_screen.dart';
import '../screens/folder_management_screen.dart';
import 'document_list_tile.dart';
import 'emptyhome.dart';
import 'folder_list_tile.dart';
class HomeContent extends StatelessWidget {
  const HomeContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();
    final docs = provider.allDocuments;
    final unorganizedDocuments = docs
        .where((document) => document.folderId == null)
        .toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: provider.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PocketDocs',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Keep everything you need in one place.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FolderManagementScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(21),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.folder_copy_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // CATEGORIES
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                            const CategoryManagementScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(21),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.category_rounded,
                          color: Theme.of(context)
                              .colorScheme
                              .secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(.18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [


                        Row(
                          children: [
                            Text(
                              '${provider.documentCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width:15,),
                            Text(
                              provider.documentCount == 1
                                  ? 'document stored'
                                  : 'documents stored',
                              style: TextStyle(
                                color: Colors.white.withOpacity(.82),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.16),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          '100% Offline',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (provider.folders.isNotEmpty) ...[
              const SizedBox(height: 26),

              const Text(
                'YOUR FOLDERS',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: .4,
                ),
              ),

              const SizedBox(height: 12),

              ...provider.folders.map(
                    (folder) {
                  final count = docs
                      .where(
                        (document) =>
                    document.folderId == folder.id,
                  )
                      .length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FolderListTile(
                      folder: folder,
                      documentCount: count,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                FolderDocumentsScreen(
                                  folder: folder,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 26),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'YOUR DOCUMENTS',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: .4,
                    ),
                  ),
                ),
                Text(
                  '${unorganizedDocuments.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (docs.isEmpty)
              EmptyHome()
            else
              ...unorganizedDocuments.map(
                    (document) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DocumentListTile(
                    document: document,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DocumentDetailsScreen(document: document),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
