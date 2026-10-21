/// Where a link leads inside the app.
class DeepLinkTarget {
  /// Creates a target.
  const DeepLinkTarget(this.path, {this.replace = false});

  /// The in-app path to open, e.g. `/profile/42`.
  final String path;

  /// Whether to replace the navigation stack instead of pushing.
  final bool replace;

  @override
  bool operator ==(Object other) =>
      other is DeepLinkTarget && other.path == path && other.replace == replace;

  @override
  int get hashCode => Object.hash(path, replace);

  @override
  String toString() => 'DeepLinkTarget($path, replace: $replace)';
}
