import '../models/folder_model.dart';

abstract class FolderLocalDataSource {
  Future<List<FolderModel>> getFolders();

  Future<FolderModel?> getFolderById(int id);

  Future<FolderModel> insertFolder(
      FolderModel folder,
      );

  Future<void> updateFolder(
      FolderModel folder,
      );

  Future<void> deleteFolder(int id);
}