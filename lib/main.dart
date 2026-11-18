import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'dependency_injection/injection_container.dart';
import 'presentation/features/documents/providers/document_provider.dart';
import 'presentation/features/documents/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //	Initializes Flutter's connection with native/platform services
  await initializeDependencies();
  //call initializeDependenciesfunction from injection_container.dart
  runApp(const PocketDocsApp());
}

class PocketDocsApp extends StatelessWidget {
  const PocketDocsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<DocumentProvider>(),
      //sl defined in injection_container.dart which is a  service locator
      child: MaterialApp(
        title: 'PocketDocs',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
