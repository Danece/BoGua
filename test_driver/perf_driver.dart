import 'package:integration_test/integration_test_driver.dart';

/// 搭配 integration_test/performance_test.dart 使用：
///   flutter drive \
///     --driver=test_driver/perf_driver.dart \
///     --target=integration_test/performance_test.dart \
///     -d windows --profile
///
/// 負責把 IntegrationTestWidgetsFlutterBinding.traceAction() 擷取到的
/// timeline 資料寫成 build/ 底下的 *.timeline_summary.json 檔案。
Future<void> main() => integrationDriver();
