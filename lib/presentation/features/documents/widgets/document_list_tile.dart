import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../domain/entities/document.dart';
import '../providers/document_provider.dart';
import 'document_image_preview.dart';
import 'document_preview.dart';

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

    final category = provider.categoryForId(document.categoryId);
    final categoryName = category?.name ?? 'Uncategorized';
    final categoryEmoji = category?.emoji ?? '📄';
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              DocumentPreview (document: document),

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

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          categoryEmoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

