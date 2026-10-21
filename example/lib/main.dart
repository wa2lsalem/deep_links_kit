import 'package:flutter/material.dart';

import 'app_deep_links.dart';
import 'app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppDeepLinks.instance.init(); // before runApp, so the launch link is kept
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'deep_links_kit',
      routerConfig: AppRouter.router,
    );
  }
}
