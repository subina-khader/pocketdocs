
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/entities/document.dart';
import '../../../../domain/entities/folder.dart';
import '../providers/document_provider.dart';

class FolderDocumentSelectionScreen extends StatefulWidget {
final Folder folder;

const FolderDocumentSelectionScreen({
super.key,
required this.folder,
});

@override
State<FolderDocumentSelectionScreen> createState() =>
_FolderDocumentSelectionScreenState();
}

class _FolderDocumentSelectionScreenState
extends State<FolderDocumentSelectionScreen> {
late Set<int> _selectedDocumentIds;

bool _isSaving = false;

@override
void initState() {
super.initState();

final provider = context.read<DocumentProvider>();

_selectedDocumentIds = provider.allDocuments
    .where(
(document) =>
document.folderId == widget.folder.id &&
document.id != null,
)
    .map((document) => document.id!)
    .toSet();
}

void _toggleDocument(Document document) {
if (document.id == null) {
return;
}

setState(() {
if (_selectedDocumentIds.contains(document.id)) {
_selectedDocumentIds.remove(document.id);
} else {
_selectedDocumentIds.add(document.id!);
}
});
}

Future<void> _save() async {
if (_isSaving) {
return;
}

setState(() {
_isSaving = true;
});

final provider = context.read<DocumentProvider>();

final success = await provider.updateFolderDocuments(
widget.folder.id!,
_selectedDocumentIds,
);

if (!mounted) {
return;
}

setState(() {
_isSaving = false;
});

if (success) {
Navigator.of(context).pop();

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Folder documents updated.'),
),
);
} else {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Could not update folder documents.'),
),
);
}
}

Widget _buildDocumentCard(
BuildContext context,
Document document,
) {
final isSelected =
document.id != null &&
_selectedDocumentIds.contains(document.id);

return GestureDetector(
onTap: () => _toggleDocument(document),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(
child: Stack(
children: [
Container(
width: double.infinity,
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(14),
border: Border.all(
color: isSelected
? Theme.of(context).colorScheme.primary
    : Theme.of(context)
    .colorScheme
    .outlineVariant,
width: isSelected ? 2 : 1,
),
color: Theme.of(context)
    .colorScheme
    .surfaceContainerHighest,
),
clipBehavior: Clip.antiAlias,
child: _buildPreview(document),
),

// Selected indicator
Positioned(
top: 8,
right: 8,
child: AnimatedContainer(
duration: const Duration(milliseconds: 150),
width: 28,
height: 28,
decoration: BoxDecoration(
color: isSelected
? Theme.of(context).colorScheme.primary
    : Theme.of(context)
    .colorScheme
    .surface
    .withValues(alpha: 0.9),
shape: BoxShape.circle,
border: Border.all(
color: isSelected
? Theme.of(context)
    .colorScheme
    .primary
    : Theme.of(context)
    .colorScheme
    .outline,
),
),
child: Icon(
isSelected
? Icons.check_rounded
    : Icons.add_rounded,
size: 18,
color: isSelected
? Theme.of(context).colorScheme.onPrimary
    : Theme.of(context)
    .colorScheme
    .onSurfaceVariant,
),
),
),
],
),
),

const SizedBox(height: 7),

Text(
document.title,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
),
),
],
),
);
}

Widget _buildPreview(Document document) {
switch (document.fileType) {
case DocumentType.image:
final file = File(document.filePath);

if (file.existsSync()) {
return Image.file(
file,
width: double.infinity,
height: double.infinity,
fit: BoxFit.cover,
errorBuilder: (_, __, ___) {
return const _DocumentPlaceholder(
icon: Icons.broken_image_outlined,
);
},
);
}

return const _DocumentPlaceholder(
icon: Icons.broken_image_outlined,
);

case DocumentType.pdf:
return const _DocumentPlaceholder(
icon: Icons.picture_as_pdf_rounded,
label: 'PDF',
);
}
}

@override
Widget build(BuildContext context) {
final provider = context.watch<DocumentProvider>();
final documents = provider.allDocuments;

return Scaffold(
appBar: AppBar(
title: const Text('Select Documents'),
actions: [
if (_isSaving)
const Padding(
padding: EdgeInsets.symmetric(horizontal: 16),
child: Center(
child: SizedBox(
width: 22,
height: 22,
child: CircularProgressIndicator(
strokeWidth: 2,
),
),
),
)
else
TextButton(
onPressed: _save,
child: const Text('Save'),
),
],
),
body: documents.isEmpty
? const Center(
child: Text('No documents available.'),
)
    : GridView.builder(
padding: const EdgeInsets.fromLTRB(
16,
16,
16,
30,
),
gridDelegate:
const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 3,
crossAxisSpacing: 10,
mainAxisSpacing: 16,
childAspectRatio: 0.68,
),
itemCount: documents.length,
itemBuilder: (context, index) {
final document = documents[index];

return _buildDocumentCard(
context,
document,
);
},
),
);
}
}

class _DocumentPlaceholder extends StatelessWidget {
final IconData icon;
final String? label;

const _DocumentPlaceholder({
required this.icon,
this.label,
});

@override
Widget build(BuildContext context) {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
icon,
size: 38,
color: Theme.of(context)
    .colorScheme
    .primary,
),
if (label != null) ...[
const SizedBox(height: 6),
Text(
label!,
style: const TextStyle(
fontWeight: FontWeight.w700,
),
),
],
],
),
);
}
}
