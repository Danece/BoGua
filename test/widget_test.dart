import 'package:flutter_test/flutter_test.dart';

import 'package:guiding_the_unknown_path/main.dart';

void main() {
  testWidgets('App 啟動時顯示進場畫面', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('易經占卜'), findsOneWidget);

    // 讓 Splash 頁的 2 秒導向計時器跑完，避免測試結束時仍有 pending Timer。
    await tester.pump(const Duration(seconds: 3));
  });
}
