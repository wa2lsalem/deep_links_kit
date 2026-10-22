import 'dart:async';

import 'package:deep_links_kit/deep_links_kit.dart';

import 'app_router.dart';

abstract final class AppDeepLinks {
  static final _firstScreen = Completer<void>();

  /// Called by the splash once it opened the first screen. Links that
  /// arrived earlier, like the one that launched the app, open now.
  static void firstScreenOpened() {
    if (!_firstScreen.isCompleted) _firstScreen.complete();
  }

  static final DeepLinksKit instance = DeepLinksKit(
    // The only part that changes from one router to another.
    navigator: DeepLinkNavigator.custom(
      push: AppRouter.router.push,
      replace: AppRouter.router.go,
    ),
    waitUntilReady: () => _firstScreen.future, // links wait for the splash
    routes: [
      // https://app.example.com/products/42 or myapp://products/42
      DeepLinkRoute('/products/:id', to: (m) => '/products/${m['id']}'),

      // https://app.example.com/u/7 opens the user page
      DeepLinkRoute('/u/:id', to: (m) => '/users/${m['id']}'),
    ],
    fallback: (_) => '/home', // any other link opens the home page
  );
}
