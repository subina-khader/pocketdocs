import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';

class FileStorageService {
  final Uuid uuid;

  FileStorageService({
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  Future<Directory> _getDocumentsDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      throw FileStorageException(
        'Unable to access application storage.',
      );
    }
  }

  Future<Directory> _getStorageDirectory({
    required bool isPdf,
  }) async {
    final appDirectory = await _getDocumentsDirectory();

    final folderName = isPdf
        ? AppConstants.pdfsFolder
        : AppConstants.imagesFolder;

    final directory = Directory(
      path.join(appDirectory.path, folderName),
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<String> saveFile({
    required File sourceFile,
    required bool isPdf,
  }) async {
    try {
      final directory = await _getStorageDirectory(
        isPdf: isPdf,
      );

      final extension = path.extension(sourceFile.path);

      final uniqueFileName =
          '${uuid.v4()}$extension';

      final destinationPath = path.join(
        directory.path,
        uniqueFileName,
      );

      final savedFile = await sourceFile.copy(
        destinationPath,
      );

      return savedFile.path;
    } catch (e) {
      throw FileStorageException(
        'Failed to save file: $e',
      );
    }
  }

  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw FileStorageException(
        'Failed to delete file: $e',
      );
    }
  }

  Future<bool> fileExists(String filePath) async {
    return File(filePath).exists();
  }
}