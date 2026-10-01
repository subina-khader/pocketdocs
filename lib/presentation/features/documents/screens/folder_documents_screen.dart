
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/entities/folder.dart';
import '../providers/document_provider.dart';
import '../widgets/document_list_tile.dart';
import 'document_details_screen.dart';
import 'folder_document_selection_screen.dart';

class FolderDocumentsScreen extends StatelessWidget {
final Folder folder;

const FolderDocumentsScreen({
super.key,
required this.folder,
});

Future<void> _openDocumentSelection(
BuildContext context,
) async {
await Navigator.of(context).push(
MaterialPageRoute(
builder: (_) => FolderDocumentSelectionScreen(
folder: folder,
),
),
);
}

@override
Widget build(BuildContext context) {
final provider = context.watch<DocumentProvider>();

final documents = provider.allDocuments
    .where(
(document) => document.folderId == folder.id,
)
    .toList();

return Scaffold(
appBar: AppBar(
title: Text(folder.name),
actions: [
PopupMenuButton<String>(
onSelected: (value) {
if (value == 'select_documents') {
_openDocumentSelection(context);
}
},
itemBuilder: (context) => const [
PopupMenuItem(
value: 'select_documents',
child: Row(
children: [
Icon(Icons.library_add_check_rounded),
SizedBox(width: 12),
Text('Select documents'),
],
),
),
],
),
],
),
body: documents.isEmpty
? const Center(
child: Text(
'No documents in this folder.',
),
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
builder: (_) => DocumentDetailsScreen(
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
