import '../models/document_model.dart';

abstract class DocumentLocalDataSource {
  Future<List<DocumentModel>> getDocuments();

  Future<DocumentModel?> getDocumentById(int id);

  Future<DocumentModel> insertDocument(
      DocumentModel document,
      );

  Future<void> updateDocument(
      DocumentModel document,
      );

  Future<void> deleteDocument(int id);

  Future<List<DocumentModel>> searchDocuments(
      String query,
      );
}