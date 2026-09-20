import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'
    show databaseFactoryFfiWeb;
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sonic_player/core/theme/app_theme.dart';
import 'package:sonic_player/core/router/app_router.dart';
import 'package:sonic_player/services/database/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize SQLite: use web factory on web, default on native.
  // On web the WASM worker requires SharedArrayBuffer (COOP/COEP headers).
  // We wrap in try-catch so the app still launches even if the DB isn't
  // available (e.g., in restricted browser environments).
  if (kIsWeb) {
    try {
      databaseFactory = databaseFactoryFfiWeb;
      await DatabaseService().database;
    } catch (e) {
      debugPrint('SQLite web init skipped: $e');
    }
  } else {
    await DatabaseService().database;
  }

  if (!kIsWeb) {
    // Set system UI overlay style for dark theme (native only)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Lock to portrait for now (can be unlocked later)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const ProviderScope(child: SonicPlayerApp()));
}

class SonicPlayerApp extends StatelessWidget {
  const SonicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sonic Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
