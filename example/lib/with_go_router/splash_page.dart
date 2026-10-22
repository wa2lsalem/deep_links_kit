import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_deep_links.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // Load the session, settings, etc.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    context.go('/home');
    AppDeepLinks.firstScreenOpened();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
