import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _initializeDatabaseFactory();
  runApp(const ProviderScope(child: MyApp()));
}

/// 純 `sqflite` 只有 Android/iOS 原生實作，桌面／Web 都要額外指定
/// [databaseFactory] 才能用；這裡照平台切換成對應的 FFI 實作，讓
/// [DatabaseHelper] 裡的 `openDatabase()`／`getDatabasesPath()` 在所有
/// 平台上都指向同一份可用的 factory。Android／iOS 維持預設值不動。
void _initializeDatabaseFactory() {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '易經占卜',
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
