import 'package:flutter_test/flutter_test.dart';
import 'package:guiding_the_unknown_path/data/datasources/gua_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GuaDataSource.loadAll 讀取並正確解析 assets/data 底下的 6 個 JSON 檔', () async {
    final dataSource = GuaDataSource();
    expect(dataSource.isLoaded, isFalse);

    await dataSource.loadAll();

    expect(dataSource.isLoaded, isTrue);

    final guaCi = dataSource.guaCi['10']!;
    expect(guaCi.name, '夬');
    expect(guaCi.ci, isNotEmpty);
    expect(guaCi.explain, isNotEmpty);

    expect(dataSource.guaYaoData['10'], hasLength(6));

    expect(dataSource.guaMap['10'], contains('夬'));

    final yaoExplain = dataSource.yaoExplainGeneral['上爻']!;
    expect(yaoExplain.stage, '反思期');
    expect(yaoExplain.position, '最高位');

    final segment = dataSource.segmentsMap['100']!;
    expect(segment[0], '☶');
    expect(segment[1], 6);

    expect(
      dataSource.wheelSegments.keys,
      containsAll(<String>[
        'segments_up',
        'segments_five',
        'segments_four',
        'segments_three',
        'segments_two',
        'segments_first',
      ]),
    );
    expect(dataSource.wheelSegments['segments_up'], hasLength(6));
  });

  test('loadAll 重複呼叫不會重新讀取（維持同一份快取）', () async {
    final dataSource = GuaDataSource();
    await dataSource.loadAll();
    final firstGuaCi = dataSource.guaCi;

    await dataSource.loadAll();

    expect(identical(dataSource.guaCi, firstGuaCi), isTrue);
  });
}
