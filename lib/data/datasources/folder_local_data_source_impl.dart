import 'package:sqflite/sqflite.dart';

import '../../core/constants/database_constants.dart';
import '../../core/errors/app_exceptions.dart' as app_exceptions;
import '../database/database_helper.dart';
import '../models/folder_model.dart';
import 'folder_local_data_source.dart';

class FolderLocalDataSourceImpl
    implements FolderLocalDataSource {
  final DatabaseHelper databaseHelper;

  FolderLocalDataSourceImpl({
    required this.databaseHelper,
  });

  @override
  Future<List<FolderModel>> getFolders() async {
    try {
      final db = await databaseHelper.database;

      final maps = await db.query(
        DatabaseConstants.foldersTable,
        orderBy:
        '${DatabaseConstants.folderCreatedAt} DESC',
      );

      return maps
          .map(FolderModel.fromMap)
          .toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to fetch folders: $e',
      );
    }
  }

  @override
  Future<FolderModel?> getFolderById(
      int id,
      ) async {
    try {
      final db = await databaseHelper.database;

      final maps = await db.query(
        DatabaseConstants.foldersTable,
        where:
        '${DatabaseConstants.folderTableId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return FolderModel.fromMap(
        maps.first,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to fetch folder: $e',
      );
    }
  }

  @override
  Future<FolderModel> insertFolder(
      FolderModel folder,
      ) async {
    try {
      final db = await databaseHelper.database;

      final id = await db.insert(
        DatabaseConstants.foldersTable,
        folder.toMap(),
      );

      return folder.copyWith(
        id: id,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to create folder: $e',
      );
    }
  }

  @override
  Future<void> updateFolder(
      FolderModel folder,
      ) async {
    if (folder.id == null) {
      throw const app_exceptions.DatabaseException(
        'Cannot update folder without an ID.',
      );
    }

    try {
      final db = await databaseHelper.database;

      await db.update(
        DatabaseConstants.foldersTable,
        folder.toMap(),
        where:
        '${DatabaseConstants.folderTableId} = ?',
        whereArgs: [folder.id],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to update folder: $e',
      );
    }
  }

  @override
  Future<void> deleteFolder(
      int id,
      ) async {
    try {
      final db = await databaseHelper.database;

      await db.delete(
        DatabaseConstants.foldersTable,
        where:
        '${DatabaseConstants.folderTableId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to delete folder: $e',
      );
    }
  }
}