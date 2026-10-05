import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../datasources/database_helper.dart';
import '../models/divination_record.dart';

/// 占卜歷史紀錄的資料存取層，封裝 [DatabaseHelper] 的 CRUD 操作。
class DivinationHistoryRepository {
  DivinationHistoryRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  Future<void> insert(DivinationRecord record) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseHelper.tableName,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 依 [DivinationRecord.createdAt] 由新到舊排序。
  Future<List<DivinationRecord>> getAll() async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableName,
      orderBy: 'created_at DESC',
    );
    return rows.map(DivinationRecord.fromMap).toList();
  }

  /// 依 [id] 查詢單筆紀錄；查無資料（例如已被刪除）時回傳 null。
  Future<DivinationRecord?> getById(String id) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DivinationRecord.fromMap(rows.first);
  }

  Future<void> delete(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      DatabaseHelper.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final db = await _databaseHelper.database;
    await db.delete(DatabaseHelper.tableName);
  }
}

/// 提供 [DivinationHistoryRepository] 單一實例。
final divinationHistoryRepositoryProvider =
    Provider<DivinationHistoryRepository>((ref) {
      return DivinationHistoryRepository();
    });

/// 占卜歷史清單狀態。`build()` 讀取全部紀錄；[add]/[remove]/[clear]
/// 會在資料庫寫入後重新整理清單，供 Phase 3 畫面直接綁定使用。
class DivinationHistoryNotifier extends AsyncNotifier<List<DivinationRecord>> {
  @override
  Future<List<DivinationRecord>> build() {
    final repository = ref.watch(divinationHistoryRepositoryProvider);
    return repository.getAll();
  }

  Future<void> add(DivinationRecord record) async {
    final repository = ref.read(divinationHistoryRepositoryProvider);
    await repository.insert(record);
    state = await AsyncValue.guard(repository.getAll);
  }

  Future<void> remove(String id) async {
    final repository = ref.read(divinationHistoryRepositoryProvider);
    await repository.delete(id);
    state = await AsyncValue.guard(repository.getAll);
  }

  Future<void> clear() async {
    final repository = ref.read(divinationHistoryRepositoryProvider);
    await repository.clearAll();
    state = await AsyncValue.guard(repository.getAll);
  }
}

final divinationHistoryProvider =
    AsyncNotifierProvider<DivinationHistoryNotifier, List<DivinationRecord>>(
      DivinationHistoryNotifier.new,
    );

/// 依 [id] 查詢單筆占卜歷史紀錄，供歷史詳情頁使用。`autoDispose` 讓
/// provider 在詳情頁離開後釋放，不需要跟 [divinationHistoryProvider]
/// 一樣長駐（列表狀態需要在分頁之間保留，單筆查詢則不需要）。
final divinationRecordProvider = FutureProvider.autoDispose
    .family<DivinationRecord?, String>((ref, id) {
      final repository = ref.watch(divinationHistoryRepositoryProvider);
      return repository.getById(id);
    });
