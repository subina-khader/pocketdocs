class Category {
  final int? id;
  final String name;
  final String emoji;
  final DateTime createdAt;

  const Category({
    this.id,
    required this.name,
    required this.emoji,
    required this.createdAt,
  });

  Category copyWith({
    int? id,
    String? name,
    String? emoji,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}