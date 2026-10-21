import 'dart:async';

import 'package:deep_links_kit/deep_links_kit.dart';
import 'package:flutter/foundation.dart';

import 'app_router.dart';

abstract final class AppDeepLinks {
  static final _firstScreen = Completer<void>();

  /// Called by the splash once it opened the first screen. Links that
  /// arrived earlier, like the one that launched the app, open now.
  static void firstScreenOpened() {
    if (!_firstScreen.isCompleted) _firstScreen.complete();
  }

  static final instance = DeepLinksKit(
    navigator: DeepLinkNavigator.custom(
      push: AppRouter.router.push,
      replace: AppRouter.router.go,
    ),
    waitUntilReady: () => _firstScreen.future,
    hosts: {'app.example.com'},
    schemes: {'myapp'},
    routes: [
      // https://app.example.com/p/42 and myapp://p/42
      DeepLinkRoute('/p/:id', to: (m) => '/products/${m['id']}'),

      // https://app.example.com/share/user/7
      DeepLinkRoute(
        '/share/:type/:id',
        to: (m) => switch (m['type']) {
          'product' => '/products/${m['id']}',
          'user' => '/users/${m['id']}',
          _ => null, // unknown type: try the next route, then the fallback
        },
      ),
    ],
    fallback: (_) => '/', // any other link opens the home page
    onLink: (link, target) => debugPrint('$link -> $target'),
  );
}
