import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// 占卜歷史紀錄的本地 sqlite 資料庫存取。全域使用單一實例（[instance]）。
class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String tableName = 'divination_records';

  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, 'guiding_the_unknown_path.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id TEXT PRIMARY KEY,
            created_at TEXT NOT NULL,
            ben_gua_key TEXT NOT NULL,
            ben_gua_name TEXT NOT NULL,
            zhi_gua_key TEXT,
            zhi_gua_name TEXT,
            dong_yao_indexes TEXT NOT NULL,
            yaos_raw TEXT NOT NULL,
            interpretation TEXT NOT NULL,
            judgement_text TEXT NOT NULL,
            explanation TEXT NOT NULL,
            note TEXT
          )
        ''');
      },
    );
  }

  /// 關閉資料庫連線；主要供測試在各案例間重置狀態使用。
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
