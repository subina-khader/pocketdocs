import '../../core/constants/database_constants.dart';
import '../../domain/entities/document.dart';

class DocumentModel extends Document {
  const DocumentModel({
    super.id,
    required super.title,
    required super.categoryId,
    required super.filePath,
    required super.fileType,
    required super.createdAt,
    super.documentDate,
    super.notes,
    super.folderId,
  });

  factory DocumentModel.fromEntity(Document document) {
    return DocumentModel(
      id: document.id,
      title: document.title,
      categoryId: document.categoryId,
      filePath: document.filePath,
      fileType: document.fileType,
      createdAt: document.createdAt,
      documentDate: document.documentDate,
      notes: document.notes,
      folderId: document.folderId,
    );
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map[DatabaseConstants.id] as int?,
      title: map[DatabaseConstants.title] as String,
      categoryId: map[DatabaseConstants.categoryId] as int?,
      filePath: map[DatabaseConstants.filePath] as String,
      fileType: DocumentType.values.firstWhere(
        (value) => value.name == map[DatabaseConstants.fileType],
        orElse: () => DocumentType.image,
      ),
      createdAt: DateTime.parse(map[DatabaseConstants.createdAt] as String),
      documentDate: map[DatabaseConstants.documentDate] != null
          ? DateTime.parse(map[DatabaseConstants.documentDate] as String)
          : null,
      notes: map[DatabaseConstants.notes] as String?,
      folderId: map[DatabaseConstants.folderId] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) DatabaseConstants.id: id,
      DatabaseConstants.title: title,
      DatabaseConstants.categoryId: categoryId,
      DatabaseConstants.filePath: filePath,
      DatabaseConstants.fileType: fileType.name,
      DatabaseConstants.createdAt: createdAt.toIso8601String(),
      DatabaseConstants.documentDate: documentDate?.toIso8601String(),
      DatabaseConstants.notes: notes,
      DatabaseConstants.folderId: folderId,
    };
  }

  DocumentModel copyWith({
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
    return DocumentModel(
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
