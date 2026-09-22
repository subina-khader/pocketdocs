enum DocumentType {
  image,
  pdf,
}



class Document {
  final int? id;
  final String title;
  final int? categoryId;
  final String filePath;
  final DocumentType fileType;
  final DateTime createdAt;
  final DateTime? documentDate;
  final String? notes;
  final int? folderId;

  const Document({
    this.id,
    required this.title,
    required this.categoryId,
    required this.filePath,
    required this.fileType,
    required this.createdAt,
    this.documentDate,
    this.notes,
    this.folderId,
  });

  Document copyWith({
    int? id,
    String? title,
    int? categoryId,
    String? filePath,
    DocumentType? fileType,
    DateTime? createdAt,
    DateTime? documentDate,
    String? notes,
    int? folderId,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      createdAt: createdAt ?? this.createdAt,
      documentDate: documentDate ?? this.documentDate,
      notes: notes ?? this.notes,
      folderId: folderId ?? this.folderId,
    );
  }
}
