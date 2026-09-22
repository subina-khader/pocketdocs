import '../../domain/entities/folder.dart';
import '../../domain/repositories/folder_repository.dart';

import '../datasources/folder_local_data_source.dart';
import '../models/folder_model.dart';

class FolderRepositoryImpl
    implements FolderRepository {
  final FolderLocalDataSource localDataSource;

  FolderRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<List<Folder>> getFolders() async {
    return await localDataSource.getFolders();
  }

  @override
  Future<Folder?> getFolderById(
      int id,
      ) async {
    return await localDataSource.getFolderById(id);
  }

  @override
  Future<Folder> addFolder(
      Folder folder,
      ) async {
    final model =
    FolderModel.fromEntity(folder);

    return await localDataSource.insertFolder(
      model,
    );
  }

  @override
  Future<void> updateFolder(
      Folder folder,
      ) async {
    final model =
    FolderModel.fromEntity(folder);

    await localDataSource.updateFolder(
      model,
    );
  }

  @override
  Future<void> deleteFolder(
      int id,
      ) async {
    await localDataSource.deleteFolder(id);
  }
}