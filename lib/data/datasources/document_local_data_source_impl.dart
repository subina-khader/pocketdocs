import 'package:sqflite/sqflite.dart';

import '../../core/constants/database_constants.dart';
import '../../core/errors/app_exceptions.dart' as app_exceptions;
import '../database/database_helper.dart';
import '../models/document_model.dart';
import 'document_local_data_source.dart';

class DocumentLocalDataSourceImpl implements DocumentLocalDataSource {
  final DatabaseHelper databaseHelper;

  DocumentLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<DocumentModel>> getDocuments() async {
    try {
      final db = await databaseHelper.database;

      final maps = await db.query(
        DatabaseConstants.documentsTable,
        orderBy: '${DatabaseConstants.createdAt} DESC',
      );

      return maps.map(DocumentModel.fromMap).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to fetch documents: $e');
    }
  }

  @override
  Future<DocumentModel?> getDocumentById(int id) async {
    try {
      final db = await databaseHelper.database;

      final maps = await db.query(
        DatabaseConstants.documentsTable,
        where: '${DatabaseConstants.id} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return DocumentModel.fromMap(maps.first);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to fetch document: $e');
    }
  }

  @override
  Future<DocumentModel> insertDocument(DocumentModel document) async {
    try {
      final db = await databaseHelper.database;

      final id = await db.insert(
        DatabaseConstants.documentsTable,
        document.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return document.copyWith(id: id);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to insert document: $e');
    }
  }

  @override
  Future<void> updateDocument(DocumentModel document) async {
    if (document.id == null) {
      throw const app_exceptions.DatabaseException(
        'Cannot update a document without an ID.',
      );
    }

    try {
      final db = await databaseHelper.database;

      await db.update(
        DatabaseConstants.documentsTable,
        document.toMap(),
        where: '${DatabaseConstants.id} = ?',
        whereArgs: [document.id],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update document: $e');
    }
  }

  @override
  Future<void> deleteDocument(int id) async {
    try {
      final db = await databaseHelper.database;

      await db.delete(
        DatabaseConstants.documentsTable,
        where: '${DatabaseConstants.id} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete document: $e');
    }
  }

  @override
  Future<List<DocumentModel>> searchDocuments(String query) async {
    try {
      final db = await databaseHelper.database;

      final searchQuery = '%$query%';

      final maps = await db.rawQuery(
        '''
        SELECT d.*
        FROM ${DatabaseConstants.documentsTable} AS d
        LEFT JOIN ${DatabaseConstants.categoriesTable} AS c
          ON d.${DatabaseConstants.categoryId} =
             c.${DatabaseConstants.categoryTableId}
        WHERE d.${DatabaseConstants.title} LIKE ?
           OR c.${DatabaseConstants.categoryName} LIKE ?
           OR d.${DatabaseConstants.notes} LIKE ?
        ORDER BY d.${DatabaseConstants.createdAt} DESC
        ''',
        [searchQuery, searchQuery, searchQuery],
      );

      return maps.map(DocumentModel.fromMap).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to search documents: $e');
    }
  }
}
