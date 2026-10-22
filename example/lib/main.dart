// The go_router example. The other routers have their own entry points:
//   flutter run -t lib/main_navigator.dart
//   flutter run -t lib/main_auto_route.dart

import 'package:flutter/material.dart';

import 'with_go_router/app_deep_links.dart';
import 'with_go_router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppDeepLinks.instance.init(); // before runApp, so the launch link is kept
  runApp(const GoRouterExample());
}

class GoRouterExample extends StatelessWidget {
  const GoRouterExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: AppRouter.router);
  }
}
