import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// /divination、/history、/info 共用的底部導覽殼層。
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome),
            label: '占卜',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: '歷史',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            label: '資訊',
          ),
        ],
      ),
    );
  }
}
