import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../data/services/document_file_service.dart';
import '../../../../dependency_injection/injection_container.dart';
import '../../../../domain/entities/document.dart';

class DocumentImagePreview extends StatefulWidget {
  final Document document;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius borderRadius;

  const DocumentImagePreview({
    super.key,
    required this.document,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<DocumentImagePreview> createState() => _DocumentImagePreviewState();
}

class _DocumentImagePreviewState extends State<DocumentImagePreview> {
  late Future<Uint8List> _imageFuture;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant DocumentImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.document.filePath != widget.document.filePath) {
      _loadImage();
    }
  }

  void _loadImage() {
    _imageFuture = sl<DocumentFileService>().decryptFile(
      widget.document.filePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder(
            context,
            const Icon(Icons.image_outlined),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return _buildPlaceholder(
            context,
            const Icon(Icons.broken_image_outlined),
          );
        }

        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: Image.memory(
            snapshot.data!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) {
              return _buildPlaceholder(
                context,
                const Icon(Icons.broken_image_outlined),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(
      BuildContext context,
      Widget icon,
      ) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: widget.borderRadius,
      ),
      alignment: Alignment.center,
      child: IconTheme(
        data: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
          size: 26,
        ),
        child: icon,
      ),
    );
  }
}