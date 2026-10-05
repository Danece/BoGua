import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 這個測試只有一個目的：直接量測 [HexagramWheel] 用的
/// `Transform.rotate` 在螢幕上實際的旋轉方向，而不是憑感覺假設。
///
/// [GuaCalculator.angleToSegmentIndex]（domain/logic/gua_calculator.dart）
/// 的公式必須先對角度取負號再正規化，前提是「angle 為正時，
/// `Transform.rotate` 在螢幕上是順時針轉」。這個前提來自 Flutter 的
/// 螢幕座標系 y 軸朝下（跟數學課本慣用、y 軸朝上時「正角度=逆時針」的
/// 直覺相反），但這裡不假設，而是實際渲染一個從圓心指向 12 點鐘方向的
/// 標記、轉一個已知的正角度，量測標記真正落在螢幕上的哪個位置來確認。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Transform.rotate(angle: 正值) 在螢幕座標系下是順時針', (
    tester,
  ) async {
    const boxSize = 200.0;
    const rotateDegrees = 10.0; // 小角度，避免轉超過一個象限造成誤判。

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            key: const Key('box'),
            width: boxSize,
            height: boxSize,
            child: Transform.rotate(
              angle: rotateDegrees * math.pi / 180,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  key: const Key('marker'),
                  width: 6,
                  height: 6,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final boxCenter = tester.getCenter(find.byKey(const Key('box')));
    final markerCenter = tester.getCenter(find.byKey(const Key('marker')));

    // 旋轉前，標記在正上方（12 點鐘），跟 box 中心同一條垂直線上
    // （markerCenter.dx == boxCenter.dx）。若轉了 +10° 後是「順時針」，
    // 標記應該往 12 點與 3 點鐘之間移動，也就是往右偏（dx 變大）；
    // 若是「逆時針」，則會往 9 點鐘那一側偏（dx 變小）。
    expect(
      markerCenter.dx,
      greaterThan(boxCenter.dx),
      reason:
          '標記往右偏，代表 Transform.rotate(angle: 正值) 在螢幕座標系'
          '（y 軸朝下）下確實是「順時針」——這正是 angleToSegmentIndex() '
          '要先取負號再正規化角度的原因。',
    );
    // 同時確認轉出去的量不是零（排除「根本沒轉」這種誤判 clockwise 的情況）。
    expect(markerCenter.dy, isNot(equals(boxCenter.dy - boxSize / 2)));
  });
}
