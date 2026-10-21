import 'deep_link.dart';
import 'deep_link_match.dart';

/// Builds the in-app path for a matched link, or returns `null` to let the
/// next route try.
typedef DeepLinkResolver = String? Function(DeepLinkMatch match);

/// Maps a link pattern to an in-app path.
///
/// Pattern syntax (matched against the normalized [DeepLink.path]):
/// - `p`: a literal segment.
/// - `:id`: captures one segment into `match['id']`.
/// - `:name?`: an optional trailing capture.
/// - `*`: captures every remaining segment into `match.rest`; must be last.
///
/// A link does not match when a captured value contains `/`, `?`, `#` or
/// `\` after decoding, or is `.` or `..`, so captures are safe to put in a
/// path.
///
/// ```dart
/// DeepLinkRoute('/p/:id/:name?', to: (m) => '/profile/${m['id']}');
/// ```
class DeepLinkRoute {
  /// Creates a route. Throws [ArgumentError] if [pattern] is invalid.
  DeepLinkRoute(
    this.pattern, {
    required this.to,
    this.replace = false,
    this.caseSensitive = false,
  }) : _segments = _PatternSegment.parseAll(pattern);

  /// The pattern this route matches, e.g. `/p/:id`.
  final String pattern;

  /// Builds the in-app path from the match.
  final DeepLinkResolver to;

  /// Whether to replace the navigation stack instead of pushing on top.
  final bool replace;

  /// Whether literal segments must match with the same letter case.
  final bool caseSensitive;

  final List<_PatternSegment> _segments;

  /// Returns the match if [link] fits this pattern, otherwise `null`.
  DeepLinkMatch? match(DeepLink link) {
    final input = link.pathSegments;
    final params = <String, String>{};
    for (var i = 0; i < _segments.length; i++) {
      final segment = _segments[i];
      if (segment.isWildcard) {
        final rest = i < input.length ? input.sublist(i) : const <String>[];
        if (!rest.every(_isSafe)) return null;
        return DeepLinkMatch(link: link, params: params, rest: rest);
      }
      if (i >= input.length) {
        if (segment.isOptional) continue;
        return null;
      }
      if (segment.isParam) {
        if (!_isSafe(input[i])) return null;
        params[segment.value] = input[i];
      } else if (!segment.matchesLiteral(input[i], caseSensitive)) {
        return null;
      }
    }
    if (input.length > _segments.length) return null;
    return DeepLinkMatch(link: link, params: params);
  }

  /// Captured values end up inside in-app paths, so a value that decodes to
  /// `/`, `?`, `#` or a dot segment (`%2F`, `%3F`, `..`) could open a
  /// different page than the pattern allows. Such links do not match.
  static bool _isSafe(String value) =>
      value != '.' && value != '..' && !value.contains(RegExp(r'[/?#\\]'));

  @override
  String toString() => 'DeepLinkRoute($pattern)';
}

class _PatternSegment {
  const _PatternSegment.literal(this.value)
      : isParam = false,
        isOptional = false,
        isWildcard = false;

  const _PatternSegment.param(this.value, {required this.isOptional})
      : isParam = true,
        isWildcard = false;

  const _PatternSegment.wildcard()
      : value = '*',
        isParam = false,
        isOptional = true,
        isWildcard = true;

  final String value;
  final bool isParam;
  final bool isOptional;
  final bool isWildcard;

  bool matchesLiteral(String input, bool caseSensitive) => caseSensitive
      ? input == value
      : input.toLowerCase() == value.toLowerCase();

  static List<_PatternSegment> parseAll(String pattern) {
    final raw = pattern.split('/').where((s) => s.isNotEmpty).toList();
    final segments = <_PatternSegment>[];
    for (var i = 0; i < raw.length; i++) {
      final segment = _parse(raw[i], pattern);
      _validate(segment, segments, pattern, isLast: i == raw.length - 1);
      segments.add(segment);
    }
    return List.unmodifiable(segments);
  }

  static _PatternSegment _parse(String raw, String pattern) {
    if (raw == '*') return const _PatternSegment.wildcard();
    if (!raw.startsWith(':')) return _PatternSegment.literal(raw);
    final isOptional = raw.endsWith('?');
    final name = raw.substring(1, isOptional ? raw.length - 1 : raw.length);
    if (name.isEmpty) {
      throw ArgumentError.value(pattern, 'pattern', 'Empty parameter name');
    }
    return _PatternSegment.param(name, isOptional: isOptional);
  }

  static void _validate(
    _PatternSegment segment,
    List<_PatternSegment> previous,
    String pattern, {
    required bool isLast,
  }) {
    String? problem;
    if (segment.isWildcard && !isLast) {
      problem = '`*` must be the last segment';
    } else if (!segment.isOptional && previous.any((s) => s.isOptional)) {
      problem = 'Required segments cannot follow optional ones';
    } else if (segment.isParam &&
        previous.any((s) => s.isParam && s.value == segment.value)) {
      problem = 'Duplicate parameter `:${segment.value}`';
    }
    if (problem != null) {
      throw ArgumentError.value(pattern, 'pattern', problem);
    }
  }
}
