import '../../core/constants/database_constants.dart';
import '../../domain/entities/folder.dart';

class FolderModel extends Folder {
  const FolderModel({
    super.id,
    required super.name,
    required super.createdAt,
  });

  factory FolderModel.fromEntity(Folder folder) {
    return FolderModel(
      id: folder.id,
      name: folder.name,
      createdAt: folder.createdAt,
    );
  }

  factory FolderModel.fromMap(Map<String, dynamic> map) {
    return FolderModel(
      id: map[DatabaseConstants.folderTableId] as int?,
      name: map[DatabaseConstants.folderName] as String,
      createdAt: DateTime.parse(
        map[DatabaseConstants.folderCreatedAt] as String,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) DatabaseConstants.folderTableId: id,
      DatabaseConstants.folderName: name,
      DatabaseConstants.folderCreatedAt:
      createdAt.toIso8601String(),
    };
  }

  FolderModel copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}