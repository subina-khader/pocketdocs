import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../data/services/document_file_service.dart';
import '../../../../dependency_injection/injection_container.dart';
import '../../../../domain/entities/document.dart';
import '../providers/document_provider.dart';
import 'add_document_screen.dart';

class DocumentDetailsScreen extends StatelessWidget {
  final Document document;

  const DocumentDetailsScreen({
    super.key,
    required this.document,
  });

  // ------------------------------------------------------------
  // SHARE
  // ------------------------------------------------------------

  Future<void> _share(
      BuildContext context,
      ) async {
    await Share.shareXFiles(
      [
        XFile(document.filePath),
      ],
      text: document.title,
    );
  }

  // ------------------------------------------------------------
  // SAVE / DOWNLOAD
  // ------------------------------------------------------------

  Future<void> _save(
      BuildContext context,
      ) async {
    // Uses the platform share sheet so the
    // user can save/export the file.
    await Share.shareXFiles(
      [
        XFile(document.filePath),
      ],
      text: 'Save ${document.title}',
    );
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------

  Future<void> _delete(
      BuildContext context,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Delete document?',
        ),
        content: Text(
          '“${document.title}” will be removed from PocketDocs.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
                  context,
                  false,
                ),
            child:
            const Text('Cancel'),
          ),
          FilledButton(
            style:
            FilledButton.styleFrom(
              backgroundColor:
              Theme.of(context)
                  .colorScheme
                  .error,
            ),
            onPressed: () =>
                Navigator.pop(
                  context,
                  true,
                ),
            child:
            const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true ||
        !context.mounted) {
      return;
    }

    final success =
    await context
        .read<DocumentProvider>()
        .deleteDocument(
      document.id!,
    );

    if (!context.mounted) {
      return;
    }

    if (success) {
      Navigator.pop(
        context,
        true,
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to delete document.',
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Document',
        ),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () async {
              await Navigator.of(
                context,
              ).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AddDocumentScreen(
                        document: document,
                      ),
                ),
              );

              if (context.mounted) {
                Navigator.pop(
                  context,
                  true,
                );
              }
            },
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),
        ],
      ),
      body: ListView(
        padding:
        const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          30,
        ),
        children: [
          // ----------------------------------------------------
          // FILE PREVIEW
          // ----------------------------------------------------

          Container(
            height: 390,
            decoration:
            BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surface,
              borderRadius:
              BorderRadius.circular(
                24,
              ),
              border: Border.all(
                color: Theme.of(context)
                    .dividerColor,
              ),
            ),
            clipBehavior:
            Clip.antiAlias,
            child:
            document.fileType ==
                DocumentType.pdf
                ? SfPdfViewer.file(
              File(
                document.filePath,
              ),
            )
                : InteractiveViewer(
              minScale: .7,
              maxScale: 4,
              child:
              Image.file(
                File(
                  document.filePath,
                ),
                width:
                double.infinity,
                fit: BoxFit.contain,
                errorBuilder:
                    (
                    _,
                    __,
                    ___,
                    ) =>
                const Center(
                  child: Icon(
                    Icons
                        .broken_image_outlined,
                    size: 52,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ----------------------------------------------------
          // ACTION BUTTONS
          // ----------------------------------------------------

          Row(
            children: [
              Expanded(
                child:
                _ActionButton(
                  icon: Icons
                      .edit_outlined,
                  label: 'Edit',
                  onTap: () async {
                    await Navigator.of(
                      context,
                    ).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AddDocumentScreen(
                              document:
                              document,
                            ),
                      ),
                    );

                    if (context.mounted) {
                      Navigator.pop(
                        context,
                        true,
                      );
                    }
                  },
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                _ActionButton(
                  icon: Icons
                      .download_outlined,
                  label: 'Download',
                  onTap: () =>
                      _save(context),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                _ActionButton(
                  icon: Icons
                      .share_outlined,
                  label: 'Share',
                  onTap: () =>
                      _share(context),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 22,
          ),

          // ----------------------------------------------------
          // DOCUMENT DETAILS
          // ----------------------------------------------------

          const Text(
            'DOCUMENT DETAILS',
            style: TextStyle(
              fontWeight:
              FontWeight.w800,
              fontSize: 13,
              letterSpacing: .4,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Card(
            child: Padding(
              padding:
              const EdgeInsets.all(
                16,
              ),
              child:
              Consumer<DocumentProvider>(
                builder: (
                    context,
                    provider,
                    _,
                    ) {
                  final categoryName =
                  provider
                      .categoryNameForId(
                    document.categoryId,
                  );

                  return Column(
                    children: [
                      _InfoRow(
                        label: 'Title',
                        value:
                        document.title,
                      ),

                      _InfoRow(
                        label: 'Category',
                        value:
                        categoryName ??
                            'Uncategorized',
                      ),

                      _InfoRow(
                        label: 'File type',
                        value: document
                            .fileType ==
                            DocumentType
                                .pdf
                            ? 'PDF'
                            : 'Image',
                      ),

                      _InfoRow(
                        label:
                        'Document date',
                        value:
                        AppDateUtils
                            .formatDate(
                          document
                              .documentDate,
                        ),
                      ),

                      _InfoRow(
                        label: 'Created',
                        value:
                        AppDateUtils
                            .formatDate(
                          document
                              .createdAt,
                        ),
                        isLast: document
                            .notes ==
                            null ||
                            document.notes!
                                .isEmpty,
                      ),

                      if (document
                          .notes !=
                          null &&
                          document.notes!
                              .isNotEmpty)
                        _InfoRow(
                          label: 'Notes',
                          value:
                          document.notes!,
                          isLast: true,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ----------------------------------------------------
          // SHARE
          // ----------------------------------------------------

          OutlinedButton.icon(
            onPressed: () =>
                _share(context),
            icon: const Icon(
              Icons.share_outlined,
            ),
            label: const Text(
              'Share document',
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          // ----------------------------------------------------
          // DELETE
          // ----------------------------------------------------

          TextButton.icon(
            style:
            TextButton.styleFrom(
              foregroundColor:
              Theme.of(context)
                  .colorScheme
                  .error,
            ),
            onPressed: () =>
                _delete(context),
            icon: const Icon(
              Icons
                  .delete_outline_rounded,
            ),
            label: const Text(
              'Delete document',
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// ACTION BUTTON
// ------------------------------------------------------------

class _ActionButton
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 18,
      ),
      label: Text(label),
      style:
      OutlinedButton.styleFrom(
        padding:
        const EdgeInsets.symmetric(
          vertical: 12,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// INFO ROW
// ------------------------------------------------------------

class _InfoRow
    extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : 15,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
              const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}