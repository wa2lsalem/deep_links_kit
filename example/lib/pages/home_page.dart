import 'package:flutter/material.dart';

import '../app_deep_links.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _samples = [
    'myapp://p/42',
    'https://app.example.com/share/user/7',
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
              onTap: () => AppDeepLinks.instance.handle(Uri.parse(link)),
            ),
        ],
      ),
    );
  }
}
