import 'dart:async';

import 'package:flutter/foundation.dart';

import 'deep_link.dart';
import 'deep_link_navigator.dart';
import 'deep_link_route.dart';
import 'deep_link_source.dart';
import 'deep_link_target.dart';

/// Builds the path for links no route matched, or returns `null` to ignore.
typedef DeepLinkFallback = String? Function(DeepLink link);

/// Called for every received link with the target it resolved to, or `null`
/// when it was ignored.
typedef DeepLinkListener = void Function(DeepLink link, DeepLinkTarget? to);

/// Receives errors thrown while handling links.
typedef DeepLinkErrorHandler = void Function(Object error, StackTrace stack);

/// Receives App Links, Universal Links and custom-scheme links, waits until
/// the app is ready, and opens the matching in-app path.
///
/// Links are handled one at a time, in the order they arrive. The same link
/// arriving twice within [duplicateWindow] (as `app_links` does on a cold
/// start) is handled once.
class DeepLinksKit {
  /// Creates the handler. Call [init] once, as early as possible.
  DeepLinksKit({
    required this.navigator,
    required List<DeepLinkRoute> routes,
    this.fallback,
    this.replaceOnFallback = true,
    this.waitUntilReady,
    Set<String> hosts = const {},
    Set<String> schemes = const {},
    this.onLink,
    this.onError,
    DeepLinkSource? source,
    this.readyTimeout = const Duration(seconds: 30),
    this.duplicateWindow = const Duration(seconds: 2),
  })  : routes = List.unmodifiable(routes),
        hosts = Set.unmodifiable(hosts.map((h) => h.toLowerCase())),
        schemes = Set.unmodifiable(schemes.map((s) => s.toLowerCase())),
        _source = source;

  /// Opens resolved paths.
  final DeepLinkNavigator navigator;

  /// Tried in order; the first route that matches and returns a path wins.
  final List<DeepLinkRoute> routes;

  /// Used when no route handles a link.
  final DeepLinkFallback? fallback;

  /// Whether a fallback path replaces the stack instead of pushing.
  final bool replaceOnFallback;

  /// Awaited before each link is resolved, e.g. to load the user session.
  /// Should be cheap to call again once the app is ready.
  final Future<void> Function()? waitUntilReady;

  /// Accepted web hosts; `*.example.com` allows subdomains. Empty allows all.
  final Set<String> hosts;

  /// Accepted custom schemes, e.g. `myapp`. Empty allows all.
  final Set<String> schemes;

  /// Optional hook for logging or analytics.
  final DeepLinkListener? onLink;

  /// Receives errors; when `null`, errors go to [FlutterError.reportError].
  final DeepLinkErrorHandler? onError;

  /// Maximum time a link waits for [waitUntilReady] and
  /// [DeepLinkNavigator.isReady] together. A link that times out is dropped
  /// and reported to [onError], so later links are not held up.
  final Duration readyTimeout;

  /// Identical links received within this window are handled once.
  final Duration duplicateWindow;

  static const _pollInterval = Duration(milliseconds: 100);

  DeepLinkSource? _source;
  StreamSubscription<Uri>? _subscription;
  Future<void> _queue = Future<void>.value();
  Uri? _lastUri;
  DateTime? _lastReceivedAt;

  /// Starts listening and handles the link that launched the app, if any.
  /// Calling it again has no effect.
  Future<void> init() async {
    if (_subscription != null) return;
    final source = _source ??= AppLinksSource();
    _subscription = source.links.listen(_receive, onError: _reportError);
    try {
      final initial = await source.getInitialLink();
      if (initial != null) _receive(initial);
    } catch (error, stack) {
      _reportError(error, stack);
    }
  }

  /// Handles [uri] as if it was received from the platform, e.g. a link
  /// carried by a push notification. Never skipped as a duplicate.
  Future<void> handle(Uri uri) {
    _queue = _queue.then((_) => _process(uri));
    return _queue;
  }

  /// Returns where [uri] leads without navigating, or `null` if ignored.
  DeepLinkTarget? resolve(Uri uri) {
    final link = DeepLink.fromUri(uri);
    return accepts(link) ? _resolveLink(link) : null;
  }

  /// Whether [link] passes the [hosts] and [schemes] filters.
  bool accepts(DeepLink link) {
    if (link.isWebLink) return _hostAllowed(link.uri.host.toLowerCase());
    return schemes.isEmpty || schemes.contains(link.uri.scheme.toLowerCase());
  }

  /// Stops listening for new links.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _receive(Uri uri) {
    if (_isDuplicate(uri)) return;
    unawaited(handle(uri));
  }

  bool _isDuplicate(Uri uri) {
    final now = DateTime.now();
    final last = _lastReceivedAt;
    final duplicate = uri == _lastUri &&
        last != null &&
        now.difference(last) < duplicateWindow;
    _lastUri = uri;
    _lastReceivedAt = now;
    return duplicate;
  }

  Future<void> _process(Uri uri) async {
    try {
      final link = DeepLink.fromUri(uri);
      if (!accepts(link)) return onLink?.call(link, null);
      await _waitForApp();
      final target = _resolveLink(link);
      onLink?.call(link, target);
      if (target == null) return;
      target.replace
          ? navigator.replace(target.path)
          : navigator.push(target.path);
    } catch (error, stack) {
      _reportError(error, stack);
    }
  }

  Future<void> _waitForApp() async {
    final elapsed = Stopwatch()..start();
    await waitUntilReady?.call().timeout(
          readyTimeout,
          onTimeout: () => throw TimeoutException(
            'waitUntilReady did not complete',
            readyTimeout,
          ),
        );
    while (!navigator.isReady) {
      if (elapsed.elapsed >= readyTimeout) {
        throw TimeoutException('Navigator was not ready', readyTimeout);
      }
      await Future<void>.delayed(_pollInterval);
    }
  }

  DeepLinkTarget? _resolveLink(DeepLink link) {
    for (final route in routes) {
      final match = route.match(link);
      final path = match == null ? null : route.to(match);
      if (path != null) return DeepLinkTarget(path, replace: route.replace);
    }
    final path = fallback?.call(link);
    return path == null
        ? null
        : DeepLinkTarget(path, replace: replaceOnFallback);
  }

  bool _hostAllowed(String host) {
    if (hosts.isEmpty || hosts.contains(host)) return true;
    return hosts.any((allowed) {
      if (!allowed.startsWith('*.')) return false;
      final root = allowed.substring(2);
      return host == root || host.endsWith('.$root');
    });
  }

  void _reportError(Object error, StackTrace stack) {
    if (onError != null) return onError!(error, stack);
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'deep_links_kit',
        context: ErrorDescription('while handling a deep link'),
      ),
    );
  }
}
