import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../../data/services/document_file_service.dart';
import '../../../../dependency_injection/injection_container.dart';
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
  Future<Uint8List> _decryptDocument() async {
    final fileService = sl<DocumentFileService>();

    return fileService.decryptFile(
      document.filePath,
    );
  }
  Future<void> _share(BuildContext context) async {
    File? tempFile;

    try {
      final bytes = await _decryptDocument();

      final tempDirectory = await getTemporaryDirectory();

      final extension = document.fileType == DocumentType.pdf
          ? 'pdf'
          : 'jpg';

      tempFile = File(
        path.join(
          tempDirectory.path,
          '${document.id ?? DateTime.now().millisecondsSinceEpoch}.$extension',
        ),
      );

      await tempFile.writeAsBytes(
        bytes,
        flush: true,
      );

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: document.title,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to share document.'),
        ),
      );
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  // ------------------------------------------------------------
  // DOWNLOAD / SAVE
  // ------------------------------------------------------------

  Future<void> _download(BuildContext context) async {
    File? tempFile;

    try {
      final bytes = await _decryptDocument();

      final tempDirectory = await getTemporaryDirectory();

      final extension = document.fileType == DocumentType.pdf
          ? 'pdf'
          : 'jpg';

      final fileName = _getFileNameWithoutExtension(
        document.title,
      );

      tempFile = File(
        path.join(
          tempDirectory.path,
          '${DateTime.now().millisecondsSinceEpoch}.$extension',
        ),
      );

      await tempFile.writeAsBytes(
        bytes,
        flush: true,
      );

      if (document.fileType == DocumentType.pdf) {
        await FileSaver.instance.saveToDownloads(
          name: fileName,
          filePath: tempFile.path,
          fileExtension: extension,
          mimeType: MimeType.pdf,
          subfolder: 'PocketDocs',
        );
      } else {
        await FileSaver.instance.saveToGallery(
          name: fileName,
          filePath: tempFile.path,
          fileExtension: extension,
          mimeType: MimeType.jpeg,
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save document.'),
        ),
      );
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
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

  void _openFullScreenImage(
      BuildContext context,
      Uint8List bytes,
      ) {
    if (document.fileType != DocumentType.image) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          imageBytes: bytes,
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
      child: FutureBuilder<Uint8List>(
        future: _decryptDocument(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Icon(
                Icons.lock_outline_rounded,
                size: 52,
              ),
            );
          }

          final bytes = snapshot.data!;

          if (document.fileType == DocumentType.pdf) {
            return SfPdfViewer.memory(bytes);
          }

          return GestureDetector(
            onTap: () {
              _openFullScreenImage(
                context,
                bytes,
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 52,
                      ),
                    );
                  },
                ),

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
                        Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 17,
                        ),
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
          );
        },
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
  final Uint8List imageBytes;
  final String title;

  const FullScreenImageViewer({
    super.key,
    required this.imageBytes,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Image.memory(
            imageBytes,
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