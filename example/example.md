# deep_links_kit example

When someone taps `https://app.example.com/products/42` (or `myapp://products/42`),
your app opens on the product page. Four steps, about 30 lines of code.

## 1. `pubspec.yaml`: tell the package your links

```yaml
deep_links_kit:
  hosts: [app.example.com]
  scheme: myapp
```

## 2. Terminal: set up Android and iOS

```sh
dart run deep_links_kit setup
```

That's all the native setup. You don't edit `AndroidManifest.xml` or
`Info.plist` by hand.

## 3. `lib/with_go_router/app_deep_links.dart`: map links to pages

One class for all deep link code. Each `DeepLinkRoute` says "a link like
this opens that page". `:id` copies part of the link, so `/products/42`
opens `/products/42` in the app.

```dart
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
```

## 4. Start it and tell it when the app is ready

### `lib/main.dart`

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppDeepLinks.instance.init(); // before runApp, so the launch link is kept
  runApp(const GoRouterExample());
}
```

### `lib/with_go_router/splash_page.dart`

When the splash finishes, it opens the home page and then lets waiting
links through. The link opens on top of home, so Back returns to home.

```dart
    context.go('/home');
    AppDeepLinks.firstScreenOpened();
```

Done. Run the app and tap the sample links on the home page.

---

## Not using go_router?

Keep the same `AppDeepLinks` class. Only `navigator:` and the line in the
splash change.

### Navigator (named routes)

Run it: `flutter run -t lib/main_navigator.dart`

### `lib/with_navigator/app_deep_links.dart`

```dart
    navigator: DeepLinkNavigator.named(AppRouter.navigatorKey),
```

### `lib/main_navigator.dart`

Give the same key to `MaterialApp`:

```dart
    return MaterialApp(
      navigatorKey: AppRouter.navigatorKey,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
```

### `lib/with_navigator/splash_page.dart`

```dart
    Navigator.of(context).pushReplacementNamed('/home');
    AppDeepLinks.firstScreenOpened();
```

### auto_route

Run it: `flutter run -t lib/main_auto_route.dart`

### `lib/with_auto_route/app_deep_links.dart`

```dart
    navigator: DeepLinkNavigator.custom(
      push: AppRouter.instance.pushPath,
      replace: AppRouter.instance.navigatePath,
    ),
```

### `lib/with_auto_route/app_router.dart`

The paths in your router are what `to:` returns:

```dart
    AutoRoute(page: HomeRoute.page, path: '/home'),
    AutoRoute(page: ProductRoute.page, path: '/products/:id'),
    AutoRoute(page: UserRoute.page, path: '/users/:id'),
```

### `lib/with_auto_route/screens.dart`

```dart
    context.router.replace(const HomeRoute());
    AppDeepLinks.firstScreenOpened();
```

## Try a real link

```sh
adb shell am start -a android.intent.action.VIEW -d "myapp://products/42"
xcrun simctl openurl booted "myapp://products/42"
```
