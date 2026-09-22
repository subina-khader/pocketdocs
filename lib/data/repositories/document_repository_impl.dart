import '../../domain/entities/document.dart';
import '../datasources/document_local_data_source.dart';
import '../models/document_model.dart';
import '../services/document_file_service.dart';
import '../../domain/repositories/document_repository.dart';
class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentLocalDataSource localDataSource;
  final DocumentFileService documentFileService;

  DocumentRepositoryImpl({
    required this.localDataSource,
    required this.documentFileService,
  });

  @override
  Future<List<Document>> getDocuments() async {
    return await localDataSource.getDocuments();
  }

  @override
  Future<Document?> getDocumentById(int id) async {
    return await localDataSource.getDocumentById(id);
  }

  @override
  Future<Document> addDocument(Document document) async {
    final model = DocumentModel.fromEntity(document);

    final savedDocument = await localDataSource.insertDocument(
      model,
    );

    return savedDocument;
  }

  @override
  Future<void> updateDocument(Document document) async {
    final model = DocumentModel.fromEntity(document);

    await localDataSource.updateDocument(model);
  }

  @override
  Future<void> deleteDocument(int id) async {
    final document = await localDataSource.getDocumentById(id);

    if (document == null) {
      return;
    }

    await localDataSource.deleteDocument(id);

    await documentFileService.deleteFile(
      document.filePath,
    );
  }

  @override
  Future<List<Document>> searchDocuments(String query) async {
    if (query.trim().isEmpty) {
      return getDocuments();
    }

    return await localDataSource.searchDocuments(
      query.trim(),
    );
  }
}