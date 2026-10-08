import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../domain/entities/document.dart';
import '../../features/documents/providers/document_provider.dart';
import '../../features/documents/widgets/document_image_preview.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;

  const DocumentCard({super.key, required this.document, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();

    final categoryName = provider.categoryNameForId(document.categoryId);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _DocumentPreview(document: document),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      categoryName ?? 'Uncategorized',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),




                  ],
                ),
              ),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  final Document document;

  const _DocumentPreview({required this.document});

  @override
  Widget build(BuildContext context) {
    if (document.fileType == DocumentType.pdf) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.picture_as_pdf, size: 32),
      );
    }

    return DocumentImagePreview(
      document: document,
      width: 64,
      height: 64,
      borderRadius: BorderRadius.circular(12),
    );
  }
}
