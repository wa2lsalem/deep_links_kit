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
