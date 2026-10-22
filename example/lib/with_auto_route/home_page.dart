import 'package:deep_links_kit/deep_links_kit.dart';
import 'package:flutter/material.dart';

/// The home page of the auto_route example.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.deepLinks});

  final DeepLinksKit deepLinks;

  static const _samples = [
    'myapp://products/42',
    'https://app.example.com/u/7',
    'https://app.example.com/unknown',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Tap a link to open it as if it came from outside:'),
          ),
          for (final link in _samples)
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(link),
              onTap: () => deepLinks.handle(Uri.parse(link)),
            ),
        ],
      ),
    );
  }
}
