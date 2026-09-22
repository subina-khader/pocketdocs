class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

class DatabaseException extends AppException {
  const DatabaseException(super.message);
}

class FileStorageException extends AppException {
  const FileStorageException(super.message);
}

class ImageProcessingException extends AppException {
  const ImageProcessingException(super.message);
}

class DocumentNotFoundException extends AppException {
  const DocumentNotFoundException(super.message);
}