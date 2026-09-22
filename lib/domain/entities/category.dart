class Category {
  final int? id;
  final String name;
  final DateTime createdAt;

  const Category({
    this.id,
    required this.name,
    required this.createdAt,
  });

  Category copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}