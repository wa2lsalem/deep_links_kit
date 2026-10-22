# deep_links_kit

One config for Android App Links, iOS Universal Links and custom URL schemes:

- **A CLI** that edits `AndroidManifest.xml`, the iOS entitlements and
  `Info.plist`, writes `assetlinks.json` / `apple-app-site-association` for
  your website, and checks that everything is served correctly.
- **A small runtime** that receives links, waits until your app is ready
  (session loaded, navigator built), and opens the matching route with
  **any router**: go_router, Navigator 1.0, auto_route, and others.

## Why

Setting up deep links by hand means editing four native files and two server
files that must agree with each other, and then writing the same
`DeepLinkService` in every app. Common bugs this package prevents:

- The link opens **twice**, because Flutter's built-in deep linking and
  `app_links` both handle it. `setup` turns the built-in one off.
- The cold-start link is handled twice, because `app_links` returns it from
  `getInitialLink()` **and** emits it on `uriLinkStream`. The runtime drops
  the duplicate.
- Navigation runs before the user session is loaded, or before the navigator
  exists. The runtime waits for both.
- The website files miss a path or a fingerprint. `doctor` finds it.

## 1. Install

```sh
flutter pub add deep_links_kit
```

Add it as a regular dependency of your app, not with
`dart pub global activate`: your code imports the runtime classes, and
`dart run deep_links_kit` runs the CLI from that same dependency.

## 2. Configure

Add a section to your app's `pubspec.yaml` (or put the same keys in a
`deep_links_kit.yaml` file):

```yaml
deep_links_kit:
  hosts: [app.example.com]       # https://app.example.com/... (App Links / Universal Links)
  scheme: myapp                  # myapp://... (optional)
```

That is enough for most apps. Everything else is optional:

```yaml
deep_links_kit:
  hosts: [app.example.com]
  scheme: myapp
  paths: ["/share/*", "/p/*"]    # only these links open the app, default "/*"
  android:
    sha256:                      # only for `generate` and `doctor`
      - "2E:3B:...:4A:C8"
  ios:
    team_id: ABCDE12345          # read from the Xcode project if omitted
```

| Key | Description |
| --- | --- |
| `hosts` / `host` | Web domains. `*.example.com` covers subdomains. |
| `schemes` / `scheme` | Custom URL schemes. |
| `paths` | Path globs on the hosts (`*` any characters, `?` one). Set it when some pages of the site should stay in the browser. Used by `setup` (Android) and `generate` (iOS), so if your backend writes the website files, give it the same paths. |
| `disable_flutter_deep_linking` | Default `true`. Keep it unless you let your router handle links itself. |
| `android.package` | Overrides `applicationId` from Gradle (flavors). |
| `android.sha256` | Certificate fingerprints, written to `assetlinks.json` and checked by `doctor`. |
| `ios.team_id` / `ios.bundle_id` | Override the values read from `project.pbxproj`. |

`android.sha256` and `ios.team_id` only feed the two website files
(`assetlinks.json` and `apple-app-site-association`). `setup` never reads
them. If your backend team writes and hosts those files, leave these keys out
and send them the package name, SHA-256, Team ID and bundle ID instead.
Without `android.sha256`, `generate` writes a placeholder to replace, and
`doctor` lists the fingerprints it finds on the server for you to check.

## 3. Run the CLI

```sh
dart run deep_links_kit setup      # --dry-run to preview
dart run deep_links_kit generate   # --output <dir>, default build/deep_links_kit
dart run deep_links_kit doctor     # --offline to skip the website checks
```

`setup` is safe to run again, and the config is the source of truth: values
you remove from it are removed from the native projects too. On Android it
writes one marked block inside the launcher activity and replaces that block
on later runs. On iOS it records what it added in `deep_links_kit.lock`
(commit this file), so a later run removes only its own old entries and never
another plugin's, such as a Facebook `fb123` URL scheme. When the Runner
target has no entitlements file, `setup` creates `Runner/Runner.entitlements`
and links it in every build configuration.

`doctor` exits with code `1` when something will break deep links, so you can
run it in CI.

> **Android launchMode:** with `singleTop` (or `standard`, the default), a
> link tapped in another app starts a second copy of your app: the splash
> runs again and in-memory state starts empty. Use
> `android:launchMode="singleTask"` on the launcher activity. `setup` and
> `doctor` warn about this but never change it, because it affects the whole
> app. The one trade-off: native screens opened on top of the activity (an
> image cropper, for example) close when a link arrives.
>
> **Google Play:** Play re-signs your app. Put the **App signing key**
> SHA-256 from *Play Console > Test and release > App integrity* in
> `assetlinks.json`, not only your upload key.
>
> **Apple:** enable *Associated Domains* for the App ID in the Apple Developer
> portal. Apple caches `apple-app-site-association` on its CDN, so changes
> can take up to 24 hours (reinstall the app to retest). See the FAQ for how
> to check what Apple has.
>
> **iOS AppDelegate:** if your `AppDelegate` overrides
> `application(_:continue:restorationHandler:)` or
> `application(_:open:options:)`, return `super`'s result from it.
> Otherwise links never reach Flutter.

## 4. Handle links

Three steps: describe your links, start listening, and say when the app is
ready.

```dart
// 1. lib/deep_links.dart
final deepLinks = DeepLinksKit(
  navigator: DeepLinkNavigator.custom(push: router.push, replace: router.go),
  routes: [
    DeepLinkRoute('/products/:id', to: (m) => '/products/${m['id']}'),
    DeepLinkRoute('/u/:id', to: (m) => '/users/${m['id']}'),
  ],
  fallback: (_) => '/home', // optional: links no route matches
);

// 2. lib/main.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  deepLinks.init(); // before runApp, so the link that opened the app is kept
  runApp(const App());
}

// 3. In your splash, after the session is loaded:
context.go('/home');
deepLinks.ready();
```

Links wait until you call `ready()`, including the one that launched the
app, and then open on top of the first screen, so Back returns to it. A
link that waits longer than `readyTimeout` (30 seconds) is dropped and
reported to `onError`.

No splash? Call `ready()` in `main` after the first frame. Before `runApp`
is too early: the link would open before the router has built your first
page, and Back would have nothing to return to.

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  deepLinks.init();
  runApp(const App());
  WidgetsBinding.instance.addPostFrameCallback((_) => deepLinks.ready());
}
```

Each route says where a link goes: `https://app.example.com/u/7` opens
`/users/7`. `m['id']` is the `:id` part of the link. Return `null` from
`to:` to let the next route or the fallback decide.

The [example](example/example.md) is a go_router shop app in Clean
Architecture (splash, home, product list and details), plus a small
auto_route app.

### Routers

```dart
// go_router
DeepLinkNavigator.custom(push: router.push, replace: router.go);

// auto_route
DeepLinkNavigator.custom(push: router.pushPath, replace: router.navigatePath);

// Navigator 1.0 named routes
DeepLinkNavigator.named(navigatorKey);

// Anything else
DeepLinkNavigator.custom(
  push: (path) => myRouter.open(path),
  isReady: () => myRouter.isMounted,
);
```

### Route patterns

Patterns match the link path. For custom schemes the host is part of the
path, so `myapp://p/42` and `https://app.example.com/p/42` both match `/p/:id`.

| Pattern | Matches | Captures |
| --- | --- | --- |
| `/p/:id` | `/p/42` | `m['id'] == '42'` |
| `/p/:id/:name?` | `/p/42`, `/p/42/ali` | optional trailing value |
| `/docs/*` | `/docs`, `/docs/a/b` | `m.rest == ['a', 'b']` |

Literal segments ignore letter case unless `caseSensitive: true`. Query
parameters are available as `m.query`. Set `replace: true` on a route to
replace the stack instead of pushing.

Captured values are decoded, and safe to put in a path: a link whose value
decodes to `/`, `?`, `#`, `\`, `.` or `..` (such as `/p/..%2Fadmin`) does
not match.

### More

- `handle(uri)`: route a link from somewhere else, such as a push
  notification.
- `waitUntilReady`: wait for your own future before each link, instead of
  calling `ready()`.
- `resolve(uri)`: get the `DeepLinkTarget` without navigating.
- `hosts` / `schemes`: ignore links for other domains or schemes.
- `onLink` / `onError`: logging and analytics hooks.
- `source`: pass your own `DeepLinkSource` in tests.

## FAQ

**Can I change the domain without releasing a new build?** No. Android and
iOS read the domains when the app is installed, so a new domain needs a new
build. Use a dedicated domain for links (for example `links.example.com`)
that never moves, even if your API does, or a wildcard host for subdomains.

**How do I test?**

```sh
adb shell pm verify-app-links --re-verify com.example.app
adb shell pm get-app-links com.example.app
adb shell am start -a android.intent.action.VIEW -d "https://app.example.com/p/1"
xcrun simctl openurl booted "https://app.example.com/p/1"
```

On a real iPhone, tap the link from Notes or Messages. Typing it in Safari's
address bar does not open the app.

**I changed `apple-app-site-association`. Does Apple have the new one?**
iPhones read the file from Apple's CDN, not from your server. Open
`https://app-site-association.cdn-apple.com/a/v1/app.example.com` to see the
copy they get. To test without waiting for the CDN, add
`applinks:app.example.com?mode=developer` next to the existing entry in
`Runner.entitlements`, turn on *Settings > Developer > Associated Domains
Development* on the iPhone, and reinstall. The phone then reads the file
from your server directly. Remove the line before you release; `setup` keeps
entries it did not add, so it will not remove it for you.
