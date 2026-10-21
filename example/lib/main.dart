import 'package:deep_links_kit/deep_links_kit.dart';
import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final deepLinks = DeepLinksKit(
  navigator: DeepLinkNavigator.named(navigatorKey),
  hosts: {'app.example.com'},
  schemes: {'myapp'},
  routes: [
    DeepLinkRoute('/p/:id', to: (match) => '/profile?id=${match['id']}'),
  ],
  fallback: (_) => '/',
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  deepLinks.init();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        final page = uri.path == '/profile'
            ? ProfilePage(id: uri.queryParameters['id'] ?? '')
            : const HomePage();
        return MaterialPageRoute(builder: (_) => page, settings: settings);
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Open myapp://p/42 to see a profile')),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('Profile $id')),
    );
  }
}
