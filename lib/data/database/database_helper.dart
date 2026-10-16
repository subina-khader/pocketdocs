import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../core/constants/database_constants.dart';
import '../../core/errors/app_exceptions.dart' as app_exceptions;
import '../services/database_key_service.dart';

class DatabaseHelper {
  static Database? _database;

  final DatabaseKeyService databaseKeyService;

  DatabaseHelper({
    required this.databaseKeyService,
  });

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final databasePath = await getDatabasesPath();

      final databaseFilePath = join(
        databasePath,
        DatabaseConstants.databaseName,
      );

      final databaseKey =
      await databaseKeyService.getOrCreateKey();

      return await openDatabase(
        databaseFilePath,
        version: DatabaseConstants.databaseVersion,
        password: databaseKey,
        onConfigure: (db) async {
          await db.execute(
            'PRAGMA foreign_keys = ON',
          );
        },
        onCreate: _onCreate,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to initialize database: $e',
      );
    }
  }

  Future<void> _onCreate(
      Database db,
      int version,
      ) async {
    // -------------------------
    // FOLDERS TABLE
    // -------------------------

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.foldersTable} (
        ${DatabaseConstants.folderTableId}
            INTEGER PRIMARY KEY AUTOINCREMENT,

        ${DatabaseConstants.folderName}
            TEXT NOT NULL,

        ${DatabaseConstants.folderCreatedAt}
            TEXT NOT NULL
      )
    ''');

    // -------------------------
    // CATEGORIES TABLE
    // -------------------------

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.categoriesTable} (
        ${DatabaseConstants.categoryTableId}
            INTEGER PRIMARY KEY AUTOINCREMENT,

        ${DatabaseConstants.categoryName}
            TEXT NOT NULL UNIQUE,

        ${DatabaseConstants.categoryEmoji}
            TEXT NOT NULL,

        ${DatabaseConstants.categoryCreatedAt}
            TEXT NOT NULL
      )
    ''');

    // -------------------------
    // DOCUMENTS TABLE
    // -------------------------

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.documentsTable} (
        ${DatabaseConstants.id}
            INTEGER PRIMARY KEY AUTOINCREMENT,

        ${DatabaseConstants.title}
            TEXT NOT NULL,

        ${DatabaseConstants.categoryId}
            INTEGER,

        ${DatabaseConstants.filePath}
            TEXT NOT NULL,

        ${DatabaseConstants.fileType}
            TEXT NOT NULL,

        ${DatabaseConstants.createdAt}
            TEXT NOT NULL,

        ${DatabaseConstants.notes}
            TEXT,

        ${DatabaseConstants.folderId}
            INTEGER,

        FOREIGN KEY (${DatabaseConstants.categoryId})
          REFERENCES ${DatabaseConstants.categoriesTable}
          (${DatabaseConstants.categoryTableId})
          ON DELETE SET NULL,

        FOREIGN KEY (${DatabaseConstants.folderId})
          REFERENCES ${DatabaseConstants.foldersTable}
          (${DatabaseConstants.folderTableId})
          ON DELETE SET NULL
      )
    ''');

    // -------------------------
    // DEFAULT CATEGORIES
    // -------------------------

    final now = DateTime.now().toIso8601String();

    final defaultCategories = [
      {
        'name': 'Receipt',
        'emoji': '🧾',
      },
      {
        'name': 'ID Card',
        'emoji': '🪪',
      },
      {
        'name': 'Vehicle',
        'emoji': '🚗',
      },
      {
        'name': 'Certificate',
        'emoji': '🎓',
      },
      {
        'name': 'Bill',
        'emoji': '💰',
      },
    ];

    for (final category in defaultCategories) {
      await db.insert(
        DatabaseConstants.categoriesTable,
        {
          DatabaseConstants.categoryName:
          category['name'],
          DatabaseConstants.categoryEmoji:
          category['emoji'],
          DatabaseConstants.categoryCreatedAt:
          now,
        },
      );
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}