import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../domain/entities/category.dart' as category_entity;
import '../../../../domain/entities/document.dart';
import '../../../../domain/entities/folder.dart';
import '../../../../domain/repositories/category_repository.dart';
import '../../../../domain/repositories/document_repository.dart';
import '../../../../domain/repositories/folder_repository.dart';

enum DocumentStatus { initial, loading, loaded, empty, error }

enum DocumentSortOption { newest, oldest, titleAscending, titleDescending }

class DocumentProvider extends ChangeNotifier {
  final DocumentRepository repository;
  final FolderRepository folderRepository;
  final CategoryRepository categoryRepository;

  DocumentProvider({
    required this.repository,
    required this.folderRepository,
    required this.categoryRepository,
  });

  DocumentStatus _status = DocumentStatus.initial;

  List<Document> _allDocuments = [];
  List<Document> _documents = [];

  List<Folder> _folders = [];
  List<category_entity.Category> _categories = [];
  int? _selectedFolderId;
  int? _selectedCategoryId;

  String _searchQuery = '';

  DocumentSortOption _sortOption = DocumentSortOption.newest;

  String? _errorMessage;

  Timer? _searchDebounce;

  // ------------------------------------------------------------
  // GETTERS
  // ------------------------------------------------------------

  DocumentStatus get status => _status;

  List<Document> get documents => List.unmodifiable(_documents);

  List<Document> get allDocuments => List.unmodifiable(_allDocuments);

  List<Folder> get folders => List.unmodifiable(_folders);

  List<category_entity.Category> get categories =>
      List.unmodifiable(_categories);
  int? get selectedFolderId => _selectedFolderId;

  int? get selectedCategoryId => _selectedCategoryId;

  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;

  DocumentSortOption get sortOption => _sortOption;

  bool get isLoading => _status == DocumentStatus.loading;

  int get documentCount => _allDocuments.length;

  // ------------------------------------------------------------
  // CATEGORY HELPERS
  // ------------------------------------------------------------

  String? categoryNameForId(int? categoryId) {
    if (categoryId == null) {
      return null;
    }

    try {
      return _categories
          .firstWhere((category) => category.id == categoryId)
          .name;
    } catch (_) {
      return null;
    }
  }

  category_entity.Category? categoryForId(int? categoryId)  {
    if (categoryId == null) {
      return null;
    }

    try {
      return _categories.firstWhere((category) => category.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  String? categoryNameForDocument(Document document) {
    return categoryNameForId(document.categoryId);
  }

  // ------------------------------------------------------------
  // LOAD DOCUMENTS
  // ------------------------------------------------------------

  Future<void> loadDocuments() async {
    _setLoading();

    try {
      final documents = await repository.getDocuments();

      _allDocuments = documents;

      _applyFiltersAndSorting();

      _clearError();

      _updateStatus();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ------------------------------------------------------------
  // GET DOCUMENT BY ID
  // ------------------------------------------------------------

  Future<Document?> getDocumentById(int id) async {
    try {
      return await repository.getDocumentById(id);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // ------------------------------------------------------------
  // FOLDERS
  // ------------------------------------------------------------

  Future<void> loadFolders() async {
    try {
      _folders = await folderRepository.getFolders();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> addFolder(String name) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return false;
    }

    try {
      final folder = Folder(name: trimmedName, createdAt: DateTime.now());

      final savedFolder = await folderRepository.addFolder(folder);

      _folders = [savedFolder, ..._folders];

      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> renameFolder(int id, String name) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return false;
    }

    try {
      final oldFolder = _folders.firstWhere((folder) => folder.id == id);

      final updatedFolder = oldFolder.copyWith(name: trimmedName);

      await folderRepository.updateFolder(updatedFolder);

      _folders = _folders.map((folder) {
        if (folder.id == id) {
          return updatedFolder;
        }

        return folder;
      }).toList();

      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> deleteFolder(int id) async {
    try {
      await folderRepository.deleteFolder(id);

      _folders = _folders.where((folder) => folder.id != id).toList();

      // Documents are not deleted.
      // Only their folder relationship is cleared.
      _allDocuments = _allDocuments.map((document) {
        if (document.folderId == id) {
          return document.copyWith(folderId: null);
        }

        return document;
      }).toList();

      if (_selectedFolderId == id) {
        _selectedFolderId = null;
      }

      _applyFiltersAndSorting();
      _updateStatus();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  void filterByFolder(int? folderId) {
    _selectedFolderId = folderId;

    _applyFiltersAndSorting();
    _updateStatus();
  }

  // ------------------------------------------------------------
  // CATEGORIES
  // ------------------------------------------------------------

  Future<void> loadCategories() async {
    try {
      _categories = await categoryRepository.getCategories();

      _applyFiltersAndSorting();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> addCategory(String name) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return false;
    }

    try {
      final category = category_entity.Category(
        name: trimmedName,
        createdAt: DateTime.now(),
      );
      final savedCategory = await categoryRepository.addCategory(category);

      _categories = [savedCategory, ..._categories];

      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> renameCategory(int id, String name) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return false;
    }

    try {
      final oldCategory = _categories.firstWhere(
        (category) => category.id == id,
      );

      final updatedCategory = oldCategory.copyWith(name: trimmedName);

      await categoryRepository.updateCategory(updatedCategory);

      _categories = _categories.map((category) {
        if (category.id == id) {
          return updatedCategory;
        }

        return category;
      }).toList();

      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      await categoryRepository.deleteCategory(id);

      _categories = _categories.where((category) => category.id != id).toList();

      // Documents are not deleted.
      // Their category_id is cleared.
      _allDocuments = _allDocuments.map((document) {
        if (document.categoryId == id) {
          return document.copyWith(categoryId: null);
        }

        return document;
      }).toList();

      if (_selectedCategoryId == id) {
        _selectedCategoryId = null;
      }

      _applyFiltersAndSorting();
      _updateStatus();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  void filterByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;

    _applyFiltersAndSorting();
    _updateStatus();
  }

  // ------------------------------------------------------------
  // DOCUMENT CRUD
  // ------------------------------------------------------------

  Future<bool> addDocument(Document document) async {
    try {
      final savedDocument = await repository.addDocument(document);

      _allDocuments = [savedDocument, ..._allDocuments];

      _applyFiltersAndSorting();
      _updateStatus();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> updateDocument(Document document) async {
    try {
      await repository.updateDocument(document);

      final index = _allDocuments.indexWhere((item) => item.id == document.id);

      if (index != -1) {
        final updatedDocuments = [..._allDocuments];

        updatedDocuments[index] = document;

        _allDocuments = updatedDocuments;
      }

      _applyFiltersAndSorting();
      _updateStatus();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> deleteDocument(int id) async {
    try {
      await repository.deleteDocument(id);

      _allDocuments = _allDocuments
          .where((document) => document.id != id)
          .toList();

      _applyFiltersAndSorting();
      _updateStatus();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------

  void searchDocuments(String query) {
    _searchQuery = query;

    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _applyFiltersAndSorting();
      _updateStatus();
    });
  }

  // ------------------------------------------------------------
  // SORT
  // ------------------------------------------------------------

  void sortDocuments(DocumentSortOption option) {
    _sortOption = option;

    _applyFiltersAndSorting();
    _updateStatus();
  }

  // ------------------------------------------------------------
  // CLEAR FILTERS
  // ------------------------------------------------------------

  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _selectedFolderId = null;
    _sortOption = DocumentSortOption.newest;

    _applyFiltersAndSorting();
    _updateStatus();
  }

  // ------------------------------------------------------------
  // REFRESH
  // ------------------------------------------------------------

  Future<void> refresh() async {
    _searchQuery = '';
    _selectedCategoryId = null;
    _selectedFolderId = null;
    _sortOption = DocumentSortOption.newest;

    await loadData();
  }

  // ------------------------------------------------------------
  // LOAD ALL DATA
  // ------------------------------------------------------------

  Future<void> loadData() async {
    _setLoading();

    try {
      final results = await Future.wait([
        repository.getDocuments(),
        folderRepository.getFolders(),
        categoryRepository.getCategories(),
      ]);

      _allDocuments = results[0] as List<Document>;
      _folders = results[1] as List<Folder>;
      _categories = results[2] as List<category_entity.Category>;
      _applyFiltersAndSorting();

      _clearError();
      _updateStatus();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ------------------------------------------------------------
  // ASSIGN DOCUMENTS TO FOLDER
  // ------------------------------------------------------------

  Future<bool> assignDocumentsToFolder(
    List<int> documentIds,
    int? folderId,
  ) async {
    try {
      for (final documentId in documentIds) {
        final document = _allDocuments.firstWhere(
          (item) => item.id == documentId,
        );

        final updatedDocument = document.copyWith(folderId: folderId);

        await repository.updateDocument(updatedDocument);
      }

      _allDocuments = _allDocuments.map((document) {
        if (document.id != null && documentIds.contains(document.id)) {
          return document.copyWith(folderId: folderId);
        }

        return document;
      }).toList();

      _applyFiltersAndSorting();
      _updateStatus();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ------------------------------------------------------------
  // MOVE DOCUMENT TO FOLDER
  // ------------------------------------------------------------

  Future<bool> moveDocumentToFolder(int documentId, int? folderId) async {
    try {
      final document = _allDocuments.firstWhere(
        (document) => document.id == documentId,
      );

      final updatedDocument = document.copyWith(folderId: folderId);

      await repository.updateDocument(updatedDocument);

      _allDocuments = _allDocuments.map((item) {
        if (item.id == documentId) {
          return updatedDocument;
        }

        return item;
      }).toList();

      _applyFiltersAndSorting();
      _updateStatus();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ------------------------------------------------------------
  // FILTER + SORT
  // ------------------------------------------------------------

  void _applyFiltersAndSorting() {
    var result = List<Document>.from(_allDocuments);

    final query = _searchQuery.trim().toLowerCase();

    // Folder filter
    if (_selectedFolderId != null) {
      result = result.where((document) {
        return document.folderId == _selectedFolderId;
      }).toList();
    }

    // Search
    if (query.isNotEmpty) {
      result = result.where((document) {
        final title = document.title.toLowerCase();

        final categoryName =
            categoryNameForId(document.categoryId)?.toLowerCase() ?? '';

        final notes = document.notes?.toLowerCase() ?? '';

        return title.contains(query) ||
            categoryName.contains(query) ||
            notes.contains(query);
      }).toList();
    }

    // Category filter
    if (_selectedCategoryId != null) {
      result = result.where((document) {
        return document.categoryId == _selectedCategoryId;
      }).toList();
    }

    result.sort(_compareDocuments);

    _documents = result;
  }

  // ------------------------------------------------------------
  // SORT COMPARISON
  // ------------------------------------------------------------

  int _compareDocuments(Document a, Document b) {
    switch (_sortOption) {
      case DocumentSortOption.newest:
        return b.createdAt.compareTo(a.createdAt);

      case DocumentSortOption.oldest:
        return a.createdAt.compareTo(b.createdAt);

      case DocumentSortOption.titleAscending:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());

      case DocumentSortOption.titleDescending:
        return b.title.toLowerCase().compareTo(a.title.toLowerCase());
    }
  }

  // ------------------------------------------------------------
  // STATUS
  // ------------------------------------------------------------

  void _setLoading() {
    _status = DocumentStatus.loading;
    _errorMessage = null;

    notifyListeners();
  }

  void _setError(String message) {
    _status = DocumentStatus.error;
    _errorMessage = message;

    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _updateStatus() {
    if (_documents.isEmpty) {
      _status = DocumentStatus.empty;
    } else {
      _status = DocumentStatus.loaded;
    }

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _updateStatus();
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
