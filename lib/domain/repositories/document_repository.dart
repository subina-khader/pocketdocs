import '../entities/document.dart';

abstract class DocumentRepository {
  Future<List<Document>> getDocuments();

  Future<Document?> getDocumentById(int id);

  Future<Document> addDocument(
      Document document,
      );

  Future<void> updateDocument(
      Document document,
      );

  Future<void> deleteDocument(
      int id,
      );

  Future<List<Document>> searchDocuments(
      String query,
      );
}