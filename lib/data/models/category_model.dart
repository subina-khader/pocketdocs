import '../../core/constants/database_constants.dart';
import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    super.id,
    required super.name,
    required super.createdAt,
  });

  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      createdAt: category.createdAt,
    );
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map[DatabaseConstants.categoryTableId] as int?,
      name: map[DatabaseConstants.categoryName] as String,
      createdAt: DateTime.parse(
        map[DatabaseConstants.categoryCreatedAt] as String,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) DatabaseConstants.categoryTableId: id,
      DatabaseConstants.categoryName: name,
      DatabaseConstants.categoryCreatedAt: createdAt.toIso8601String(),
    };
  }

  CategoryModel copyWith({int? id, String? name, DateTime? createdAt}) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
