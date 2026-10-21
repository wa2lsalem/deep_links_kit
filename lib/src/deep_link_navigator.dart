import 'package:flutter/widgets.dart';

/// Opens a resolved in-app path. Plug in any router through this interface.
///
/// ```dart
/// // go_router
/// DeepLinkNavigator.custom(push: router.push, replace: router.go);
///
/// // Navigator 1.0 named routes
/// DeepLinkNavigator.named(navigatorKey);
/// ```
abstract class DeepLinkNavigator {
  /// Allows subclasses to have const constructors.
  const DeepLinkNavigator();

  /// Wraps your own functions, for go_router, auto_route or any other router.
  ///
  /// [replace] defaults to [push]. [isReady] reports whether navigation is
  /// possible yet (for example, the first frame was built); it defaults to
  /// always ready.
  const factory DeepLinkNavigator.custom({
    required void Function(String path) push,
    void Function(String path)? replace,
    bool Function()? isReady,
  }) = _CustomDeepLinkNavigator;

  /// Uses Navigator 1.0 named routes through [navigatorKey].
  const factory DeepLinkNavigator.named(
    GlobalKey<NavigatorState> navigatorKey,
  ) = _NamedDeepLinkNavigator;

  /// Whether the app can navigate yet. Polled until it returns `true`.
  bool get isReady;

  /// Opens [path] on top of the current stack.
  void push(String path);

  /// Opens [path] and replaces the current stack.
  void replace(String path);
}

class _CustomDeepLinkNavigator extends DeepLinkNavigator {
  const _CustomDeepLinkNavigator({
    required void Function(String path) push,
    void Function(String path)? replace,
    bool Function()? isReady,
  })  : _push = push,
        _replace = replace,
        _isReady = isReady;

  final void Function(String path) _push;
  final void Function(String path)? _replace;
  final bool Function()? _isReady;

  @override
  bool get isReady => _isReady?.call() ?? true;

  @override
  void push(String path) => _push(path);

  @override
  void replace(String path) => (_replace ?? _push)(path);
}

class _NamedDeepLinkNavigator extends DeepLinkNavigator {
  const _NamedDeepLinkNavigator(this._navigatorKey);

  final GlobalKey<NavigatorState> _navigatorKey;

  @override
  bool get isReady => _navigatorKey.currentState != null;

  @override
  void push(String path) => _navigatorKey.currentState!.pushNamed(path);

  @override
  void replace(String path) =>
      _navigatorKey.currentState!.pushNamedAndRemoveUntil(path, (_) => false);
}
