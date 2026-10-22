import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'details_page.dart';
import 'home_page.dart';
import 'deep_links.dart';
import 'app_router.gr.dart';

@RoutePage()
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // Load the session, settings, etc.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    context.router.replace(const HomeRoute());
    deepLinks.ready(); // links that arrived meanwhile open now
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => HomePage(deepLinks: deepLinks);
}

@RoutePage()
class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key, @PathParam('id') required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => DetailsPage('Product $id');
}

@RoutePage()
class UserScreen extends StatelessWidget {
  const UserScreen({super.key, @PathParam('id') required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => DetailsPage('User $id');
}
