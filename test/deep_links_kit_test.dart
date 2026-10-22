import 'dart:async';

import 'package:deep_links_kit/deep_links_kit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSource implements DeepLinkSource {
  _FakeSource([this.initial]);

  final Uri? initial;
  final controller = StreamController<Uri>.broadcast();

  @override
  Future<Uri?> getInitialLink() async => initial;

  @override
  Stream<Uri> get links => controller.stream;
}

class _FakeNavigator extends DeepLinkNavigator {
  final calls = <String>[];
  bool ready = true;

  @override
  bool get isReady => ready;

  @override
  void push(String path) => calls.add('push $path');

  @override
  void replace(String path) => calls.add('replace $path');
}

final _routes = [
  DeepLinkRoute('/p/:id', to: (m) => '/profile/${m['id']}'),
  DeepLinkRoute('/home', to: (_) => '/home', replace: true),
];

void main() {
  late _FakeNavigator navigator;

  setUp(() => navigator = _FakeNavigator());

  DeepLinksKit kit({
    DeepLinkSource? source,
    DeepLinkFallback? fallback,
    Future<void> Function()? waitUntilReady,
    Set<String> hosts = const {},
    Set<String> schemes = const {},
    List<Object>? errors,
  }) =>
      DeepLinksKit(
        navigator: navigator,
        routes: _routes,
        source: source ?? _FakeSource(),
        fallback: fallback,
        waitUntilReady: waitUntilReady,
        hosts: hosts,
        schemes: schemes,
        readyTimeout: const Duration(milliseconds: 300),
        onError: (error, _) => errors?.add(error),
      )..ready();

  test('pushes or replaces according to the route', () async {
    final handler = kit();
    await handler.handle(Uri.parse('https://e.com/p/7'));
    await handler.handle(Uri.parse('https://e.com/home'));
    expect(navigator.calls, ['push /profile/7', 'replace /home']);
  });

  test('uses the fallback for unmatched links', () async {
    final handler = kit(fallback: (_) => '/start');
    await handler.handle(Uri.parse('https://e.com/unknown'));
    expect(navigator.calls, ['replace /start']);
  });

  test('ignores unmatched links without a fallback', () async {
    await kit().handle(Uri.parse('https://e.com/unknown'));
    expect(navigator.calls, isEmpty);
  });

  test('filters hosts, including wildcards, and schemes', () async {
    final handler = kit(hosts: {'*.e.com'}, schemes: {'myapp'});
    await handler.handle(Uri.parse('https://other.com/p/1'));
    await handler.handle(Uri.parse('other://p/2'));
    await handler.handle(Uri.parse('https://share.e.com/p/3'));
    await handler.handle(Uri.parse('myapp://p/4'));
    expect(navigator.calls, ['push /profile/3', 'push /profile/4']);
  });

  test('links wait until ready() is called', () async {
    final handler = DeepLinksKit(
      navigator: navigator,
      source: _FakeSource(),
      routes: _routes,
    );
    final pending = handler.handle(Uri.parse('https://e.com/p/1'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(navigator.calls, isEmpty);
    handler.ready();
    handler.ready(); // a second call is harmless
    await pending;
    await handler.handle(Uri.parse('https://e.com/p/2'));
    expect(navigator.calls, ['push /profile/1', 'push /profile/2']);
  });

  test('says ready() was not called when a link times out', () async {
    final errors = <Object>[];
    final handler = DeepLinksKit(
      navigator: navigator,
      source: _FakeSource(),
      routes: _routes,
      readyTimeout: const Duration(milliseconds: 100),
      onError: (error, _) => errors.add(error),
    );
    await handler.handle(Uri.parse('https://e.com/p/1'));
    expect(errors.single.toString(), contains('ready() was not called'));
    expect(navigator.calls, isEmpty);
  });

  test('waits for readiness before resolving', () async {
    var sessionLoaded = false;
    final handler = DeepLinksKit(
      navigator: navigator,
      source: _FakeSource(),
      waitUntilReady: () async => sessionLoaded = true,
      routes: [
        DeepLinkRoute('/p/:id', to: (_) => sessionLoaded ? '/in' : '/out'),
      ],
    );
    await handler.handle(Uri.parse('https://e.com/p/1'));
    expect(navigator.calls, ['push /in']);
  });

  test('waits for the navigator to become ready', () async {
    navigator.ready = false;
    final pending = kit().handle(Uri.parse('https://e.com/p/1'));
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(navigator.calls, isEmpty);
    navigator.ready = true;
    await pending;
    expect(navigator.calls, ['push /profile/1']);
  });

  test('reports a timeout when the navigator never gets ready', () async {
    navigator.ready = false;
    final errors = <Object>[];
    await kit(errors: errors).handle(Uri.parse('https://e.com/p/1'));
    expect(errors.single, isA<TimeoutException>());
    expect(navigator.calls, isEmpty);
  });

  test('drops a link when waitUntilReady never completes', () async {
    final errors = <Object>[];
    final handler = kit(
      errors: errors,
      waitUntilReady: () => Completer<void>().future,
    );
    await handler.handle(Uri.parse('https://e.com/p/1'));
    expect(errors.single, isA<TimeoutException>());
    expect(navigator.calls, isEmpty);
  });

  test('handles links in order and keeps going after an error', () async {
    final errors = <Object>[];
    final handler = DeepLinksKit(
      navigator: navigator,
      source: _FakeSource(),
      onError: (error, _) => errors.add(error),
      routes: [
        DeepLinkRoute('/bad', to: (_) => throw StateError('boom')),
        DeepLinkRoute('/p/:id', to: (m) => '/profile/${m['id']}'),
      ],
    )..ready();
    unawaited(handler.handle(Uri.parse('https://e.com/p/1')));
    unawaited(handler.handle(Uri.parse('https://e.com/bad')));
    await handler.handle(Uri.parse('https://e.com/p/2'));
    expect(navigator.calls, ['push /profile/1', 'push /profile/2']);
    expect(errors.single, isA<StateError>());
  });

  test('handles the cold-start link once even if the stream repeats it',
      () async {
    final link = Uri.parse('https://e.com/p/9');
    final source = _FakeSource(link);
    final handler = kit(source: source);
    await handler.init();
    source.controller.add(link);
    await Future<void>.delayed(Duration.zero);
    await handler.handle(Uri.parse('https://e.com/p/10'));
    expect(navigator.calls, ['push /profile/9', 'push /profile/10']);
    await handler.dispose();
  });

  test('resolve returns the target without navigating', () {
    final handler = kit(fallback: (_) => '/start');
    expect(
      handler.resolve(Uri.parse('myapp://p/5')),
      const DeepLinkTarget('/profile/5'),
    );
    expect(
      handler.resolve(Uri.parse('https://e.com/x')),
      const DeepLinkTarget('/start', replace: true),
    );
    expect(navigator.calls, isEmpty);
  });
}
