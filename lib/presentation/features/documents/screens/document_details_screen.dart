import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../domain/entities/document.dart';
import '../providers/document_provider.dart';
import 'add_document_screen.dart';

class DocumentDetailsScreen extends StatelessWidget {
  final Document document;

  const DocumentDetailsScreen({super.key, required this.document});

  // ------------------------------------------------------------
  // SHARE
  // ------------------------------------------------------------

  Future<void> _share(BuildContext context) async {
    try {
      await Share.shareXFiles([XFile(document.filePath)], text: document.title);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to share document: $e')));
    }
  }

  // ------------------------------------------------------------
  // DOWNLOAD / SAVE
  // ------------------------------------------------------------

  Future<void> _download(BuildContext context) async {
    try {
      final file = File(document.filePath);

      if (!await file.exists()) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document file not found.')),
        );

        return;
      }

      final extension = _getExtension(document.filePath);
      final fileName = _getFileNameWithoutExtension(document.filePath);

      if (document.fileType == DocumentType.pdf) {
        // PDF → Downloads/PocketDocs
        await FileSaver.instance.saveToDownloads(
          name: fileName,
          filePath: document.filePath,
          fileExtension: extension.isEmpty ? 'pdf' : extension,
          mimeType: MimeType.pdf,
          subfolder: 'PocketDocs',
        );
      } else {
        // Image → Gallery / Pictures/PocketDocs
        final mimeType = _getImageMimeType(extension);

        await FileSaver.instance.saveToGallery(
          name: fileName,
          filePath: document.filePath,
          fileExtension: extension.isEmpty ? 'jpg' : extension,
          mimeType: mimeType,
          album: 'PocketDocs',
        );
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            document.fileType == DocumentType.pdf
                ? 'Saved to Downloads/PocketDocs'
                : 'Saved to PocketDocs album',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      print('$e');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save document: $e')));
    }
  }

  String _getExtension(String path) {
    final fileName = path.split(Platform.pathSeparator).last;

    final dotIndex = fileName.lastIndexOf('.');

    if (dotIndex == -1) {
      return '';
    }

    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  String _getFileNameWithoutExtension(String path) {
    final fileName = path.split(Platform.pathSeparator).last;

    final dotIndex = fileName.lastIndexOf('.');

    if (dotIndex == -1) {
      return fileName;
    }

    return fileName.substring(0, dotIndex);
  }

  MimeType _getImageMimeType(String extension) {
    switch (extension) {
      case 'png':
        return MimeType.png;

      case 'webp':
        return MimeType.webp;

      case 'gif':
        return MimeType.gif;

      case 'heic':
        return MimeType.heic;

      case 'heif':
        return MimeType.heif;

      case 'avif':
        return MimeType.avif;

      case 'jpeg':
      case 'jpg':
      default:
        return MimeType.jpeg;
    }
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('“${document.title}” will be removed from PocketDocs.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    if (document.id == null) {
      return;
    }

    final success = await context.read<DocumentProvider>().deleteDocument(
      document.id!,
    );

    if (!context.mounted) {
      return;
    }

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete document.')),
      );
    }
  }

  // ------------------------------------------------------------
  // EDIT
  // ------------------------------------------------------------

  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddDocumentScreen(document: document)),
    );

    if (!context.mounted) {
      return;
    }

    Navigator.pop(context, true);
  }

  // ------------------------------------------------------------
  // FULL SCREEN IMAGE
  // ------------------------------------------------------------

  void _openFullScreenImage(BuildContext context) {
    if (document.fileType != DocumentType.image) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          imagePath: document.filePath,
          title: document.title,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();

    final categoryName =
        provider.categoryNameForId(document.categoryId) ?? 'Uncategorized';

    return Scaffold(
      appBar: AppBar(title: const Text('Document')),
      body: SafeArea(
        child: Column(
          children: [
            // ------------------------------------------------------
            // PREVIEW
            // ------------------------------------------------------

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _buildPreview(context),
              ),
            ),

            // ------------------------------------------------------
            // TITLE + CATEGORY
            // ------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // TITLE
                  Expanded(
                    child: Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // CATEGORY
                  Text(
                    categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // ------------------------------------------------------
            // BOTTOM ACTIONS
            // ------------------------------------------------------
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      onTap: () => _edit(context),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _ActionButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: () => _share(context),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _ActionButton(
                      icon: Icons.download_outlined,
                      label: 'Download',
                      onTap: () => _download(context),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      isDestructive: true,
                      onTap: () => _delete(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PREVIEW WIDGET
  // ------------------------------------------------------------

  Widget _buildPreview(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: document.fileType == DocumentType.pdf
          ? SfPdfViewer.file(File(document.filePath))
          : GestureDetector(
              onTap: () {
                _openFullScreenImage(context);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(document.filePath),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return const Center(
                        child: Icon(Icons.broken_image_outlined, size: 52),
                      );
                    },
                  ),

                  // Full screen hint
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fullscreen, color: Colors.white, size: 17),
                          SizedBox(width: 5),
                          Text(
                            'Full screen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ============================================================
// ACTION BUTTON
// ============================================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color: isDestructive
              ? color.withOpacity(.45)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FULL SCREEN IMAGE VIEWER
// ============================================================

class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;
  final String title;

  const FullScreenImageViewer({
    super.key,
    required this.imagePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 60,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
