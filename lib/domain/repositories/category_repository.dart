
import '../entities/category.dart';

abstract class CategoryRepository {
Future<List<Category>> getCategories();

Future<Category?> getCategoryById(int id);

Future<Category> addCategory(Category category);

Future<void> updateCategory(Category category);

Future<void> deleteCategory(int id);
}

