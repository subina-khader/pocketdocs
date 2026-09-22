import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../data/services/document_file_service.dart';
import '../../../../dependency_injection/injection_container.dart';
import '../../../../domain/entities/document.dart';
import '../providers/document_provider.dart';

class AddDocumentScreen extends StatefulWidget {
  final Document? document;

  const AddDocumentScreen({super.key, this.document});

  bool get isEditing => document != null;

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();

  final _notesController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  int? _folderId;

  int? _categoryId;

  DateTime? _documentDate;

  File? _selectedFile;

  bool _isPdf = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final document = widget.document;

    if (document != null) {
      _titleController.text = document.title;

      _notesController.text = document.notes ?? '';

      _categoryId = document.categoryId;

      _documentDate = document.documentDate;

      _selectedFile = File(document.filePath);

      _isPdf = document.fileType == DocumentType.pdf;

      _folderId = document.folderId;
    }

    // Load categories/folders after
    // the provider is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final provider = context.read<DocumentProvider>();

      if (provider.categories.isEmpty) {
        provider.loadCategories();
      }

      if (provider.folders.isEmpty) {
        provider.loadFolders();
      }

      // For a new document, select the
      // first available category by default.
      if (widget.document == null &&
          _categoryId == null &&
          provider.categories.isNotEmpty) {
        setState(() {
          _categoryId = provider.categories.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // CAMERA
  // ------------------------------------------------------------

  Future<void> _takePhoto() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    setState(() {
      _selectedFile = File(image.path);

      _isPdf = false;
    });
  }

  // ------------------------------------------------------------
  // GALLERY
  // ------------------------------------------------------------

  Future<void> _pickFromGallery() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      _selectedFile = File(image.path);

      _isPdf = false;
    });
  }

  // ------------------------------------------------------------
  // PDF
  // ------------------------------------------------------------

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    setState(() {
      _selectedFile = File(result.files.single.path!);

      _isPdf = true;
    });
  }

  // ------------------------------------------------------------
  // DATE
  // ------------------------------------------------------------

  Future<void> _selectDocumentDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: _documentDate ?? DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _documentDate = date;
      });
    }
  }

  // ------------------------------------------------------------
  // SAVE
  // ------------------------------------------------------------

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFile == null) {
      _showMessage('Please select a document.');
      return;
    }

    if (_categoryId == null) {
      _showMessage('Please select a category.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = context.read<DocumentProvider>();

      final fileService = sl<DocumentFileService>();

      String filePath = _selectedFile!.path;

      final isExistingFile =
          widget.document != null && filePath == widget.document!.filePath;

      if (!isExistingFile) {
        filePath = await fileService.processAndSave(
          sourceFile: _selectedFile!,
          isPdf: _isPdf,
        );
      }

      final document = Document(
        id: widget.document?.id,
        title: _titleController.text.trim(),
        categoryId: _categoryId,
        filePath: filePath,
        fileType: _isPdf ? DocumentType.pdf : DocumentType.image,
        createdAt: widget.document?.createdAt ?? DateTime.now(),
        documentDate: _documentDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        folderId: _folderId,
      );

      final success = widget.isEditing
          ? await provider.updateDocument(document)
          : await provider.addDocument(document);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
        return;
      }

      if (!isExistingFile) {
        await fileService.deleteFile(filePath);
      }

      _showMessage('Unable to save document.');
    } catch (_) {
      if (!mounted) return;

      _showMessage('Something went wrong while saving.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Document' : 'Add Document'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFileSelector(),

            const SizedBox(height: 22),

            // TITLE
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Amazon Receipt',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title.';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            // CATEGORY
            Consumer<DocumentProvider>(
              builder: (context, provider, _) {
                if (provider.categories.isEmpty) {
                  return InputDecorator(
                    decoration: const InputDecoration(labelText: 'Category'),
                    child: const Text('No categories available'),
                  );
                }

                return DropdownButtonFormField<int>(
                  value: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: provider.categories
                      .map(
                        (category) => DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoryId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category.';
                    }

                    return null;
                  },
                );
              },
            ),

            const SizedBox(height: 14),

            // FOLDER
            Consumer<DocumentProvider>(
              builder: (context, provider, _) {
                return DropdownButtonFormField<int?>(
                  value: _folderId,
                  decoration: const InputDecoration(labelText: 'Folder'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...provider.folders.map(
                      (folder) => DropdownMenuItem<int?>(
                        value: folder.id,
                        child: Text(folder.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _folderId = value;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 14),

            // DOCUMENT DATE
            _DateField(
              label: 'Document Date',
              date: _documentDate,
              onTap: _selectDocumentDate,
            ),

            const SizedBox(height: 14),

            // NOTES
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Add additional information...',
              ),
            ),

            const SizedBox(height: 26),

            // SAVE
            FilledButton(
              onPressed: _isSaving ? null : _saveDocument,
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.isEditing ? 'Update Document' : 'Save Document',
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FILE SELECTOR
  // ------------------------------------------------------------

  Widget _buildFileSelector() {
    if (_selectedFile != null) {
      return _SelectedFilePreview(
        file: _selectedFile!,
        isPdf: _isPdf,
        onRemove: () {
          setState(() {
            _selectedFile = null;
          });
        },
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.upload_file_outlined, size: 48),

            const SizedBox(height: 14),

            const Text(
              'Add your document',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Camera'),
                ),

                OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),

                OutlinedButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('PDF'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// DATE FIELD
// ------------------------------------------------------------

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: const InputDecoration(
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ).copyWith(labelText: label),
        child: Text(
          date == null
              ? 'Select date'
              : '${date!.day.toString().padLeft(2, '0')}/'
                    '${date!.month.toString().padLeft(2, '0')}/'
                    '${date!.year}',
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// SELECTED FILE PREVIEW
// ------------------------------------------------------------

class _SelectedFilePreview extends StatelessWidget {
  final File file;
  final bool isPdf;
  final VoidCallback onRemove;

  const _SelectedFilePreview({
    required this.file,
    required this.isPdf,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (isPdf)
            const SizedBox(
              height: 180,
              child: Center(child: Icon(Icons.picture_as_pdf, size: 80)),
            )
          else
            Image.file(
              file,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    file.path.split(Platform.pathSeparator).last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
