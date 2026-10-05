import 'package:flutter_test/flutter_test.dart';
import 'package:guiding_the_unknown_path/data/datasources/database_helper.dart';
import 'package:guiding_the_unknown_path/data/models/divination_record.dart';
import 'package:guiding_the_unknown_path/data/repositories/divination_history_repository.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

DivinationRecord _buildRecord({
  String id = 'test-id-1',
  DateTime? createdAt,
}) {
  return DivinationRecord(
    id: id,
    createdAt: createdAt ?? DateTime(2026, 1, 1, 12),
    benGuaKey: '14',
    benGuaName: '䷛ 大過卦-澤風大過',
    zhiGuaKey: '04',
    zhiGuaName: '䷫ 姤卦-天風姤',
    dongYaoIndexes: const [0],
    yaosRaw: const ['⚋*', '⚊', '⚊', '⚊', '⚊', '⚋'],
    interpretation: '一爻變，本卦 上爻 爻辭占',
    judgementText: '大吉之象',
    explanation: '測試用解釋文字',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // 每個測試前重置資料庫，確保彼此獨立、不互相污染。
  setUp(() async {
    await DatabaseHelper.instance.close();
    final dbPath = path.join(
      await getDatabasesPath(),
      'guiding_the_unknown_path.db',
    );
    await databaseFactory.deleteDatabase(dbPath);
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  test('insert 後 getAll 能正確讀回同一筆資料', () async {
    final repository = DivinationHistoryRepository();
    final record = _buildRecord();

    await repository.insert(record);
    final all = await repository.getAll();

    expect(all, hasLength(1));
    expect(all.single, record);
  });

  test('getAll 依 createdAt 倒序排列（新的在前）', () async {
    final repository = DivinationHistoryRepository();
    final older = _buildRecord(
      id: 'older',
      createdAt: DateTime(2026, 1, 1),
    );
    final newer = _buildRecord(
      id: 'newer',
      createdAt: DateTime(2026, 2, 1),
    );

    await repository.insert(older);
    await repository.insert(newer);

    final all = await repository.getAll();
    expect(all.map((record) => record.id).toList(), ['newer', 'older']);
  });

  test('delete 後該筆消失', () async {
    final repository = DivinationHistoryRepository();
    final record = _buildRecord();
    await repository.insert(record);
    expect(await repository.getAll(), hasLength(1));

    await repository.delete(record.id);

    expect(await repository.getAll(), isEmpty);
  });

  test('getById 找得到時回傳對應紀錄', () async {
    final repository = DivinationHistoryRepository();
    final record = _buildRecord();
    await repository.insert(record);

    final found = await repository.getById(record.id);

    expect(found, record);
  });

  test('getById 查無資料時回傳 null', () async {
    final repository = DivinationHistoryRepository();

    final found = await repository.getById('不存在的 id');

    expect(found, isNull);
  });

  test('clearAll 清空所有紀錄', () async {
    final repository = DivinationHistoryRepository();
    await repository.insert(_buildRecord(id: 'a'));
    await repository.insert(_buildRecord(id: 'b'));

    await repository.clearAll();

    expect(await repository.getAll(), isEmpty);
  });
}
