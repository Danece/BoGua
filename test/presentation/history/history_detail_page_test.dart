import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiding_the_unknown_path/data/datasources/gua_data_source.dart';
import 'package:guiding_the_unknown_path/data/models/divination_record.dart';
import 'package:guiding_the_unknown_path/data/repositories/divination_history_repository.dart';
import 'package:guiding_the_unknown_path/presentation/history/history_detail_page.dart';

/// 純記憶體的假 repository，理由同
/// test/presentation/history/history_page_test.dart：sqflite_common_ffi
/// 在 testWidgets() 的 fake-async 環境下無法正常 resolve。
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
  Future<DivinationRecord?> getById(String id) async {
    for (final record in _records) {
      if (record.id == id) return record;
    }
    return null;
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

DivinationRecord _buildRecord({String id = 'test-id', DateTime? createdAt}) {
  return DivinationRecord(
    id: id,
    createdAt: createdAt ?? DateTime(2026, 3, 5, 9, 30),
    benGuaKey: '14',
    benGuaName: '大過卦',
    zhiGuaKey: '04',
    zhiGuaName: '姤卦',
    dongYaoIndexes: const [0],
    yaosRaw: const ['⚋*', '⚊', '⚊', '⚊', '⚊', '⚋'],
    interpretation: '一爻變，本卦 上爻 爻辭占',
    judgementText: '棟橈，利有攸往，亨，大吉之象',
    explanation: '測試用解釋',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // GuaDataSource.loadAll() 會透過 rootBundle 讀真正的 asset 檔。同一個
  // GuaDataSource「新實例」在同一支測試檔裡對 rootBundle 重複發出讀取，
  // 在 testWidgets() 的環境下第二次會卡死不回應（Windows 上曾實測重現）。
  // 因此全檔共用同一份已載入好的資料，只在 setUpAll 讀一次，之後每個
  // test 都用 guaDataSourceProvider.overrideWith 直接回傳它，不再重新
  // 觸發 I/O。
  late GuaDataSource sharedDataSource;

  setUpAll(() async {
    sharedDataSource = GuaDataSource();
    await sharedDataSource.loadAll();
  });

  Widget buildApp({
    required String initialLocation,
    required _FakeDivinationHistoryRepository repository,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/history',
          builder: (context, state) => const Text('歷史列表頁'),
        ),
        GoRoute(
          path: '/history/:id',
          builder: (context, state) =>
              HistoryDetailPage(id: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);

    return ProviderScope(
      overrides: [
        divinationHistoryRepositoryProvider.overrideWithValue(repository),
        guaDataSourceProvider.overrideWith((ref) => sharedDataSource),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('顯示完整占卜結果：AppBar 時間、本卦、占法、判斷依據', (tester) async {
    final record = _buildRecord();
    final repository = _FakeDivinationHistoryRepository([record]);

    await tester.pumpWidget(
      buildApp(
        initialLocation: '/history/${record.id}',
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026/03/05 09:30'), findsOneWidget);
    expect(find.textContaining('大過卦'), findsWidgets);
    expect(find.text('一爻變，本卦 上爻 爻辭占'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('查無資料時顯示錯誤提示，點擊按鈕可返回列表頁', (tester) async {
    final repository = _FakeDivinationHistoryRepository();

    await tester.pumpWidget(
      buildApp(initialLocation: '/history/not-exist', repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('找不到這筆紀錄，可能已經被刪除'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNothing);

    await tester.tap(find.text('返回列表頁'));
    await tester.pumpAndSettle();

    expect(find.text('歷史列表頁'), findsOneWidget);
  });

  testWidgets('點擊刪除並確認後，紀錄從 repository 移除並返回列表頁', (tester) async {
    final record = _buildRecord();
    final repository = _FakeDivinationHistoryRepository([record]);

    await tester.pumpWidget(
      buildApp(
        initialLocation: '/history/${record.id}',
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('刪除這筆紀錄'), findsOneWidget);
    await tester.tap(find.text('確定'));
    await tester.pumpAndSettle();

    expect(find.text('歷史列表頁'), findsOneWidget);
    expect(await repository.getById(record.id), isNull);
  });

  testWidgets('點擊刪除但取消時，紀錄仍保留在詳情頁', (tester) async {
    final record = _buildRecord();
    final repository = _FakeDivinationHistoryRepository([record]);

    await tester.pumpWidget(
      buildApp(
        initialLocation: '/history/${record.id}',
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(await repository.getById(record.id), isNotNull);
  });
}
