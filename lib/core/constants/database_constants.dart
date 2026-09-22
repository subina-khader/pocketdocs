
class DatabaseConstants {
DatabaseConstants._();

// -------------------------
// DATABASE
// -------------------------

static const String databaseName = 'pocket_docs.db';

static const int databaseVersion = 3;

// -------------------------
// DOCUMENTS
// -------------------------

static const String documentsTable = 'documents';

static const String id = 'id';
static const String title = 'title';

// Category is now stored as a foreign-key ID.
static const String categoryId = 'category_id';

static const String filePath = 'file_path';
static const String fileType = 'file_type';
static const String createdAt = 'created_at';
static const String documentDate = 'document_date';
static const String notes = 'notes';

// Folder is stored as a foreign-key ID.
static const String folderId = 'folder_id';

// -------------------------
// FOLDERS
// -------------------------

static const String foldersTable = 'folders';

static const String folderTableId = 'id';
static const String folderName = 'name';
static const String folderCreatedAt = 'created_at';

// -------------------------
// CATEGORIES
// -------------------------

static const String categoriesTable = 'categories';

static const String categoryTableId = 'id';
static const String categoryName = 'name';
static const String categoryCreatedAt = 'created_at';
}

