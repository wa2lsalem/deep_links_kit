import 'package:flutter/material.dart';

/// The page a link opens, e.g. "Product 42".
class DetailsPage extends StatelessWidget {
  const DetailsPage(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
