// The go_router example. For auto_route: flutter run -t lib/main_auto_route.dart

import 'package:deep_links_kit/deep_links_kit.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection_container.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initDependencies();
  sl<DeepLinksKit>().init(); // before runApp, so the launch link is kept
  runApp(const App());
}
