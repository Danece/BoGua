import 'package:flutter_test/flutter_test.dart';
import 'package:guiding_the_unknown_path/data/datasources/gua_data_source.dart';
import 'package:guiding_the_unknown_path/domain/logic/yao_explainer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late YaoExplainer explainer;
  late GuaDataSource dataSource;

  setUpAll(() async {
    dataSource = GuaDataSource();
    await dataSource.loadAll();
    explainer = YaoExplainer(yaoExplainGeneral: dataSource.yaoExplainGeneral);
  });

  test('查得到爻位（上爻）的通用階段資料', () {
    final result = explainer.explain(yaoIndex: 0, yaoText: '潛龍勿用');
    final general = dataSource.yaoExplainGeneral['上爻']!;

    expect(result.stage, general.stage);
    expect(result.position, general.position);
    expect(result.meaning, general.meaning);
    expect(result.advice, general.advice);
  });

  test('不含凶且含吉 → 大吉之象', () {
    final result = explainer.explain(yaoIndex: 0, yaoText: '元亨,吉,無不利');
    expect(result.judgementLabel, '大吉之象');
    expect(result.actionItems, isNotEmpty);
  });

  test('含凶 → 凶險之象', () {
    final result = explainer.explain(yaoIndex: 1, yaoText: '有凶,無攸利');
    expect(result.judgementLabel, '凶險之象');
  });

  test('同時含吉與凶時，凶的優先序較高 → 凶險之象', () {
    final result = explainer.explain(yaoIndex: 1, yaoText: '先吉後有凶');
    expect(result.judgementLabel, '凶險之象');
  });

  test('含無咎（且不含凶/吉）→ 無咎之象', () {
    final result = explainer.explain(yaoIndex: 2, yaoText: '小有言,終無咎');
    expect(result.judgementLabel, '無咎之象');
  });

  test('含厲或危（且未命中前面條件）→ 危厲之象', () {
    final resultLi = explainer.explain(yaoIndex: 3, yaoText: '貞厲');
    expect(resultLi.judgementLabel, '危厲之象');

    final resultWei = explainer.explain(yaoIndex: 3, yaoText: '見危');
    expect(resultWei.judgementLabel, '危厲之象');
  });

  test('含利（且未命中前面條件）→ 有利之象', () {
    final result = explainer.explain(yaoIndex: 4, yaoText: '利有攸往');
    expect(result.judgementLabel, '有利之象');
  });

  test('都不符合關鍵字 → 平穩之象', () {
    final result = explainer.explain(yaoIndex: 5, yaoText: '見羣龍無首');
    expect(result.judgementLabel, '平穩之象');
  });
}
