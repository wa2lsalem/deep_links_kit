import 'package:app_links/app_links.dart';

/// Where incoming links come from. Replace it in tests or to feed links from
/// another plugin.
abstract interface class DeepLinkSource {
  /// The link that launched the app, if any (cold start).
  Future<Uri?> getInitialLink();

  /// Links received while the app is running. May also repeat the initial
  /// link; [DeepLinksKit] ignores such duplicates.
  Stream<Uri> get links;
}

/// The default source, backed by the `app_links` plugin.
class AppLinksSource implements DeepLinkSource {
  /// Creates a source. Pass [appLinks] to share an existing instance.
  AppLinksSource([AppLinks? appLinks]) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();

  @override
  Stream<Uri> get links => _appLinks.uriLinkStream;
}
