# deep_links_kit with go_router

A complete app lives in this folder. These are the only parts that deal with
deep links, file by file.

## 1. `pubspec.yaml`: the config

```yaml
deep_links_kit:
  hosts: [app.example.com]
  scheme: myapp
```

## 2. Terminal: native and website setup

```sh
dart run deep_links_kit setup      # edits android/ and ios/
dart run deep_links_kit generate   # files for https://app.example.com/.well-known/
dart run deep_links_kit doctor     # checks everything
```

## 3. `lib/app_deep_links.dart`: links to your routes

`AppDeepLinks.instance` maps each link to a go_router path. Links wait until
`firstScreenOpened()` is called, so they never open behind the splash.

```dart
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
```

## 4. `lib/main.dart`: start listening

Call `init()` before `runApp`, so the link that launched the app is kept.

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppDeepLinks.instance.init(); // before runApp, so the launch link is kept
  runApp(const ExampleApp());
}
```

## 5. `lib/pages/splash_page.dart`: let waiting links open

After the splash opens the first screen, it calls `firstScreenOpened()`. A
waiting link then opens on top of that screen, so Back returns to it.

```dart
  Future<void> _start() async {
    // Load the session, settings, etc.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    context.go('/');
    AppDeepLinks.firstScreenOpened();
  }
```

## 6. `lib/app_router.dart`: your router, unchanged

A plain `GoRouter`. Nothing in it is specific to deep links.

```dart
abstract final class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(path: '/', builder: (_, _) => const HomePage()),
      GoRoute(
        path: '/products/:id',
        builder: (_, state) =>
            DetailsPage('Product ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/users/:id',
        builder: (_, state) =>
            DetailsPage('User ${state.pathParameters['id']}'),
      ),
    ],
  );
}
```

## Try it

Run the app and tap the sample links on the home page, or send a real link:

```sh
adb shell am start -a android.intent.action.VIEW -d "myapp://p/42"
xcrun simctl openurl booted "myapp://p/42"
```
