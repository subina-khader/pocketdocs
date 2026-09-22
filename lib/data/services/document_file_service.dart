import 'dart:io';

import 'file_storage_service.dart';
import 'image_compression_service.dart';

class DocumentFileService {
  final FileStorageService fileStorageService;
  final ImageCompressionService imageCompressionService;

  DocumentFileService({
    required this.fileStorageService,
    required this.imageCompressionService,
  });

  Future<String> processAndSave({
    required File sourceFile,
    required bool isPdf,
  }) async {
    File fileToSave = sourceFile;

    if (!isPdf) {
      fileToSave = await imageCompressionService
          .compressImage(sourceFile);
    }

    return fileStorageService.saveFile(
      sourceFile: fileToSave,
      isPdf: isPdf,
    );
  }

  Future<void> deleteFile(String filePath) async {
    await fileStorageService.deleteFile(filePath);
  }
}