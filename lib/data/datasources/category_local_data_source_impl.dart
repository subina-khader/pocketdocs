import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/category_model.dart';
import '../../core/constants/database_constants.dart';
import 'category_local_data_source.dart';

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  final DatabaseHelper databaseHelper;

  CategoryLocalDataSourceImpl({
    required this.databaseHelper,
  });

  @override
  Future<List<CategoryModel>> getCategories() async {
    final db = await databaseHelper.database;

    final maps = await db.query(
      DatabaseConstants.categoriesTable,
      orderBy: '${DatabaseConstants.categoryName} ASC',
    );

    return maps
        .map((map) => CategoryModel.fromMap(map))
        .toList();
  }

  @override
  Future<CategoryModel?> getCategoryById(int id) async {
    final db = await databaseHelper.database;

    final maps = await db.query(
      DatabaseConstants.categoriesTable,
      where: '${DatabaseConstants.categoryTableId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return CategoryModel.fromMap(maps.first);
  }

  @override
  Future<CategoryModel> insertCategory(
      CategoryModel category,
      ) async {
    final db = await databaseHelper.database;

    final id = await db.insert(
      DatabaseConstants.categoriesTable,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return category.copyWith(id: id);
  }

  @override
  Future<void> updateCategory(
      CategoryModel category,
      ) async {
    if (category.id == null) {
      throw ArgumentError(
        'Category ID is required to update a category.',
      );
    }

    final db = await databaseHelper.database;

    await db.update(
      DatabaseConstants.categoriesTable,
      category.toMap(),
      where: '${DatabaseConstants.categoryTableId} = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<void> deleteCategory(int id) async {
    final db = await databaseHelper.database;

    await db.delete(
      DatabaseConstants.categoriesTable,
      where: '${DatabaseConstants.categoryTableId} = ?',
      whereArgs: [id],
    );
  }
}