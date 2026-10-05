import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiding_the_unknown_path/main.dart' as app;
import 'package:integration_test/integration_test.dart';

/// 效能量測：實際跑一次「進場星空 → 點擊轉盤占卜」的完整流程，用
/// [IntegrationTestWidgetsFlutterBinding.traceAction] 擷取跟 DevTools
/// Performance 分頁同一份 timeline 資料，量出真正的 frame build／raster
/// 時間，而不是憑肉眼看有沒有掉幀。
///
/// 執行方式（需要在 profile 模式下才有代表性，debug 模式的數字沒有意義）：
///   flutter drive \
///     --driver=test_driver/perf_driver.dart \
///     --target=integration_test/performance_test.dart \
///     -d windows --profile
///
/// 執行完會在 build/ 底下產生：
///   - splash_star_field_timeline.timeline_summary.json（星空 + 八卦旋轉）
///   - wheel_spin_timeline.timeline_summary.json（六層轉盤占卜動畫）
/// 兩份摘要各自包含 average/90th percentile/worst frame build 時間，以及
/// 掉出 16ms 預算的 frame 數量。
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('進場星空與轉盤占卜動畫的 frame time', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // --- 階段一：進場畫面，星空閃爍 + 八卦緩慢旋轉 ---
    // 量測一段自然運作的時間（不特意觸發互動），對應星空 CustomPainter
    // 與 _RotatingBagua 的 AnimatedBuilder 是否能穩定維持 60fps。
    await binding.traceAction(() async {
      await tester.pump();
      await Future<void>.delayed(const Duration(seconds: 3));
      await tester.pump();
    }, reportKey: 'splash_star_field_timeline');

    // 點擊畫面提前跳過進場動畫（SplashPage 允許顯示 3 秒內點擊跳過），
    // 進入占卜頁。
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();

    expect(find.text('問'), findsOneWidget);

    // --- 階段二：點擊轉盤中央「問」按鈕，觸發六層轉盤同時旋轉 9 秒 ---
    await binding.traceAction(() async {
      await tester.tap(find.text('問'));
      await tester.pump();
      // HexagramWheelState._spinDuration 固定 9 秒，多留一點餘裕確保
      // 轉盤真的轉完、結果畫面也渲染出來。
      await Future<void>.delayed(const Duration(seconds: 10));
      await tester.pumpAndSettle();
    }, reportKey: 'wheel_spin_timeline');

    // 轉盤轉完應該進入「result」狀態（中央按鈕變成「重置」），確認流程
    // 真的有跑完整個占卜，量到的才是有意義的資料。
    expect(find.text('重置'), findsOneWidget);
  });
}
