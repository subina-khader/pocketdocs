
import 'package:provider/provider.dart';

import '../data/database/database_helper.dart';

import '../data/datasources/category_local_data_source.dart';
import '../data/datasources/category_local_data_source_impl.dart';

import '../data/datasources/document_local_data_source.dart';
import '../data/datasources/document_local_data_source_impl.dart';

import '../data/datasources/folder_local_data_source.dart';
import '../data/datasources/folder_local_data_source_impl.dart';

import '../data/repositories/category_repository_impl.dart';
import '../data/repositories/document_repository_impl.dart';
import '../data/repositories/folder_repository_impl.dart';

import '../data/services/document_file_service.dart';
import '../data/services/file_storage_service.dart';
import '../data/services/image_compression_service.dart';

import '../domain/repositories/category_repository.dart';
import '../domain/repositories/document_repository.dart';
import '../domain/repositories/folder_repository.dart';

import '../presentation/features/documents/providers/document_provider.dart';

final ServiceLocator sl = ServiceLocator();

Future<void> initializeDependencies() async {
// -------------------------
// Database
// -------------------------

final databaseHelper = DatabaseHelper();

// -------------------------
// Services
// -------------------------

final fileStorageService = FileStorageService();

final imageCompressionService =
ImageCompressionService();

final documentFileService = DocumentFileService(
fileStorageService: fileStorageService,
imageCompressionService: imageCompressionService,
);

// -------------------------
// Document Data Source
// -------------------------

final localDataSource = DocumentLocalDataSourceImpl(
databaseHelper: databaseHelper,
);

// -------------------------
// Document Repository
// -------------------------

final documentRepository = DocumentRepositoryImpl(
localDataSource: localDataSource,
documentFileService: documentFileService,
);

// -------------------------
// Folder Data Source
// -------------------------

final folderLocalDataSource = FolderLocalDataSourceImpl(
databaseHelper: databaseHelper,
);

// -------------------------
// Folder Repository
// -------------------------

final folderRepository = FolderRepositoryImpl(
localDataSource: folderLocalDataSource,
);

// -------------------------
// Category Data Source
// -------------------------

final categoryLocalDataSource =
CategoryLocalDataSourceImpl(
databaseHelper: databaseHelper,
);

// -------------------------
// Category Repository
// -------------------------

final categoryRepository = CategoryRepositoryImpl(
localDataSource: categoryLocalDataSource,
);

// -------------------------
// Register Singletons
// -------------------------

sl.registerSingleton<DatabaseHelper>(
databaseHelper,
);

sl.registerSingleton<FileStorageService>(
fileStorageService,
);

sl.registerSingleton<ImageCompressionService>(
imageCompressionService,
);

sl.registerSingleton<DocumentFileService>(
documentFileService,
);

// -------------------------
// Document Dependencies
// -------------------------

sl.registerSingleton<DocumentLocalDataSource>(
localDataSource,
);

sl.registerSingleton<DocumentRepository>(
documentRepository,
);

// -------------------------
// Folder Dependencies
// -------------------------

sl.registerSingleton<FolderLocalDataSource>(
folderLocalDataSource,
);

sl.registerSingleton<FolderRepository>(
folderRepository,
);

// -------------------------
// Category Dependencies
// -------------------------

sl.registerSingleton<CategoryLocalDataSource>(
categoryLocalDataSource,
);

sl.registerSingleton<CategoryRepository>(
categoryRepository,
);

// -------------------------
// Document Provider
// -------------------------

sl.registerFactory<DocumentProvider>(
() => DocumentProvider(
repository: sl<DocumentRepository>(),
folderRepository: sl<FolderRepository>(),
categoryRepository: sl<CategoryRepository>(),
),
);
}

class ServiceLocator {
final Map<Type, dynamic> _singletons = {};
final Map<Type, dynamic Function()> _factories = {};

void registerSingleton<T>(T instance) {
_singletons[T] = instance;
}

void registerFactory<T>(T Function() factory) {
_factories[T] = factory;
}

T call<T>() {
if (_singletons.containsKey(T)) {
return _singletons[T] as T;
}

if (_factories.containsKey(T)) {
return _factories[T]!() as T;
}

throw StateError(
'Dependency of type $T has not been registered.',
);
}

T get<T>() => call<T>();
}

