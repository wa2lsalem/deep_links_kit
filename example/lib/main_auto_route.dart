// The auto_route example: flutter run -t lib/main_auto_route.dart
// After changing routes or screens: dart run build_runner build

import 'package:flutter/material.dart';

import 'with_auto_route/app_router.dart';
import 'with_auto_route/deep_links.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  deepLinks.init(); // before runApp, so the link that opened the app is kept
  runApp(const AutoRouteExample());
}

class AutoRouteExample extends StatelessWidget {
  const AutoRouteExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router.config());
  }
}
