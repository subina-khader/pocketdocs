import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

import '../../../../data/services/backup_restore_service.dart';
import '../../../../dependency_injection/injection_container.dart';
import '../widgets/help_row.dart';
import '../widgets/restore_password_dialog.dart';
import '../widgets/security_option_tile.dart';
import '../widgets/settings_card.dart';
import '../widgets/settings_icon_box.dart';
import '../widgets/settings_section_title.dart';
import 'pin_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/app_lock_service.dart';
import '../providers/document_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
class SettingsScreen extends StatefulWidget {
  final bool isActive;
  const SettingsScreen({super.key, this.isActive = false,});

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
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive && !oldWidget.isActive) {
      _loadStorage();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStorage();
  }
  @override
  void initState() {
    super.initState();

    _loadStorage();
    _loadAppLockState();
  }

  Future<void> _loadStorage() async {
    try {
      final documentsDirectory =
      await getApplicationDocumentsDirectory();

      final databaseDirectory =
      Directory(await getDatabasesPath());

      final documentsBytes =
      await _directorySize(documentsDirectory);

      final databaseBytes =
      await _directorySize(databaseDirectory);

      final totalBytes = documentsBytes + databaseBytes;

      if (!mounted) return;

      setState(() {
        _storageText = _formatBytes(totalBytes);
      });
    } catch (e) {
      debugPrint('[STORAGE] Failed to calculate storage: $e');

      if (!mounted) return;

      setState(() {
        _storageText = 'Unavailable';
      });
    }
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
                SecurityOptionTile(
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
                SecurityOptionTile(
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

    final password = await _showBackupPasswordDialog();

    if (password == null || !mounted) {
      return;
    }

    setState(() {
      _isBackupRestoreLoading = true;
    });

    try {
      final backupService = sl<BackupRestoreService>();

      final backupFile = await backupService.createBackup(
        password: password,
      );

      if (!mounted) return;

      await Share.shareXFiles(
        [
          XFile(backupFile.path),
        ],
        text: 'PocketDocs encrypted backup',
        subject: 'PocketDocs Backup',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Encrypted backup created successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
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
      if (mounted) {
        setState(() {
          _isBackupRestoreLoading = false;
        });

        await _loadStorage();
      }
    }
  }

  Future<void> _restoreBackup() async {
    if (_isBackupRestoreLoading) {
      debugPrint('[RESTORE] Already running. Ignoring request.');
      return;
    }

    debugPrint('[RESTORE] ===== RESTORE STARTED =====');

    try {
      debugPrint('[RESTORE] Opening file picker...');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null) {
        debugPrint('[RESTORE] File picker cancelled.');
        return;
      }

      if (result.files.isEmpty) {
        debugPrint('[RESTORE] No files returned.');
        return;
      }

      final pickedFile = result.files.single;
      final fileName = pickedFile.name;
      final filePath = pickedFile.path;

      debugPrint('[RESTORE] Selected name: "$fileName"');
      debugPrint('[RESTORE] Selected path: "$filePath"');
      debugPrint('[RESTORE] Extension: "${path.extension(fileName)}"');
      debugPrint('[RESTORE] File size from picker: ${pickedFile.size} bytes');

      if (filePath == null || filePath.isEmpty) {
        debugPrint('[RESTORE] ERROR: Picker returned no usable file path.');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cannot access this file. Select a local .pocketdocs backup.',
              ),
            ),
          );
        }
        return;
      }

      final file = File(filePath);
      final exists = await file.exists();

      debugPrint('[RESTORE] File exists: $exists');

      if (!exists) {
        debugPrint('[RESTORE] ERROR: Selected file does not exist at path.');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot access the selected backup file.'),
            ),
          );
        }
        return;
      }

      final actualLength = await file.length();
      debugPrint('[RESTORE] Actual file size: $actualLength bytes');

      if (actualLength == 0) {
        debugPrint('[RESTORE] ERROR: Selected file is empty.');
        return;
      }

      final header = await file.openRead(0, 5).fold<List<int>>(
        <int>[],
            (previous, bytes) => previous..addAll(bytes),
      );

      debugPrint('[RESTORE] Backup header: $header');

      const expectedHeader = [0x50, 0x44, 0x42, 0x4B, 0x02];

      if (header.length != expectedHeader.length ||
          !List.generate(
            expectedHeader.length,
                (index) => header[index] == expectedHeader[index],
          ).every((matches) => matches)) {
        debugPrint('[RESTORE] Invalid backup file header.');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This file is not a valid PocketDocs backup.',
            ),
          ),
        );
        return;
      }

      debugPrint('[RESTORE] Backup header validated.');

      debugPrint('[RESTORE] Extension validation passed.');

      if (!mounted) return;

      final confirmed = await _showRestoreConfirmation();

      if (confirmed != true || !mounted) {
        debugPrint('[RESTORE] User cancelled confirmation.');
        return;
      }

      debugPrint('[RESTORE] Asking for backup password.');

      final password = await _showRestorePasswordDialog();

      if (password == null || !mounted) {
        debugPrint('[RESTORE] Password dialog cancelled.');
        return;
      }

      debugPrint('[RESTORE] Password entered. Value not logged.');

      setState(() {
        _isBackupRestoreLoading = true;
      });

      debugPrint('[RESTORE] Getting BackupRestoreService.');

      final backupService = sl<BackupRestoreService>();

      debugPrint('[RESTORE] Calling restoreBackup()...');

      await backupService.restoreBackup(
        backupFile: file,
        password: password,
      );

      debugPrint('[RESTORE] restoreBackup() completed successfully.');

      if (!mounted) return;

      final provider = context.read<DocumentProvider>();

      debugPrint('[RESTORE] Reloading documents...');
      await provider.loadDocuments();

      debugPrint('[RESTORE] Reloading folders...');
      await provider.loadFolders();

      debugPrint('[RESTORE] Reloading categories...');
      await provider.loadCategories();

      await _loadStorage();

      debugPrint('[RESTORE] ===== RESTORE COMPLETED =====');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Encrypted backup restored successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('[RESTORE] ERROR: $e');
      debugPrint('[RESTORE] STACK TRACE: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restore failed: ${_cleanErrorMessage(e)}',
          ),
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBackupRestoreLoading = false;
        });
      }

      debugPrint('[RESTORE] ===== RESTORE FLOW ENDED =====');
    }
  }

  Future<String?> _showBackupPasswordDialog() {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final passwordController = TextEditingController();
        final confirmPasswordController = TextEditingController();

        bool obscurePassword = true;
        bool obscureConfirmPassword = true;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create encrypted backup'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Set a password for this backup. '
                          'You will need this password to restore it.',
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Backup password',
                        hintText: 'Minimum 8 characters',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword =
                              !obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),

                FilledButton(
                  onPressed: () {
                    final password =
                    passwordController.text.trim();

                    final confirmPassword =
                    confirmPasswordController.text.trim();

                    if (password.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password must be at least 8 characters.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (password != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Passwords do not match.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop(password);
                  },
                  child: const Text('Create backup'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<String?> _showRestorePasswordDialog() {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RestorePasswordDialog(),
    );
  }  Future<bool?> _showRestoreConfirmation() {
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
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How PocketDocs works',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your personal space for storing and managing documents.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                const HelpRow(
                  icon: Icons.add_a_photo_outlined,
                  title: 'Add documents',
                  text:
                  'Capture images or import PDFs and images '
                      'from your device.',
                ),
                const HelpRow(
                  icon: Icons.folder_copy_outlined,
                  title: 'Organize your files',
                  text:
                  'Add titles, assign categories, and arrange '
                      'documents into folders.',
                ),
                const HelpRow(
                  icon: Icons.search_rounded,
                  title: 'Find and manage',
                  text:
                  'Search, filter, preview, share, and manage '
                      'your saved documents.',
                ),
                const HelpRow(
                  icon: Icons.shield_outlined,
                  title: 'Keep documents private',
                  text:
                  'Your documents stay on your device. Enable '
                      'App Lock for an additional layer of protection.',
                ),
                const HelpRow(
                  icon: Icons.backup_outlined,
                  title: 'Back up and restore',
                  text:
                  'Create a password-protected backup and '
                      'restore your documents when needed.',
                ),

                const SizedBox(height: 8),
              ],
            ),
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
          const SectionTitle('SECURITY'),

          SettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                leading: IconBox(
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
          const SectionTitle('BACKUP & RESTORE'),

          SettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                leading: IconBox(
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
                leading: IconBox(
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
          const SectionTitle('STORAGE'),

          SettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                leading: IconBox(
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
          const SectionTitle('HELP & INFORMATION'),

          SettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                leading: IconBox(
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
                leading: IconBox(
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
          const SectionTitle('DANGER ZONE'),

          SettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                leading: IconBox(
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

