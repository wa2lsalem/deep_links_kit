// The Navigator (named routes) example: flutter run -t lib/main_navigator.dart

import 'package:flutter/material.dart';

import 'with_navigator/app_deep_links.dart';
import 'with_navigator/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppDeepLinks.instance.init(); // before runApp, so the launch link is kept
  runApp(const NavigatorExample());
}

class NavigatorExample extends StatelessWidget {
  const NavigatorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppRouter.navigatorKey,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
