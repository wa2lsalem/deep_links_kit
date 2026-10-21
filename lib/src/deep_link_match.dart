import 'deep_link.dart';

/// The result of matching a [DeepLink] against a route pattern.
class DeepLinkMatch {
  /// Creates a match. Usually created by the route, not by app code.
  const DeepLinkMatch({
    required this.link,
    this.params = const {},
    this.rest = const [],
  });

  /// The link that was matched.
  final DeepLink link;

  /// Values captured by `:name` segments in the pattern.
  final Map<String, String> params;

  /// Segments captured by a trailing `*` in the pattern.
  final List<String> rest;

  /// Shortcut for `params[name]`.
  String? operator [](String name) => params[name];

  /// Query parameters of the matched link.
  Map<String, String> get query => link.queryParameters;
}
