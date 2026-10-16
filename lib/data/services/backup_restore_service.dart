import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../domain/entities/document.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/database_constants.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/repositories/folder_repository.dart';
import '../database/database_helper.dart';
import '../models/document_model.dart';
import 'backup_encryption_service.dart';
import 'document_file_service.dart';
import 'file_storage_service.dart';

class BackupRestoreService {
  static const String _format = 'pocketdocs';
  static const int _version = 2;

  final DatabaseHelper databaseHelper;
  final DocumentRepository documentRepository;
  final FolderRepository folderRepository;
  final CategoryRepository categoryRepository;
  final FileStorageService fileStorageService;
  final DocumentFileService documentFileService;
  final BackupEncryptionService backupEncryptionService;

  BackupRestoreService({
    required this.databaseHelper,
    required this.documentRepository,
    required this.folderRepository,
    required this.categoryRepository,
    required this.fileStorageService,
    required this.documentFileService,
    required this.backupEncryptionService,
  });

  // ===========================================================================
  // CREATE BACKUP
  // ===========================================================================

  Future<File> createBackup({
    required String password,
  }) async {
    final documents = await documentRepository.getDocuments();
    final folders = await folderRepository.getFolders();
    final categories = await categoryRepository.getCategories();

    final tempDirectory = await getTemporaryDirectory();

    final timestamp = _timestamp();

    final zipFile = File(
      path.join(
        tempDirectory.path,
        'PocketDocs_Backup_$timestamp.zip',
      ),
    );

    final backupFile = File(
      path.join(
        tempDirectory.path,
        'PocketDocs_Backup_$timestamp.pocketdocs',
      ),
    );

    final temporaryPlaintextFiles = <File>[];

    final encoder = ZipFileEncoder();

    try {
      // -----------------------------------------------------------------------
      // Validate all document files first.
      // -----------------------------------------------------------------------

      for (final document in documents) {
        if (document.id == null) {
          throw Exception(
            'Cannot back up a document without an ID.',
          );
        }

        final file = File(document.filePath);

        if (!await file.exists()) {
          throw Exception(
            'The file for "${document.title}" could not be found.',
          );
        }
      }

      // -----------------------------------------------------------------------
      // Create ZIP.
      // -----------------------------------------------------------------------

      encoder.create(zipFile.path);

      final manifest = {
        'format': _format,
        'version': _version,
        'createdAt': DateTime.now().toIso8601String(),
        'counts': {
          'documents': documents.length,
          'folders': folders.length,
          'categories': categories.length,
        },
      };

      await _addJsonFile(
        encoder,
        'manifest.json',
        manifest,
      );

      // -----------------------------------------------------------------------
      // Metadata.
      // -----------------------------------------------------------------------

      final data = {
        'categories': categories.map((category) {
          return {
            'id': category.id,
            'name': category.name,
            'emoji': category.emoji,
            'createdAt': category.createdAt.toIso8601String(),
          };
        }).toList(),

        'folders': folders.map((folder) {
          return {
            'id': folder.id,
            'name': folder.name,
            'createdAt': folder.createdAt.toIso8601String(),
          };
        }).toList(),

        'documents': documents.map((document) {
          final extension = document.fileType == DocumentType.pdf
              ? '.pdf'
              : '.jpg';

          return {
            'id': document.id,
            'title': document.title,
            'categoryId': document.categoryId,
            'fileType': document.fileType.name,
            'createdAt': document.createdAt.toIso8601String(),
            'notes': document.notes,
            'folderId': document.folderId,
            'backupFile': 'files/${document.id}$extension',
          };
        }).toList(),
      };

      await _addJsonFile(
        encoder,
        'data.json',
        data,
      );

      // -----------------------------------------------------------------------
      // Add decrypted document files to ZIP.
      //
      // The local .enc files are decrypted temporarily because the local
      // encryption key is device-specific and must NOT be stored in backup.
      // -----------------------------------------------------------------------

      for (final document in documents) {
        final id = document.id!;

        final isPdf = document.fileType == DocumentType.pdf;

        final extension = isPdf ? '.pdf' : '.jpg';

        final backupFileName = 'files/$id$extension';

        final encryptedOrPlainBytes =
        await documentFileService.decryptFile(
          document.filePath,
        );

        final temporaryPlaintextFile = File(
          path.join(
            tempDirectory.path,
            'pocketdocs_plain_${DateTime.now().microsecondsSinceEpoch}_$id$extension',
          ),
        );

        await temporaryPlaintextFile.writeAsBytes(
          encryptedOrPlainBytes,
          flush: true,
        );

        temporaryPlaintextFiles.add(
          temporaryPlaintextFile,
        );

        await encoder.addFile(
          temporaryPlaintextFile,
          backupFileName,
        );
      }
    } finally {
      await encoder.close();
    }

    try {
      // -----------------------------------------------------------------------
      // Read completed ZIP.
      // -----------------------------------------------------------------------

      final zipBytes = await zipFile.readAsBytes();

      // -----------------------------------------------------------------------
      // Encrypt entire ZIP using the user backup password.
      // -----------------------------------------------------------------------

      final encryptedBackup =
      await backupEncryptionService.encrypt(
        data: Uint8List.fromList(zipBytes),
        password: password,
      );

      await backupFile.writeAsBytes(
        encryptedBackup,
        flush: true,
      );

      return backupFile;
    } finally {
      // -----------------------------------------------------------------------
      // Delete temporary plaintext document files.
      // -----------------------------------------------------------------------

      for (final file in temporaryPlaintextFiles) {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }

      // -----------------------------------------------------------------------
      // Delete temporary ZIP.
      // -----------------------------------------------------------------------

      try {
        if (await zipFile.exists()) {
          await zipFile.delete();
        }
      } catch (_) {}
    }
  }

  // ===========================================================================
  // RESTORE BACKUP
  // ===========================================================================

  Future<void> restoreBackup({
    required File backupFile,
    required String password,
  }) async {
    final tempDirectory = await getTemporaryDirectory();

    final restoreDirectory = await Directory(
      path.join(
        tempDirectory.path,
        'pocketdocs_restore_${DateTime.now().millisecondsSinceEpoch}',
      ),
    ).create(recursive: true);

    final decryptedZipFile = File(
      path.join(
        restoreDirectory.path,
        'backup.zip',
      ),
    );

    final restoredFiles = <String, String>{};

    var databaseRestoreSucceeded = false;

    try {
      // -----------------------------------------------------------------------
      // Read encrypted backup.
      // -----------------------------------------------------------------------

      debugPrint('[BACKUP SERVICE] File: ${backupFile.path}');
      debugPrint('[BACKUP SERVICE] Exists: ${await backupFile.exists()}');

      final encryptedBytes = await backupFile.readAsBytes();

      debugPrint(
        '[BACKUP SERVICE] Read ${encryptedBytes.length} encrypted bytes.',
      );
      debugPrint(
        '[BACKUP SERVICE] Header bytes: '
            '${encryptedBytes.take(5).toList()}',
      );
      // -----------------------------------------------------------------------
      // Decrypt backup using supplied password.
      // -----------------------------------------------------------------------
      debugPrint('[BACKUP SERVICE] Starting password-based decryption.');

      final zipBytes = await backupEncryptionService.decrypt(
        encryptedData: Uint8List.fromList(encryptedBytes),
        password: password,
      );
      debugPrint(
        '[BACKUP SERVICE] Decryption successful. '
            'Decrypted ZIP size: ${zipBytes.length} bytes.',
      );
      await decryptedZipFile.writeAsBytes(
        zipBytes,
        flush: true,
      );

      // -----------------------------------------------------------------------
      // Decode ZIP.
      // -----------------------------------------------------------------------
      debugPrint('[BACKUP SERVICE] Decoding ZIP archive.');

      final archive = ZipDecoder().decodeBytes(
        zipBytes,
      );
      debugPrint(
        '[BACKUP SERVICE] ZIP entries: '
            '${archive.map((entry) => entry.name).toList()}',
      );

      debugPrint('[BACKUP SERVICE] Validating archive.');
      _validateArchive(archive);
      debugPrint('[BACKUP SERVICE] Archive validation passed.');

      // -----------------------------------------------------------------------
      // Validate archive.
      // -----------------------------------------------------------------------

      _validateArchive(archive);

      // -----------------------------------------------------------------------
      // Extract archive.
      // -----------------------------------------------------------------------

      await extractArchiveToDisk(
        archive,
        restoreDirectory.path,
      );

      archive.clear();

      // -----------------------------------------------------------------------
      // Read manifest and data.
      // -----------------------------------------------------------------------

      final manifestFile = File(
        path.join(
          restoreDirectory.path,
          'manifest.json',
        ),
      );

      final dataFile = File(
        path.join(
          restoreDirectory.path,
          'data.json',
        ),
      );

      final manifest = jsonDecode(
        await manifestFile.readAsString(),
      ) as Map<String, dynamic>;

      final data = jsonDecode(
        await dataFile.readAsString(),
      ) as Map<String, dynamic>;

      _validateManifest(manifest);

      final categories =
      List<Map<String, dynamic>>.from(
        (data['categories'] as List).map(
              (item) => Map<String, dynamic>.from(item),
        ),
      );

      final folders =
      List<Map<String, dynamic>>.from(
        (data['folders'] as List).map(
              (item) => Map<String, dynamic>.from(item),
        ),
      );

      final documents =
      List<Map<String, dynamic>>.from(
        (data['documents'] as List).map(
              (item) => Map<String, dynamic>.from(item),
        ),
      );

      // -----------------------------------------------------------------------
      // Validate document references before touching current database.
      // -----------------------------------------------------------------------

      await _validateDocuments(
        documents,
        restoreDirectory,
      );

      // -----------------------------------------------------------------------
      // Re-encrypt every document using this installation's new local key.
      // -----------------------------------------------------------------------

      for (final document in documents) {
        final backupFileName =
        document['backupFile'] as String;

        final extractedFile = File(
          path.join(
            restoreDirectory.path,
            backupFileName,
          ),
        );

        final isPdf = document['fileType'] == 'pdf';

        final restoredPath =
        await documentFileService.processAndSave(
          sourceFile: extractedFile,
          isPdf: isPdf,
        );

        restoredFiles[backupFileName] = restoredPath;
      }

      // -----------------------------------------------------------------------
      // Replace current database.
      // -----------------------------------------------------------------------

      final db = await databaseHelper.database;

      await db.transaction((txn) async {
        // Documents reference categories and folders.
        // Delete documents first.

        await txn.delete(
          DatabaseConstants.documentsTable,
        );

        await txn.delete(
          DatabaseConstants.foldersTable,
        );

        await txn.delete(
          DatabaseConstants.categoriesTable,
        );

        // ---------------------------------------------------------------------
        // Restore categories.
        // ---------------------------------------------------------------------

        final categoryIdMap = <int, int>{};

        for (final category in categories) {
          final oldId = category['id'] as int?;

          final newId = await txn.insert(
            DatabaseConstants.categoriesTable,
            {
              DatabaseConstants.categoryName:
              category['name'],
              DatabaseConstants.categoryEmoji:
              category['emoji'],
              DatabaseConstants.categoryCreatedAt:
              category['createdAt'],
            },
          );

          if (oldId != null) {
            categoryIdMap[oldId] = newId;
          }
        }

        // ---------------------------------------------------------------------
        // Restore folders.
        // ---------------------------------------------------------------------

        final folderIdMap = <int, int>{};

        for (final folder in folders) {
          final oldId = folder['id'] as int?;

          final newId = await txn.insert(
            DatabaseConstants.foldersTable,
            {
              DatabaseConstants.folderName:
              folder['name'],
              DatabaseConstants.folderCreatedAt:
              folder['createdAt'],
            },
          );

          if (oldId != null) {
            folderIdMap[oldId] = newId;
          }
        }

        // ---------------------------------------------------------------------
        // Restore documents.
        // ---------------------------------------------------------------------

        for (final document in documents) {
          final oldCategoryId =
          document['categoryId'] as int?;

          final oldFolderId =
          document['folderId'] as int?;

          final categoryId = oldCategoryId == null
              ? null
              : categoryIdMap[oldCategoryId];

          final folderId = oldFolderId == null
              ? null
              : folderIdMap[oldFolderId];

          final backupFileName =
          document['backupFile'] as String;

          final restoredPath =
          restoredFiles[backupFileName];

          if (restoredPath == null) {
            throw Exception(
              'Restored file is missing: $backupFileName',
            );
          }

          await txn.insert(
            DatabaseConstants.documentsTable,
            {
              DatabaseConstants.title:
              document['title'],
              DatabaseConstants.categoryId:
              categoryId,
              DatabaseConstants.filePath:
              restoredPath,
              DatabaseConstants.fileType:
              document['fileType'],
              DatabaseConstants.createdAt:
              document['createdAt'],
              DatabaseConstants.notes:
              document['notes'],
              DatabaseConstants.folderId:
              folderId,
            },
          );
        }
      });

      databaseRestoreSucceeded = true;

      // -----------------------------------------------------------------------
      // Delete old/orphaned PocketDocs files.
      // -----------------------------------------------------------------------

      await fileStorageService.clearStorageExcept(
        restoredFiles.values.toSet(),
      );
    } catch (e) {
      // -----------------------------------------------------------------------
      // IMPORTANT:
      //
      // If the database transaction already succeeded, do NOT delete the
      // restored files even if the final storage cleanup failed.
      // -----------------------------------------------------------------------

      if (!databaseRestoreSucceeded) {
        for (final restoredPath in restoredFiles.values) {
          try {
            await fileStorageService.deleteFile(
              restoredPath,
            );
          } catch (_) {}
        }
      }

      rethrow;
    } finally {
      // -----------------------------------------------------------------------
      // Delete temporary restore directory.
      // -----------------------------------------------------------------------

      if (await restoreDirectory.exists()) {
        try {
          await restoreDirectory.delete(
            recursive: true,
          );
        } catch (_) {}
      }
    }
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  void _validateArchive(Archive archive) {
    final names = archive
        .where((entry) => entry.isFile)
        .map((entry) => entry.name)
        .toSet();

    if (!names.contains('manifest.json')) {
      throw Exception(
        'Invalid PocketDocs backup: manifest.json is missing.',
      );
    }

    if (!names.contains('data.json')) {
      throw Exception(
        'Invalid PocketDocs backup: data.json is missing.',
      );
    }

    for (final entry in archive) {
      if (_containsUnsafePath(entry.name)) {
        throw Exception(
          'Invalid PocketDocs backup: unsafe file path.',
        );
      }

      if (entry.isSymbolicLink) {
        throw Exception(
          'Invalid PocketDocs backup: symbolic links are not allowed.',
        );
      }
    }
  }

  void _validateManifest(
      Map<String, dynamic> manifest,
      ) {
    if (manifest['format'] != _format) {
      throw Exception(
        'This file is not a PocketDocs backup.',
      );
    }

    if (manifest['version'] != _version) {
      throw Exception(
        'This PocketDocs backup version is not supported.',
      );
    }
  }

  Future<void> _validateDocuments(
      List<Map<String, dynamic>> documents,
      Directory restoreDirectory,
      ) async {
    for (final document in documents) {
      final backupFileName =
      document['backupFile'];

      if (backupFileName is! String ||
          !backupFileName.startsWith('files/')) {
        throw Exception(
          'Invalid document file reference.',
        );
      }

      final file = File(
        path.join(
          restoreDirectory.path,
          backupFileName,
        ),
      );

      if (!await file.exists()) {
        throw Exception(
          'A document file is missing from the backup.',
        );
      }

      final fileType = document['fileType'];

      if (fileType != 'image' && fileType != 'pdf') {
        throw Exception(
          'Unsupported document file type.',
        );
      }
    }
  }

  bool _containsUnsafePath(String fileName) {
    final normalized = path.posix.normalize(
      fileName.replaceAll('\\', '/'),
    );

    return normalized.startsWith('../') ||
        normalized == '..' ||
        normalized.startsWith('/') ||
        path.posix.isAbsolute(normalized);
  }

  Future<void> _addJsonFile(
      ZipFileEncoder encoder,
      String fileName,
      Map<String, dynamic> data,
      ) async {
    final tempDirectory =
    await getTemporaryDirectory();

    final jsonFile = File(
      path.join(
        tempDirectory.path,
        'pocketdocs_${DateTime.now().microsecondsSinceEpoch}.json',
      ),
    );

    try {
      await jsonFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );

      await encoder.addFile(
        jsonFile,
        fileName,
      );
    } finally {
      if (await jsonFile.exists()) {
        await jsonFile.delete();
      }
    }
  }

  String _timestamp() {
    final now = DateTime.now();

    String two(int value) =>
        value.toString().padLeft(2, '0');

    return '${now.year}'
        '${two(now.month)}'
        '${two(now.day)}_'
        '${two(now.hour)}'
        '${two(now.minute)}'
        '${two(now.second)}';
  }
}