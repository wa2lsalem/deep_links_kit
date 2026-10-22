import 'dart:io';

import 'package:deep_links_kit_example/app.dart';
import 'package:deep_links_kit_example/core/deep_links/app_deep_links.dart'
    as go_router;
import 'package:deep_links_kit_example/core/di/injection_container.dart';
import 'package:deep_links_kit_example/features/home/presentation/pages/home_page.dart';
import 'package:deep_links_kit_example/features/product_details/presentation/pages/product_details_page.dart';
import 'package:deep_links_kit_example/features/product_list/presentation/pages/product_list_page.dart';
import 'package:deep_links_kit_example/main_auto_route.dart';
import 'package:deep_links_kit_example/with_auto_route/deep_links.dart'
    as auto_route;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('go_router: a launch link waits for the splash, then opens '
      'over home', (tester) async {
    initDependencies();
    final deepLinks = go_router.deepLinks;
    await tester.pumpWidget(const App());
    deepLinks.handle(Uri.parse('myapp://products/42'));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsPage), findsOneWidget);
    expect(find.text('Headphones'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

    // A short link opens the same page.
    deepLinks.handle(Uri.parse('https://app.example.com/p/1'));
    await tester.pumpAndSettle();
    expect(find.text('A 350 ml ceramic mug.'), findsOneWidget);

    deepLinks.handle(Uri.parse('myapp://products'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductListPage), findsOneWidget);

    // A product that does not exist shows an error, not a crash.
    deepLinks.handle(Uri.parse('myapp://products/999'));
    await tester.pumpAndSettle();
    expect(find.text('This product does not exist'), findsOneWidget);

    // An unknown link goes back to the home page.
    deepLinks.handle(Uri.parse('https://app.example.com/unknown'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('auto_route: a launch link waits for the splash, then opens '
      'over home', (tester) async {
    final deepLinks = auto_route.deepLinks;
    await tester.pumpWidget(const AutoRouteExample());
    await tester.pump(); // auto_route builds its first page a frame later
    deepLinks.handle(Uri.parse('myapp://products/42'));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Product 42'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    deepLinks.handle(Uri.parse('https://app.example.com/unknown'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  test('example.md shows the code as it is in the files', () {
    String read(String path) =>
        File(path).readAsStringSync().replaceAll('\r\n', '\n');
    final steps = RegExp(
      r'^#{2,3} (?:\d+\. )?`([^`]+)`.*?```(?:dart|yaml)\n(.*?)```',
      multiLine: true,
      dotAll: true,
    ).allMatches(read('example.md')).toList();
    expect(steps, hasLength(7));
    for (final step in steps) {
      expect(read(step[1]!), contains(step[2]!), reason: step[1]);
    }
  });
}
