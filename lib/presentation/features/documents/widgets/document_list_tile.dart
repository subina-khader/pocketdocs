
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../domain/entities/document.dart';
import '../providers/document_provider.dart';

class DocumentListTile extends StatelessWidget {
final Document document;
final VoidCallback onTap;

const DocumentListTile({
super.key,
required this.document,
required this.onTap,
});

@override
Widget build(BuildContext context) {
final provider = context.watch<DocumentProvider>();

final categoryName =
provider.categoryNameForId(document.categoryId) ??
'Uncategorized';

return Card(
child: InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(20),
child: Padding(
padding: const EdgeInsets.all(12),
child: Row(
children: [
_Preview(document: document),

const SizedBox(width: 13),

Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
document.title,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 14,
fontWeight: FontWeight.w700,
),
),

const SizedBox(height: 5),

Text(
categoryName,
style: TextStyle(
fontSize: 12,
color: Theme.of(context)
    .colorScheme
    .primary,
fontWeight: FontWeight.w600,
),
),

const SizedBox(height: 4),

Text(
AppDateUtils.formatDate(
document.documentDate,
),
style: TextStyle(
fontSize: 11,
color: Theme.of(context)
    .colorScheme
    .onSurfaceVariant,
),
),
],
),
),

const Icon(
Icons.chevron_right_rounded,
),
],
),
),
),
);
}
}

class _Preview extends StatelessWidget {
final Document document;

const _Preview({
required this.document,
});

@override
Widget build(BuildContext context) {
if (document.fileType == DocumentType.pdf) {
return Container(
width: 62,
height: 62,
decoration: BoxDecoration(
color: Theme.of(context)
    .colorScheme
    .primaryContainer,
borderRadius: BorderRadius.circular(15),
),
child: Icon(
Icons.picture_as_pdf_rounded,
color: Theme.of(context).colorScheme.primary,
size: 30,
),
);
}

return ClipRRect(
borderRadius: BorderRadius.circular(15),
child: Image.file(
File(document.filePath),
width: 62,
height: 62,
fit: BoxFit.cover,
errorBuilder: (_, __, ___) => Container(
width: 62,
height: 62,
color: Theme.of(context)
    .colorScheme
    .primaryContainer,
child: const Icon(
Icons.image_not_supported_outlined,
),
),
),
);
}
}

