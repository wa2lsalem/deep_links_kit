// The auto_route example: flutter run -t lib/main_auto_route.dart
// After changing routes or screens: dart run build_runner build

import 'package:flutter/material.dart';

import 'with_auto_route/app_deep_links.dart';
import 'with_auto_route/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppDeepLinks.instance.init(); // before runApp, so the launch link is kept
  runApp(const AutoRouteExample());
}

class AutoRouteExample extends StatelessWidget {
  const AutoRouteExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: AppRouter.instance.config());
  }
}
