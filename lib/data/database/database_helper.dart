import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/database_constants.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, DatabaseConstants.databaseName);

    return openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

        ${DatabaseConstants.documentDate}
            TEXT,

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
      'Receipt',
      'ID Card',
      'Vehicle',
      'Certificate',
      'Warranty',
      'Bill',
      'Travel',
      'Other',
    ];

    for (final category in defaultCategories) {
      await db.insert(DatabaseConstants.categoriesTable, {
        DatabaseConstants.categoryName: category,
        DatabaseConstants.categoryCreatedAt: now,
      });
    }
  }
}
