import 'package:flutter_test/flutter_test.dart';
import 'package:guiding_the_unknown_path/data/datasources/gua_data_source.dart';
import 'package:guiding_the_unknown_path/domain/logic/gua_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GuaCalculator calculator;
  late GuaDataSource dataSource;

  setUpAll(() async {
    dataSource = GuaDataSource();
    await dataSource.loadAll();
    calculator = GuaCalculator(
      wheelSegments: dataSource.wheelSegments,
      segmentsMap: dataSource.segmentsMap,
      guaMap: dataSource.guaMap,
      guaCi: dataSource.guaCi,
      guaYaoData: dataSource.guaYaoData,
    );
  });

  test('0 爻變：無動爻，以本卦卦辭占（含大於一圈的負角度正規化）', () {
    // 上=idx1, 五=idx1(以 -450° 測試超過一圈的負角度正規化), 四=idx0,
    // 三=idx1, 二=idx0, 初=idx0。六爻皆落在非動爻區段。
    //
    // 注意：angleToSegmentIndex() 是「先取負號再正規化」（見該函式文件
    // 註解），所以這裡的角度不是憑感覺選的隨機數字，而是刻意反推出能
    // 命中 idx1／idx0 的值：idx1 用 -90（因為 -(-90)=90，90/60 取整為
    // 1），idx0 用 0。
    final result = calculator.calculate([
      -90.0,
      -450.0,
      0.0,
      -90.0,
      0.0,
      0.0,
    ]);

    expect(result.benGuaKey, '14');
    expect(result.zhiGuaKey, isNull);
    expect(result.zhiGuaName, isNull);
    expect(result.dongYaoIndexes, isEmpty);
    expect(result.interpretation, '無動爻，以本卦卦辭占');
    expect(result.judgementYaoText, isNull);
    expect(result.judgementExplain, dataSource.guaCi['14']!.ci);
  });

  test('1 爻變：本卦上爻爻辭占', () {
    // 與 0 爻變案例相同的乾淨爻象，但上爻改落在動爻區段（idx0，用角度
    // 0 命中），benGuaKey 應維持不變，僅新增一個動爻。
    final result = calculator.calculate([0.0, -90.0, 0.0, -90.0, 0.0, 0.0]);

    expect(result.benGuaKey, '14');
    expect(result.dongYaoIndexes, [0]);
    expect(result.zhiGuaKey, '04');
    expect(result.interpretation, '一爻變，本卦 上爻 爻辭占');
    expect(result.judgementYaoText, '上爻');
    expect(result.judgementExplain, dataSource.guaYaoData['14']![0]);
  });

  test('3 爻變：本卦之卦卦辭合占', () {
    // 上=idx0, 五=idx1, 四=idx1, 三=idx1, 二=idx0, 初=idx1。
    final result = calculator.calculate([
      0.0,
      -90.0,
      -90.0,
      -90.0,
      0.0,
      -90.0,
    ]);

    expect(result.benGuaKey, '14');
    expect(result.dongYaoIndexes, [0, 2, 5]);
    expect(result.zhiGuaKey, '40');
    expect(result.interpretation, '三爻變，本卦之卦卦辭合占');
    expect(result.judgementYaoText, isNull);
    expect(
      result.judgementExplain,
      '本卦：${dataSource.guaCi['14']!.ci}\n之卦：${dataSource.guaCi['40']!.ci}',
    );
  });

  test('6 爻變：以之卦卦辭占', () {
    // 上=idx0, 五=idx2, 四=idx1, 三=idx0, 二=idx2, 初=idx1
    // （idx2 用 -150：-(-150)=150，150/60 取整為 2）。
    final result = calculator.calculate([
      0.0,
      -150.0,
      -90.0,
      0.0,
      -150.0,
      -90.0,
    ]);

    expect(result.benGuaKey, '16');
    expect(result.dongYaoIndexes, [0, 1, 2, 3, 4, 5]);
    expect(result.zhiGuaKey, '61');
    expect(result.interpretation, '六爻變，以之卦卦辭占');
    expect(result.judgementYaoText, isNull);
    expect(result.judgementExplain, dataSource.guaCi['61']!.ci);
  });

  group('angleToSegmentIndex：轉盤角度換算成扇形區塊索引', () {
    test('角度 0 對應 index 0（完全不轉）', () {
      expect(angleToSegmentIndex(0), 0);
    });

    test('角度 180 對應 index 3', () {
      // -(180) = -180，正規化到 [0,360) 是 180，180/60 取整為 3。
      expect(angleToSegmentIndex(180), 3);
    });

    test('每 60 度整數邊界對應遞增的 index（0~5）', () {
      for (var i = 0; i < 6; i++) {
        // 用負角度反推：angleToSegmentIndex(-i*60) 應該命中 index i。
        expect(angleToSegmentIndex(-(i * 60.0)), i);
      }
    });

    test('超過一整圈或負角度都能正確正規化', () {
      expect(angleToSegmentIndex(-720), 0); // 轉兩圈回到原點。
      expect(angleToSegmentIndex(720), 0);
      expect(angleToSegmentIndex(-90 - 720), 1); // 帶正規化的 idx1。
    });

    test(
      '強制角度=0：實際占卜結果的上爻應該直接取 wheelSegments 的 index 0'
      '（segments_up[0]，老陰動爻 ⚋*）',
      () {
        final result = calculator.calculate(List.filled(6, 0.0));

        expect(
          dataSource.wheelSegments['segments_up']![0],
          '⚋*',
          reason: '這是驗證用的前提假設：真實 asset 資料裡 segments_up[0] '
              '本來就是 ⚋*，不是這個測試自己編的。',
        );
        expect(result.yaosRaw[0], dataSource.wheelSegments['segments_up']![0]);
      },
    );

    test(
      '強制角度=180：上爻應該取 wheelSegments 的 index 3（依公式反推）',
      () {
        final result = calculator.calculate([180.0, 0.0, 0.0, 0.0, 0.0, 0.0]);

        expect(angleToSegmentIndex(180), 3);
        expect(result.yaosRaw[0], dataSource.wheelSegments['segments_up']![3]);
      },
    );
  });

  group('judgementYaoIndexFor：供歷史紀錄回放重組 DivinationResult 使用', () {
    test('0／3／6 爻變沒有單一爻位，回傳 null', () {
      expect(judgementYaoIndexFor(const []), isNull);
      expect(judgementYaoIndexFor(const [0, 2, 5]), isNull);
      expect(judgementYaoIndexFor(const [0, 1, 2, 3, 4, 5]), isNull);
    });

    test('1 爻變：回傳該動爻索引', () {
      expect(judgementYaoIndexFor(const [3]), 3);
    });

    test('2 爻變：回傳較小的動爻索引（位階較高者）', () {
      expect(judgementYaoIndexFor(const [1, 4]), 1);
    });

    test('4 爻變：回傳不變的兩爻中索引較大者（位階較低者）', () {
      // 動爻 [0,1,2,3]，不變的是 [4,5]，取較大者 5。
      expect(judgementYaoIndexFor(const [0, 1, 2, 3]), 5);
    });

    test('5 爻變：回傳唯一不變的那一爻索引', () {
      // 動爻 [0,1,2,3,5]，唯一不變的是 4。
      expect(judgementYaoIndexFor(const [0, 1, 2, 3, 5]), 4);
    });
  });
}
