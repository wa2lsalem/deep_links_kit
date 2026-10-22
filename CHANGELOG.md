## 0.1.1

- **Breaking:** links now wait until you call `deepLinks.ready()`, usually at
  the end of your splash. This replaces the `Completer` you passed to
  `waitUntilReady`. Without a splash, call it in `main` after the first
  frame.
  `waitUntilReady` still works and replaces `ready()` when given.
- Route captures that decode to `/`, `?`, `#`, `\`, `.` or `..` no longer
  match, so a crafted link cannot open a different in-app path.
- `readyTimeout` now also covers `waitUntilReady`, and defaults to 30
  seconds. A link that never gets ready no longer holds up later links.
- The CLI reports malformed YAML, JSON or plist files and file errors as
  failures instead of crashing, and rejects a non-boolean
  `disable_flutter_deep_linking`.
- Removed `executables` from the pubspec. Run the CLI with
  `dart run deep_links_kit` from your app, which is unchanged.
- The example is a go_router shop app in Clean Architecture (splash, home,
  product list and details) plus a small auto_route app, explained step by
  step in `example/example.md`.

## 0.1.0

- `DeepLinksKit` runtime: route patterns, readiness waiting, ordered handling,
  duplicate cold-start link suppression, host and scheme filters.
- `DeepLinkNavigator.custom` for any router and `DeepLinkNavigator.named` for
  Navigator 1.0.
- CLI `setup`: Android intent filters, iOS associated domains, URL schemes and
  turning off Flutter's built-in deep linking.
- CLI `generate`: `assetlinks.json` and `apple-app-site-association`.
- CLI `doctor`: checks the native setup and the files served by each host.
- `setup` and `doctor` warn when the launcher activity's `launchMode` lets a
  link start a second copy of the app.
- `setup` records its iOS changes in `deep_links_kit.lock`, so hosts and
  schemes removed from the config are removed from the iOS project too.
