import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection_container.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Shop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      routerConfig: sl<GoRouter>(),
    );
  }
}
