import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiding_the_unknown_path/data/models/divination_record.dart';
import 'package:guiding_the_unknown_path/data/repositories/divination_history_repository.dart';
import 'package:guiding_the_unknown_path/presentation/history/history_page.dart';

/// 純記憶體的假 repository，讓 widget test 不需要碰真正的 sqflite 資料庫
/// （sqflite_common_ffi 在 `testWidgets()` 的 fake-async 環境下無法正常
/// resolve，見 test/data/divination_history_repository_test.dart 裡
/// 用 `test()` 搭配真實資料庫的整合測試）。
class _FakeDivinationHistoryRepository extends DivinationHistoryRepository {
  _FakeDivinationHistoryRepository([List<DivinationRecord> initial = const []])
    : _records = List.of(initial);

  final List<DivinationRecord> _records;

  @override
  Future<void> insert(DivinationRecord record) async {
    _records.removeWhere((r) => r.id == record.id);
    _records.add(record);
  }

  @override
  Future<List<DivinationRecord>> getAll() async {
    final sorted = List<DivinationRecord>.of(_records)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  @override
  Future<void> delete(String id) async {
    _records.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> clearAll() async {
    _records.clear();
  }
}

DivinationRecord _buildRecord({
  required String id,
  required DateTime createdAt,
  List<int> dongYaoIndexes = const [],
  String? zhiGuaName,
}) {
  return DivinationRecord(
    id: id,
    createdAt: createdAt,
    benGuaKey: '14',
    benGuaName: '大過卦',
    zhiGuaKey: zhiGuaName == null ? null : '04',
    zhiGuaName: zhiGuaName,
    dongYaoIndexes: dongYaoIndexes,
    yaosRaw: const ['⚋', '⚊', '⚊', '⚊', '⚊', '⚋'],
    interpretation: '無動爻，以本卦卦辭占',
    judgementText: '棟橈,利有攸往,亨',
    explanation: '測試用解釋',
  );
}

Widget _buildApp([List<DivinationRecord> seed = const []]) {
  return ProviderScope(
    overrides: [
      divinationHistoryRepositoryProvider.overrideWithValue(
        _FakeDivinationHistoryRepository(seed),
      ),
    ],
    child: const MaterialApp(home: HistoryPage()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('空歷史時顯示友善的空狀態畫面', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('還沒有占卜紀錄，去問問看吧'), findsOneWidget);
  });

  testWidgets('有紀錄時顯示卡片：卦名、時間、動爻摘要、之卦', (tester) async {
    await tester.pumpWidget(
      _buildApp([
        _buildRecord(
          id: 'a',
          createdAt: DateTime(2026, 1, 2, 15, 30),
          dongYaoIndexes: const [1, 3],
          zhiGuaName: '小畜卦',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('大過卦'), findsOneWidget);
    expect(find.text('2026/01/02 15:30'), findsOneWidget);
    expect(find.text('動爻：五爻、三爻'), findsOneWidget);
    expect(find.text('→ 變卦：小畜卦'), findsOneWidget);
  });

  testWidgets('無動爻時顯示「無動爻」', (tester) async {
    await tester.pumpWidget(
      _buildApp([_buildRecord(id: 'b', createdAt: DateTime(2026, 1, 1))]),
    );
    await tester.pumpAndSettle();

    expect(find.text('無動爻'), findsOneWidget);
  });

  testWidgets('左滑跳出確認對話框，取消時紀錄仍保留', (tester) async {
    await tester.pumpWidget(
      _buildApp([_buildRecord(id: 'c', createdAt: DateTime(2026, 1, 1))]),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.text('大過卦'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('刪除這筆紀錄'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('大過卦'), findsOneWidget);
  });

  testWidgets('左滑並確認刪除後，紀錄從畫面移除', (tester) async {
    await tester.pumpWidget(
      _buildApp([_buildRecord(id: 'd', createdAt: DateTime(2026, 1, 1))]),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.text('大過卦'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('確定'));
    await tester.pumpAndSettle();

    expect(find.text('大過卦'), findsNothing);
    expect(find.text('還沒有占卜紀錄，去問問看吧'), findsOneWidget);
  });

  testWidgets('點擊清空全部並確認後，畫面顯示空狀態', (tester) async {
    await tester.pumpWidget(
      _buildApp([_buildRecord(id: 'e', createdAt: DateTime(2026, 1, 1))]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pumpAndSettle();

    expect(find.text('清空全部紀錄'), findsOneWidget);

    await tester.tap(find.text('確定'));
    await tester.pumpAndSettle();

    expect(find.text('還沒有占卜紀錄，去問問看吧'), findsOneWidget);
  });
}
