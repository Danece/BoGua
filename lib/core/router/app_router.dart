import 'package:go_router/go_router.dart';

import '../../presentation/divination/divination_page.dart';
import '../../presentation/history/history_detail_page.dart';
import '../../presentation/history/history_page.dart';
import '../../presentation/info/info_page.dart';
import '../../presentation/shared_widgets/app_shell.dart';
import '../../presentation/splash/splash_page.dart';

/// App 的導覽殼層設定。
///
/// `/` 為進場動畫頁，`/divination`、`/history`、`/info` 三頁共用一個
/// 底部導覽列（透過 [AppShell] 以 [StatefulShellRoute.indexedStack] 維持
/// 各分頁各自的狀態）。
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/divination',
                builder: (context, state) => const DivinationPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => HistoryDetailPage(
                      id: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/info',
                builder: (context, state) => const InfoPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
