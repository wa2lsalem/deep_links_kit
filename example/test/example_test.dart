import 'dart:io';

import 'package:deep_links_kit/deep_links_kit.dart';
import 'package:deep_links_kit_example/main.dart';
import 'package:deep_links_kit_example/main_auto_route.dart';
import 'package:deep_links_kit_example/main_navigator.dart';
import 'package:deep_links_kit_example/with_auto_route/app_deep_links.dart'
    as auto_route;
import 'package:deep_links_kit_example/with_go_router/app_deep_links.dart'
    as go_router;
import 'package:deep_links_kit_example/with_navigator/app_deep_links.dart'
    as navigator;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Built inside each test: creating a router before testWidgets would
  // initialize the wrong binding.
  final examples = <String, (Widget, DeepLinksKit) Function()>{
    'go_router': () =>
        (const GoRouterExample(), go_router.AppDeepLinks.instance),
    'Navigator': () =>
        (const NavigatorExample(), navigator.AppDeepLinks.instance),
    'auto_route': () =>
        (const AutoRouteExample(), auto_route.AppDeepLinks.instance),
  };

  for (final MapEntry(key: name, value: example) in examples.entries) {
    testWidgets('$name: a launch link waits for the splash, then opens over '
        'home', (tester) async {
      final (app, deepLinks) = example();
      await tester.pumpWidget(app);
      await tester.pump(); // auto_route builds its first page a frame later
      deepLinks.handle(Uri.parse('myapp://products/42'));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Product 42'), findsWidgets);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      deepLinks.handle(Uri.parse('https://app.example.com/u/7'));
      await tester.pumpAndSettle();
      expect(find.text('User 7'), findsWidgets);

      // An unknown link goes back to the home page.
      deepLinks.handle(Uri.parse('https://app.example.com/unknown'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    });
  }

  test('example.md shows the code as it is in the files', () {
    String read(String path) =>
        File(path).readAsStringSync().replaceAll('\r\n', '\n');
    final steps = RegExp(
      r'^#{2,3} (?:\d+\. )?`([^`]+)`.*?```(?:dart|yaml)\n(.*?)```',
      multiLine: true,
      dotAll: true,
    ).allMatches(read('example.md')).toList();
    expect(steps, hasLength(10));
    for (final step in steps) {
      expect(read(step[1]!), contains(step[2]!), reason: step[1]);
    }
  });
}
