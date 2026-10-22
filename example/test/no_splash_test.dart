import 'package:deep_links_kit/deep_links_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Source implements DeepLinkSource {
  @override
  Future<Uri?> getInitialLink() async => Uri.parse('myapp://products/42');

  @override
  Stream<Uri> get links => const Stream.empty();
}

void main() {
  // Without a splash, main calls ready() after the first frame, as in
  // example.md. Calling it before runApp would push the link before the
  // router has built its first page, and Back would have nowhere to go.
  testWidgets('without a splash, a launch link opens over the first page', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('Home')),
        GoRoute(
          path: '/products/:id',
          builder: (_, s) => Scaffold(
            appBar: AppBar(),
            body: Text('Product ${s.pathParameters['id']}'),
          ),
        ),
      ],
    );
    final deepLinks = DeepLinksKit(
      navigator: DeepLinkNavigator.custom(
        push: router.push,
        replace: router.go,
      ),
      source: _Source(),
      routes: [
        DeepLinkRoute('/products/:id', to: (m) => '/products/${m['id']}'),
      ],
    );
    await deepLinks.init();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    WidgetsBinding.instance.addPostFrameCallback((_) => deepLinks.ready());
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Product 42'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}
