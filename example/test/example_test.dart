import 'dart:io';

import 'package:deep_links_kit_example/app_deep_links.dart';
import 'package:deep_links_kit_example/app_router.dart';
import 'package:deep_links_kit_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a launch link waits for the splash, then opens over home', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    AppDeepLinks.instance.handle(Uri.parse('myapp://p/42'));

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Product 42'), findsWidgets);

    AppRouter.router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  test('example.md shows the code as it is in the files', () {
    String read(String path) =>
        File(path).readAsStringSync().replaceAll('\r\n', '\n');
    final steps = RegExp(
      r'^## \d+\. `([^`]+)`.*?```(?:dart|yaml)\n(.*?)```',
      multiLine: true,
      dotAll: true,
    ).allMatches(read('example.md')).toList();
    expect(steps, hasLength(5));
    for (final step in steps) {
      expect(read(step[1]!), contains(step[2]!), reason: step[1]);
    }
  });
}
