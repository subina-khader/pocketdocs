import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/database_constants.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/repositories/folder_repository.dart';
import '../database/database_helper.dart';
import '../models/category_model.dart';
import '../models/document_model.dart';
import '../models/folder_model.dart';
import 'file_storage_service.dart';

class BackupRestoreService {
  static const String _format = 'pocketdocs';
  static const int _version = 1;

  final DatabaseHelper databaseHelper;
  final DocumentRepository documentRepository;
  final FolderRepository folderRepository;
  final CategoryRepository categoryRepository;
  final FileStorageService fileStorageService;

  BackupRestoreService({
    required this.databaseHelper,
    required this.documentRepository,
    required this.folderRepository,
    required this.categoryRepository,
    required this.fileStorageService,
  });

  // ===========================================================================
  // CREATE BACKUP
  // ===========================================================================

  Future<File> createBackup() async {
    final documents = await documentRepository.getDocuments();
    final folders = await folderRepository.getFolders();
    final categories = await categoryRepository.getCategories();

    final tempDirectory = await getTemporaryDirectory();

    final backupFile = File(
      path.join(
        tempDirectory.path,
        'PocketDocs_Backup_${_timestamp()}.pocketdocs',
      ),
    );

    final encoder = ZipFileEncoder();

    encoder.create(backupFile.path);

    try {
      // -----------------------------------------------------------------------
      // Validate all document files before creating the backup.
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
      // Manifest
      // -----------------------------------------------------------------------

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
      // Metadata
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
          final extension = path.extension(document.filePath);

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
      // Document files
      // -----------------------------------------------------------------------

      for (final document in documents) {
        final file = File(document.filePath);

        final extension = path.extension(document.filePath);

        final backupFileName =
            'files/${document.id}$extension';

        await encoder.addFile(
          file,
          backupFileName,
        );
      }
    } finally {
      await encoder.close();
    }

    return backupFile;
  }

  // ===========================================================================
  // RESTORE BACKUP
  // ===========================================================================

  Future<void> restoreBackup(File backupFile) async {
    print('========== BACKUP RESTORE SERVICE ==========');
    print('Received backup path: ${backupFile.path}');
    print('Backup exists: ${await backupFile.exists()}');

    if (await backupFile.exists()) {
      print('Backup size: ${await backupFile.length()} bytes');
    }
    final tempDirectory = await getTemporaryDirectory();

    final restoreDirectory = await Directory(
      path.join(
        tempDirectory.path,
        'pocketdocs_restore_${DateTime.now().millisecondsSinceEpoch}',
      ),
    ).create(recursive: true);

    final restoredFiles = <String, String>{};

    try {
      // -------------------------------------------------------------------------
      // Decode archive
      // -------------------------------------------------------------------------

      final input = InputFileStream(backupFile.path);
      print('Attempting to decode backup as ZIP archive...');
      final archive = ZipDecoder().decodeStream(input);
      print('ZIP archive decoded successfully.');
      print('Archive entries: ${archive.length}');

      for (final entry in archive) {
        print('Archive entry: ${entry.name}');
      }
      await input.close();

      // -------------------------------------------------------------------------
      // Validate archive structure
      // -------------------------------------------------------------------------

      _validateArchive(archive);

      // -------------------------------------------------------------------------
      // Extract archive
      // -------------------------------------------------------------------------

      await extractArchiveToDisk(
        archive,
        restoreDirectory.path,
      );

      archive.clear();

      // -------------------------------------------------------------------------
      // Read metadata
      // -------------------------------------------------------------------------

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

      // -------------------------------------------------------------------------
      // Read backup data
      // -------------------------------------------------------------------------

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

      // -------------------------------------------------------------------------
      // Validate referenced document files
      // -------------------------------------------------------------------------

      await _validateDocuments(
        documents,
        restoreDirectory,
      );

      // -------------------------------------------------------------------------
      // Save restored files
      //
      // IMPORTANT:
      // We save them before touching the existing database.
      // -------------------------------------------------------------------------

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
        await fileStorageService.saveFile(
          sourceFile: extractedFile,
          isPdf: isPdf,
        );

        restoredFiles[backupFileName] = restoredPath;
      }

      // -------------------------------------------------------------------------
      // Replace current database
      // -------------------------------------------------------------------------

      final db = await databaseHelper.database;

      await db.transaction((txn) async {
        // Documents reference categories and folders,
        // so delete documents first.
        await txn.delete(
          DatabaseConstants.documentsTable,
        );

        await txn.delete(
          DatabaseConstants.foldersTable,
        );

        await txn.delete(
          DatabaseConstants.categoriesTable,
        );

        // -----------------------------------------------------------------------
        // Restore categories
        // -----------------------------------------------------------------------

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

        // -----------------------------------------------------------------------
        // Restore folders
        // -----------------------------------------------------------------------

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

        // -----------------------------------------------------------------------
        // Restore documents
        // -----------------------------------------------------------------------

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

      // -------------------------------------------------------------------------
      // Database restore succeeded.
      //
      // Now remove old/orphaned PocketDocs files while keeping
      // the newly restored files.
      // -------------------------------------------------------------------------

      await fileStorageService.clearStorageExcept(
        restoredFiles.values.toSet(),
      );
    } catch (e) {
      // -------------------------------------------------------------------------
      // Restore failed.
      //
      // Delete only the files that we created during this restore attempt.
      // Existing PocketDocs files remain untouched.
      // -------------------------------------------------------------------------

      for (final restoredPath in restoredFiles.values) {
        await fileStorageService.deleteFile(
          restoredPath,
        );
      }

      rethrow;
    } finally {
      // -------------------------------------------------------------------------
      // Remove temporary extracted backup files.
      // -------------------------------------------------------------------------

      if (await restoreDirectory.exists()) {
        await restoreDirectory.delete(
          recursive: true,
        );
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