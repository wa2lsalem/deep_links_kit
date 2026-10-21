/// A configured path glob such as `/share/*`, translated for each platform.
///
/// `*` matches any characters and `?` matches one, as in Apple's
/// `apple-app-site-association` components.
class LinkPath {
  /// Wraps a configured [pattern].
  const LinkPath(this.pattern);

  /// The configured glob, starting with `/`.
  final String pattern;

  /// Whether this path accepts every URL on the host.
  bool get matchesAll => pattern == '/*';

  /// The `<data>` attribute that matches this path on Android, or `null`
  /// when every path is accepted.
  String? get androidAttribute {
    if (matchesAll) return null;
    final star = pattern.indexOf('*');
    final hasSingle = pattern.contains('?');
    if (star == -1 && !hasSingle) return 'android:path="$pattern"';
    if (star == pattern.length - 1 && !hasSingle) {
      return 'android:pathPrefix="${pattern.substring(0, star)}"';
    }
    final regex = pattern.replaceAll('*', '.*').replaceAll('?', '.');
    return 'android:pathPattern="$regex"';
  }
}
