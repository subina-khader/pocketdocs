
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../domain/entities/document.dart';
import 'document_image_preview.dart';


class DocumentPreview  extends StatelessWidget {
  final Document document;

  const DocumentPreview ({
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    if (document.fileType == DocumentType.pdf) {
      return Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          Icons.picture_as_pdf_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 30,
        ),
      );
    }

    return DocumentImagePreview(
      document: document,
      width: 62,
      height: 62,
      borderRadius: BorderRadius.circular(15),
    );
  }
}
