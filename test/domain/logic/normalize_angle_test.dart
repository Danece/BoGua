import 'package:flutter_test/flutter_test.dart';
import 'package:guiding_the_unknown_path/domain/logic/gua_calculator.dart';

void main() {
  test('正角度：小於 360 時原樣返回', () {
    expect(normalizeAngleDegrees(0), 0);
    expect(normalizeAngleDegrees(90), 90);
    expect(normalizeAngleDegrees(359.9), closeTo(359.9, 1e-9));
  });

  test('正角度：大於等於 360 時取餘數', () {
    expect(normalizeAngleDegrees(360), 0);
    expect(normalizeAngleDegrees(450), 90);
    expect(normalizeAngleDegrees(3600), 0);
    expect(normalizeAngleDegrees(3650), 50);
  });

  test('負角度：正規化為 0~360 正值', () {
    expect(normalizeAngleDegrees(-90), 270);
    expect(normalizeAngleDegrees(-360), 0);
    expect(normalizeAngleDegrees(-450), 270);
    expect(normalizeAngleDegrees(-3600), 0);
    expect(normalizeAngleDegrees(-3650), 310);
  });

  test('結果永遠落在 [0, 360) 區間（涵蓋隨機轉盤可能出現的極端值）', () {
    const values = [-7321.5, -0.001, 0.0, 0.001, 359.999, 360.0, 7321.5];
    for (final value in values) {
      final result = normalizeAngleDegrees(value);
      expect(result, greaterThanOrEqualTo(0));
      expect(result, lessThan(360));
    }
  });
}
