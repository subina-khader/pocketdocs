import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

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