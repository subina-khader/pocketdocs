import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/services/app_lock_service.dart';
import '../widgets/home_content.dart';
import 'folder_management_screen.dart';
import '../../../../domain/entities/document.dart';
import '../providers/document_provider.dart';
import '../widgets/document_album_tile.dart';
import '../widgets/document_list_tile.dart';
import '../widgets/folder_list_tile.dart';
import 'add_document_screen.dart';
import 'document_details_screen.dart';
import 'documents_screen.dart';
import 'folder_documents_screen.dart';
import 'settings_screen.dart';
import 'category_management_screen.dart';
import 'app_lock_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>  with WidgetsBindingObserver {
  int _index = 0;
  bool _shouldLockOnResume = false;
  bool _isShowingLock = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().loadData();
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _shouldLockOnResume = true;
      return;
    }

    if (state == AppLifecycleState.resumed &&
        _shouldLockOnResume) {
      _shouldLockOnResume = false;
      _showAppLock();
    }
  }
  Future<void> _showAppLock() async {
    if (_isShowingLock || !mounted) return;

    final appLockService = AppLockService();

    final isEnabled = await appLockService.isEnabled();

    if (!isEnabled || !mounted) return;

    _isShowingLock = true;

    try {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const AppLockScreen(),
          fullscreenDialog: true,
        ),
      );
    } finally {
      _isShowingLock = false;
    }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeContent(),
      const DocumentsScreen(),
      SettingsScreen(
        isActive: _index == 2,
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddDocumentScreen()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description_rounded),
            label: 'Documents',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}


