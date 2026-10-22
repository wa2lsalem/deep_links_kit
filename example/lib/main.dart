// The go_router example. For auto_route: flutter run -t lib/main_auto_route.dart

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/deep_links/app_deep_links.dart';
import 'core/di/injection_container.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initDependencies();
  deepLinks.init(); // before runApp, so the launch link is kept
  runApp(const App());
}
