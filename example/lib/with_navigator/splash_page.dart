import 'package:flutter/material.dart';

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
    Navigator.of(context).pushReplacementNamed('/home');
    AppDeepLinks.firstScreenOpened();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
