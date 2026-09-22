import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/entities/folder.dart';
import '../providers/document_provider.dart';
import '../widgets/document_list_tile.dart';
import 'document_details_screen.dart';

class FolderDocumentsScreen extends StatelessWidget {
  final Folder folder;

  const FolderDocumentsScreen({
    super.key,
    required this.folder,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();

    final documents = provider.allDocuments
        .where((document) => document.folderId == folder.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(folder.name),
      ),
      body: documents.isEmpty
          ? const Center(
        child: Text('No documents in this folder.'),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: documents.length,
        separatorBuilder: (_, __) =>
        const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final document = documents[index];

          return DocumentListTile(
            document: document,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      DocumentDetailsScreen(
                        document: document,
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}