/// An incoming link, normalized so web links and custom-scheme links can be
/// matched by the same route patterns.
///
/// For `https://example.com/p/42` the path is `/p/42`.
/// For `myapp://p/42` the URI host is `p`, so it is folded back into the
/// path and the path is also `/p/42`.
class DeepLink {
  const DeepLink._(this.uri, this.pathSegments);

  /// Creates a normalized link from a raw [uri].
  factory DeepLink.fromUri(Uri uri) {
    final segments = <String>[
      if (!_isWebScheme(uri.scheme)) uri.host,
      ...uri.pathSegments,
    ].where((segment) => segment.isNotEmpty);
    return DeepLink._(uri, List.unmodifiable(segments));
  }

  /// The raw URI as received from the platform.
  final Uri uri;

  /// The decoded, non-empty path segments after normalization.
  final List<String> pathSegments;

  /// The normalized path, always starting with `/`.
  String get path => '/${pathSegments.join('/')}';

  /// Query parameters of the raw URI.
  Map<String, String> get queryParameters => uri.queryParameters;

  /// Whether this is an `http` or `https` link (App Link / Universal Link).
  bool get isWebLink => _isWebScheme(uri.scheme);

  static bool _isWebScheme(String scheme) =>
      scheme == 'http' || scheme == 'https';

  @override
  String toString() => 'DeepLink($uri)';
}
