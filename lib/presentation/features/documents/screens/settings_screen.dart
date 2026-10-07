import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

import '../../../../data/services/backup_restore_service.dart';
import '../../../../dependency_injection/injection_container.dart';
import 'pin_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/app_lock_service.dart';
import '../providers/document_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _storageText = 'Calculating...';
  bool _appLockEnabled = false;
  bool _isBackupRestoreLoading = false;
  AppLockType? _appLockType;
  bool _hasPocketDocsPin = false;
  final AppLockService _appLockService = AppLockService();
  @override
  void initState() {
    super.initState();

    _loadStorage();
    _loadAppLockState();
  }

  Future<void> _loadStorage() async {
    final directory = await getApplicationDocumentsDirectory();
    final bytes = await _directorySize(directory);

    if (!mounted) return;

    setState(() {
      _storageText = _formatBytes(bytes);
    });
  }

  Future<void> _loadAppLockState() async {
    final enabled = await _appLockService.isEnabled();
    final type = await _appLockService.getLockType();
    final hasPin = await _appLockService.hasPin();

    if (!mounted) return;

    setState(() {
      _appLockEnabled = enabled;
      _appLockType = type;
      _hasPocketDocsPin = hasPin;
    });
  }

  Future<int> _directorySize(Directory directory) async {
    if (!await directory.exists()) return 0;

    var total = 0;

    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }

    return total;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _showAppLockUI() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final deviceIsActive =
            _appLockEnabled && _appLockType == AppLockType.device;
        final pinIsActive =
            _appLockEnabled && _appLockType == AppLockType.pin;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 13),
                    const Expanded(
                      child: Text(
                        'App Lock',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Only one App Lock method is active at a time. Device authentication is required to change or disable App Lock.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                _SecurityOptionTile(
                  icon: Icons.fingerprint_rounded,
                  title: deviceIsActive
                      ? 'Disable Device Authentication'
                      : 'Use Device Authentication',
                  subtitle: deviceIsActive
                      ? 'Authenticate with your device to disable App Lock'
                      : 'Authenticate with your device to enable or switch to this method',
                  trailing: deviceIsActive
                      ? Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.primary,
                  )
                      : Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _handleDeviceAuthentication();
                  },
                ),
                const SizedBox(height: 8),
                _SecurityOptionTile(
                  icon: Icons.pin_outlined,
                  title: pinIsActive
                      ? 'Change PocketDocs PIN'
                      : 'Use PocketDocs PIN',
                  subtitle: pinIsActive
                      ? 'Device authentication is required before changing it'
                      : 'Authenticate with your device, then create a 5-digit PIN',
                  trailing: pinIsActive
                      ? Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.primary,
                  )
                      : const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    final hadPin = _hasPocketDocsPin;
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const PinSetupScreen(),
                      ),
                    );

                    if (result == true && mounted) {
                      await _loadAppLockState();
                      if (!mounted) return;

                      final message = !hadPin && _hasPocketDocsPin
                          ? 'PocketDocs PIN enabled.'
                          : hadPin && !_hasPocketDocsPin
                          ? 'PocketDocs PIN disabled.'
                          : hadPin
                          ? 'PocketDocs PIN changed.'
                          : 'PocketDocs PIN enabled.';

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDeviceAuthentication() async {
    if (_appLockEnabled && _appLockType == AppLockType.device) {
      await _disableDeviceAuthentication();
      return;
    }

    final canAuthenticate =
    await _appLockService.canAuthenticateWithDevice();

    if (!mounted) return;

    if (!canAuthenticate) {
      _showDeviceAuthenticationRequired();
      return;
    }

    final authenticated = await _appLockService.authenticateWithDevice(
      localizedReason: 'Authenticate to change PocketDocs security settings',
    );

    if (!mounted) return;

    if (!authenticated) {
      _showComingSoon(
        'Authentication failed. App Lock was not changed.',
      );
      return;
    }

    await _appLockService.enableDeviceLock();

    if (!mounted) return;

    setState(() {
      _appLockEnabled = true;
      _appLockType = AppLockType.device;
      _hasPocketDocsPin = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Device authentication enabled.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _disableDeviceAuthentication() async {
    final canAuthenticate =
    await _appLockService.canAuthenticateWithDevice();

    if (!mounted) return;

    if (!canAuthenticate) {
      _showDeviceAuthenticationRequired();
      return;
    }

    final authenticated = await _appLockService.authenticateWithDevice(
      localizedReason: 'Authenticate to disable PocketDocs App Lock',
    );

    if (!mounted) return;

    if (!authenticated) {
      _showComingSoon(
        'Authentication failed. App Lock remains enabled.',
      );
      return;
    }

    await _appLockService.disableLock();

    if (!mounted) return;

    setState(() {
      _appLockEnabled = false;
      _appLockType = null;
      _hasPocketDocsPin = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App Lock disabled.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeviceAuthenticationRequired() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Device authentication required'),
        content: const Text(
          'Set up a fingerprint, face unlock, or device PIN/password in your device settings before creating or changing a PocketDocs PIN.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _backupDocuments() async {
    if (_isBackupRestoreLoading) return;

    setState(() {
      _isBackupRestoreLoading = true;
    });

    print('========== POCKETDOCS BACKUP START ==========');

    try {
      final backupService = sl<BackupRestoreService>();

      print('Creating backup...');

      final backupFile = await backupService.createBackup();

      print('Backup created.');
      print('Backup path: ${backupFile.path}');
      print('Backup name: ${path.basename(backupFile.path)}');
      print('Backup extension: ${path.extension(backupFile.path)}');
      print('Backup exists: ${await backupFile.exists()}');
      print('Backup size: ${await backupFile.length()} bytes');

      if (!mounted) return;

      print('Opening share sheet...');

      await Share.shareXFiles(
        [
          XFile(backupFile.path),
        ],
        text: 'PocketDocs backup',
        subject: 'PocketDocs Backup',
      );

      print('Share.shareXFiles completed.');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup created successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      print('Backup success SnackBar shown.');
    } catch (e, stackTrace) {
      print('========== BACKUP ERROR ==========');
      print('Error: $e');
      print('StackTrace: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup failed: ${_cleanErrorMessage(e)}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      print('========== POCKETDOCS BACKUP END ==========');

      if (mounted) {
        setState(() {
          _isBackupRestoreLoading = false;
        });

        await _loadStorage();
      }
    }
  }
  Future<void> _restoreBackup() async {
    if (_isBackupRestoreLoading) return;

    print('========== POCKETDOCS RESTORE START ==========');

    try {
      print('Opening file picker...');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: false,
      );

      if (result == null) {
        print('File picker cancelled.');
        return;
      }

      print('File picker returned.');
      print('Number of files: ${result.files.length}');

      final pickedFile = result.files.single;

      print('---------------- PICKED FILE DEBUG ----------------');
      print('File name: ${pickedFile.name}');
      print('File path: ${pickedFile.path}');
      print('File extension: ${path.extension(pickedFile.name)}');
      print('File size from picker: ${pickedFile.size}');
      print('Bytes available: ${pickedFile.bytes != null}');
      print('Identifier: ${pickedFile.identifier}');
      print('---------------- END PICKED FILE DEBUG ----------------');

      if (pickedFile.path == null) {
        print('ERROR: FilePicker returned null path.');
        throw Exception('Unable to access the selected backup file.');
      }

      final file = File(pickedFile.path!);

      print('Actual File path: ${file.path}');
      print('Actual file exists: ${await file.exists()}');

      if (await file.exists()) {
        print('Actual file size: ${await file.length()} bytes');
      }

      print(
        'Filename ends with .pocketdocs: '
            '${pickedFile.name.toLowerCase().endsWith('.pocketdocs')}',
      );

      print(
        'Path ends with .pocketdocs: '
            '${file.path.toLowerCase().endsWith('.pocketdocs')}',
      );

      // TEMPORARILY DO NOT REJECT BASED ON EXTENSION.
      //
      // We will let BackupRestoreService inspect the actual archive.
      // This is more reliable for files coming from Google Drive.

      if (!mounted) return;

      print('Showing restore confirmation...');

      final confirmed = await _showRestoreConfirmation();

      print('Restore confirmation result: $confirmed');

      if (confirmed != true || !mounted) {
        print('Restore cancelled by user.');
        return;
      }

      setState(() {
        _isBackupRestoreLoading = true;
      });

      print('Calling BackupRestoreService.restoreBackup()...');
      print('Restore file: ${file.path}');

      final backupService = sl<BackupRestoreService>();

      await backupService.restoreBackup(file);

      print('restoreBackup() completed successfully.');

      if (!mounted) return;

      final provider = context.read<DocumentProvider>();

      print('Reloading documents...');
      await provider.loadDocuments();

      print('Reloading folders...');
      await provider.loadFolders();

      print('Reloading categories...');
      await provider.loadCategories();

      await _loadStorage();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup restored successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      print('Restore success SnackBar shown.');
    } catch (e, stackTrace) {
      print('========== RESTORE ERROR ==========');
      print('Error: $e');
      print('StackTrace: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restore failed: ${_cleanErrorMessage(e)}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      print('========== POCKETDOCS RESTORE END ==========');

      if (mounted) {
        setState(() {
          _isBackupRestoreLoading = false;
        });
      }
    }
  }

  Future<bool?> _showRestoreConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme =
            Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: const Text(
            'Restore backup?',
          ),
          content: const Text(
            'Restoring this backup will replace all current PocketDocs documents, folders, and categories with the data in the backup.\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );
  }
  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(
        'Exception: '.length,
      );
    }

    return message;
  }
  void _showComingSoon(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        final colorScheme = Theme.of(context).colorScheme;

        return AlertDialog(
          title: const Text('Delete all documents?'),
          content: const Text(
            'This permanently removes all saved document records and files.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete all'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<DocumentProvider>();

    final ids = provider.allDocuments
        .map((document) => document.id)
        .whereType<int>()
        .toList();

    for (final id in ids) {
      await provider.deleteDocument(id);
    }

    await _loadStorage();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All documents deleted.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showHowItWorks() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How PocketDocs works',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 18),
              _HelpRow(
                icon: Icons.add_a_photo_outlined,
                title: 'Add',
                text:
                'Capture an image or choose an image/PDF from your device.',
              ),
              _HelpRow(
                icon: Icons.folder_copy_outlined,
                title: 'Organize',
                text:
                'Give the document a title and category so it is easy to find.',
              ),
              _HelpRow(
                icon: Icons.search_rounded,
                title: 'Find',
                text:
                'Use Documents to search, filter and sort your saved files.',
              ),
              _HelpRow(
                icon: Icons.shield_outlined,
                title: 'Offline',
                text:
                'Documents and metadata are stored locally on this device.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          // ----------------------------------------------------------
          // HEADER
          // ----------------------------------------------------------

          Text(
            'Settings',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Manage security, storage and your PocketDocs data.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),

          const SizedBox(height: 26),

          // ----------------------------------------------------------
          // SECURITY
          // ----------------------------------------------------------
          const _SectionTitle('SECURITY'),

          _SettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                leading: _IconBox(
                  icon: Icons.lock_outline_rounded,
                  color: colorScheme.primary,
                ),
                title: const Text(
                  'App Lock',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Text(
                    'Protect PocketDocs with device security or a PIN',
                    style: TextStyle(fontSize: 11.5),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                ),             onTap: _showAppLockUI,
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ----------------------------------------------------------
          // BACKUP & RESTORE
          // ----------------------------------------------------------
          const _SectionTitle('BACKUP & RESTORE'),

          _SettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                leading: _IconBox(
                  icon: Icons.backup_outlined,
                  color: colorScheme.primary,
                ),
                title: const Text(
                  'Backup documents',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Text(
                    'Create a backup of your documents and data',
                    style: TextStyle(fontSize: 11.5),
                  ),
                ),
                trailing: _isBackupRestoreLoading
                    ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                ),
                onTap: _isBackupRestoreLoading
                    ? null
                    : _backupDocuments,
              ),

              Divider(
                height: 1,
                indent: 68,
                color: colorScheme.outlineVariant.withOpacity(.45),
              ),

              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                leading: _IconBox(
                  icon: Icons.restore_outlined,
                  color: colorScheme.primary,
                ),
                title: const Text(
                  'Restore backup',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Text(
                    'Restore your documents from a backup',
                    style: TextStyle(fontSize: 11.5),
                  ),
                ),
                trailing: _isBackupRestoreLoading
                    ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                ),
                onTap: _isBackupRestoreLoading
                    ? null
                    : _restoreBackup,
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ----------------------------------------------------------
          // STORAGE
          // ----------------------------------------------------------
          const _SectionTitle('STORAGE'),

          _SettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                leading: _IconBox(
                  icon: Icons.storage_outlined,
                  color: colorScheme.primary,
                ),
                title: const Text(
                  'Storage used',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Text(
                    'Space currently used by PocketDocs',
                    style: TextStyle(fontSize: 11.5),
                  ),
                ),
                trailing: Text(
                  _storageText,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ----------------------------------------------------------
          // HELP & INFORMATION
          // ----------------------------------------------------------
          const _SectionTitle('HELP & INFORMATION'),

          _SettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                leading: _IconBox(
                  icon: Icons.help_outline_rounded,
                  color: colorScheme.primary,
                ),
                title: const Text(
                  'How PocketDocs works',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Text(
                    'Learn how your documents are stored and organized',
                    style: TextStyle(fontSize: 11.5),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 21),
                onTap: _showHowItWorks,
              ),

              Divider(
                height: 1,
                indent: 68,
                color: colorScheme.outlineVariant.withOpacity(.45),
              ),

              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                leading: _IconBox(
                  icon: Icons.wifi_off_rounded,
                  color: colorScheme.primary,
                ),
                title: const Text(
                  'Offline-first',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Text(
                    'Your documents stay on this device',
                    style: TextStyle(fontSize: 11.5),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ----------------------------------------------------------
          // DANGER ZONE
          // ----------------------------------------------------------
          const _SectionTitle('DANGER ZONE'),

          _SettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                leading: _IconBox(
                  icon: Icons.delete_forever_outlined,
                  color: colorScheme.error,
                  backgroundColor: colorScheme.errorContainer.withOpacity(.65),
                ),
                title: Text(
                  'Delete all documents',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Text(
                    'Permanently remove all saved documents and files',
                    style: TextStyle(fontSize: 11.5),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                  color: colorScheme.error,
                ),
                onTap: _deleteAll,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SETTINGS CARD
// ============================================================================

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

// ============================================================================
// ICON BOX
// ============================================================================

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? backgroundColor;

  const _IconBox({
    required this.icon,
    required this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.primaryContainer.withOpacity(.65),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, size: 21, color: color),
    );
  }
}

// ============================================================================
// SECURITY OPTION
// ============================================================================

class _SecurityOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SecurityOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,

  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 21),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION TITLE
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

// ============================================================================
// HELP ROW
// ============================================================================

class _HelpRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _HelpRow({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: colorScheme.primary),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
