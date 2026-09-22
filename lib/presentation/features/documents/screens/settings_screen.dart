import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/document_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _compressionKey = 'compression_enabled';

  bool _compressionEnabled = true;
  String _storageText = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    final bytes = await _directorySize(directory);

    if (!mounted) return;
    setState(() {
      _compressionEnabled = prefs.getBool(_compressionKey) ?? true;
      _storageText = _formatBytes(bytes);
    });
  }

  Future<void> _setCompression(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compressionKey, value);
    if (!mounted) return;
    setState(() => _compressionEnabled = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Compression will be used for new images.'
              : 'Compression is off for new images.',
        ),
      ),
    );
  }

  Future<int> _directorySize(Directory directory) async {
    if (!await directory.exists()) return 0;
    var total = 0;
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
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
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete all'),
          ),
        ],
      ),
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

    await _loadSettings();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All documents deleted.')),
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
              SizedBox(height: 16),
              _HelpRow(
                icon: Icons.add_a_photo_outlined,
                title: 'Add',
                text: 'Capture an image or choose an image/PDF from your device.',
              ),
              _HelpRow(
                icon: Icons.folder_copy_outlined,
                title: 'Organize',
                text: 'Give the document a title and category so it is easy to find.',
              ),
              _HelpRow(
                icon: Icons.search_rounded,
                title: 'Find',
                text: 'Use Documents to search, filter and sort your saved files.',
              ),
              _HelpRow(
                icon: Icons.shield_outlined,
                title: 'Offline',
                text: 'Documents and metadata are stored locally on this device.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            'Manage storage, backup and app preferences.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('BACKUP & RESTORE'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Backup documents'),
                  subtitle: const Text('Create a local backup file'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Backup UI is ready. Connect your backup/export implementation here.',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('Restore backup'),
                  subtitle: const Text('Restore a previous PocketDocs backup'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Restore UI is ready. Connect your backup import implementation here.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('STORAGE'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.compress_outlined),
                  title: const Text('Image compression'),
                  subtitle: const Text('Compress new images before saving'),
                  trailing: Switch(
                    value: _compressionEnabled,
                    onChanged: _setCompression,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Storage used'),
                  trailing: Text(
                    _storageText,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('HELP & INFORMATION'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: const Text('How PocketDocs works'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showHowItWorks,
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.wifi_off_rounded),
                  title: Text('Offline-first'),
                  subtitle: Text('Your documents stay on this device.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('DANGER ZONE'),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete all documents',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: _deleteAll,
            ),
          ),
        ],
      ),
    );
  }
}

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
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: .7,
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _HelpRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
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
