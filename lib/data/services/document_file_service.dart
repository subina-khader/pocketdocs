

import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'encryption_service.dart';
import 'file_storage_service.dart';
import 'image_compression_service.dart';

class DocumentFileService {
  final FileStorageService fileStorageService;
  final ImageCompressionService imageCompressionService;
  final EncryptionService encryptionService;

  DocumentFileService({
    required this.fileStorageService,
    required this.imageCompressionService,
    required this.encryptionService,
  });

  Future<String> processAndSave({
    required File sourceFile,
    required bool isPdf,
  }) async {
    File? processedFile;

    try {
      if (isPdf) {
        processedFile = sourceFile;
      } else {
        processedFile = await imageCompressionService.compressImage(
          sourceFile,
        );
      }

      final bytes = await processedFile.readAsBytes();

      final encryptedBytes = await encryptionService.encryptBytes(
        Uint8List.fromList(bytes),
      );

      return await fileStorageService.saveEncryptedBytes(
        encryptedBytes: encryptedBytes,
        isPdf: isPdf,
        originalExtension: '.enc',
      );
    } finally {
      if (!isPdf &&
          processedFile != null &&
          processedFile.path != sourceFile.path) {
        try {
          if (await processedFile.exists()) {
            await processedFile.delete();
          }
        } catch (_) {}
      }
    }
  }

  Future<Uint8List> decryptFile(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileSystemException(
        'Document file not found.',
        filePath,
      );
    }

    final bytes = await file.readAsBytes();

    // Legacy PocketDocs files were stored unencrypted.
    // New files use the .enc extension.
    if (path.extension(filePath).toLowerCase() != '.enc') {
      return Uint8List.fromList(bytes);
    }

    return encryptionService.decryptBytes(
      Uint8List.fromList(bytes),
    );
  }

  Future<void> deleteFile(String filePath) {
    return fileStorageService.deleteFile(filePath);
  }
}