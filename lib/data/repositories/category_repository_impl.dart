import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_data_source.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource localDataSource;

  CategoryRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<List<Category>> getCategories() async {
    return await localDataSource.getCategories();
  }

  @override
  Future<Category?> getCategoryById(int id) async {
    return await localDataSource.getCategoryById(id);
  }

  @override
  Future<Category> addCategory(Category category) async {
    final model = CategoryModel.fromEntity(category);

    return await localDataSource.insertCategory(model);
  }

  @override
  Future<void> updateCategory(Category category) async {
    final model = CategoryModel.fromEntity(category);

    await localDataSource.updateCategory(model);
  }

  @override
  Future<void> deleteCategory(int id) async {
    await localDataSource.deleteCategory(id);
  }
}