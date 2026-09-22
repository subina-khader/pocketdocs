import '../models/category_model.dart';

abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories();

  Future<CategoryModel?> getCategoryById(int id);

  Future<CategoryModel> insertCategory(CategoryModel category);

  Future<void> updateCategory(CategoryModel category);

  Future<void> deleteCategory(int id);
}
