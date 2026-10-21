/// Small, formatting-preserving edits to the top-level dictionary of an XML
/// property list (`Info.plist`, `*.entitlements`).
class PlistEditor {
  /// Wraps the text of a plist file.
  PlistEditor(this.content);

  /// The current file text.
  String content;

  /// An empty plist, used to create a missing entitlements file.
  static const emptyDocument = '<?xml version="1.0" encoding="UTF-8"?>\n'
      '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
      '"http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
      '<plist version="1.0">\n'
      '<dict>\n'
      '</dict>\n'
      '</plist>\n';

  static final _arrayOpen = RegExp(r'<array\s*/?>');
  static final _string = RegExp(r'<string>(.*?)</string>');
  static final _bool = RegExp(r'<(true|false)\s*/>');

  String get _eol => content.contains('\r\n') ? '\r\n' : '\n';

  String get _unit =>
      RegExp(r'\n([ \t]+)<key>').firstMatch(content)?.group(1) ?? '\t';

  int _keyIndex(String key) => content.indexOf('<key>$key</key>');

  /// The strings in the array stored under [key].
  List<String> stringArray(String key) {
    final keyAt = _keyIndex(key);
    if (keyAt == -1) return const [];
    final open = content.indexOf(_arrayOpen, keyAt);
    final close = content.indexOf('</array>', keyAt);
    if (open == -1 || close == -1 || content[open + 6] == '/') return const [];
    return [
      for (final m in _string.allMatches(content.substring(open, close)))
        m.group(1)!,
    ];
  }

  /// Adds the [values] missing from the array under [key], creating it when
  /// needed. Returns the values that were added.
  List<String> addToStringArray(String key, List<String> values) {
    final existing = stringArray(key);
    final missing = [
      for (final v in values)
        if (!existing.contains(v)) v,
    ];
    if (missing.isEmpty) return const [];
    final strings = [for (final v in missing) '<string>$v</string>'];
    final keyAt = _keyIndex(key);
    if (keyAt == -1) {
      _insertTopLevel([
        '<key>$key</key>',
        '<array>',
        for (final s in strings) '$_unit$s',
        '</array>',
      ]);
    } else {
      final close = _expandArray(content.indexOf(_arrayOpen, keyAt));
      final lineStart = _lineStart(close);
      _insertLines(lineStart, '${_indentAt(lineStart)}$_unit', strings);
    }
    return missing;
  }

  /// The boolean stored under [key], or `null` if absent.
  bool? boolValue(String key) {
    final keyAt = _keyIndex(key);
    if (keyAt == -1) return null;
    return _bool.firstMatch(content.substring(keyAt))?.group(1) == 'true';
  }

  /// Stores [value] under [key]. Returns whether anything changed.
  bool setBool(String key, bool value) {
    if (boolValue(key) == value) return false;
    final keyAt = _keyIndex(key);
    if (keyAt == -1) {
      _insertTopLevel(['<key>$key</key>', '<$value/>']);
    } else {
      final match = _bool.allMatches(content, keyAt).first;
      content = content.replaceRange(match.start, match.end, '<$value/>');
    }
    return true;
  }

  /// Whether any `CFBundleURLSchemes` array contains [scheme].
  bool hasUrlScheme(String scheme) => RegExp(
        r'<key>CFBundleURLSchemes</key>\s*<array>(.*?)</array>',
        dotAll: true,
      ).allMatches(content).any((m) => m.group(1)!.contains('>$scheme<'));

  /// Registers [scheme] under `CFBundleURLTypes`. Returns whether it changed.
  bool addUrlScheme(String scheme) {
    if (hasUrlScheme(scheme)) return false;
    final u = _unit;
    final entry = [
      '<dict>',
      '$u<key>CFBundleTypeRole</key>',
      '$u<string>Editor</string>',
      '$u<key>CFBundleURLSchemes</key>',
      '$u<array>',
      '$u$u<string>$scheme</string>',
      '$u</array>',
      '</dict>',
    ];
    final keyAt = _keyIndex('CFBundleURLTypes');
    if (keyAt == -1) {
      _insertTopLevel([
        '<key>CFBundleURLTypes</key>',
        '<array>',
        for (final line in entry) '$u$line',
        '</array>',
      ]);
      return true;
    }
    final open = content.indexOf(_arrayOpen, keyAt);
    _expandArray(open);
    final next = content.indexOf('\n', open) + 1;
    _insertLines(next, '${_indentAt(_lineStart(open))}$u', entry);
    return true;
  }

  /// Every scheme listed under `CFBundleURLSchemes`.
  List<String> get urlSchemes => [
        for (final m in RegExp(
          r'<key>CFBundleURLSchemes</key>\s*<array>(.*?)</array>',
          dotAll: true,
        ).allMatches(content))
          for (final s in _string.allMatches(m.group(1)!)) s.group(1)!,
      ];

  /// Removes [values] from the array under [key], and the key itself once
  /// the array is empty. Returns the values that were removed.
  List<String> removeFromStringArray(String key, List<String> values) {
    final removed = <String>[];
    for (final value in values) {
      final keyAt = _keyIndex(key);
      if (keyAt == -1) break;
      final close = content.indexOf('</array>', keyAt);
      final line = _stringLine(value, keyAt, close);
      if (line == null) continue;
      _removeLines(line.start, line.end);
      removed.add(value);
    }
    if (removed.isNotEmpty && stringArray(key).isEmpty) _removeEntry(key);
    return removed;
  }

  /// Unregisters [scheme]: drops its `CFBundleURLTypes` entry when it was the
  /// entry's only scheme, otherwise just the scheme. Returns whether it
  /// changed.
  bool removeUrlScheme(String scheme) {
    final schemes = RegExp(
      r'<key>CFBundleURLSchemes</key>\s*<array>(.*?)</array>',
      dotAll: true,
    );
    final match = schemes
        .allMatches(content)
        .where((m) => m.group(1)!.contains('<string>$scheme</string>'))
        .firstOrNull;
    if (match == null) return false;
    final dictStart = content.lastIndexOf('<dict>', match.start);
    final dictEnd = content.indexOf('</dict>', match.end);
    if (_string.allMatches(match.group(1)!).length > 1 || dictStart == -1) {
      final line = _stringLine(scheme, match.start, match.end)!;
      _removeLines(line.start, line.end);
    } else {
      _removeLines(dictStart, dictEnd);
    }
    final typesAt = _keyIndex('CFBundleURLTypes');
    final typesClose = _closingArray(content.indexOf(_arrayOpen, typesAt));
    if (!content.substring(typesAt, typesClose).contains('<dict>')) {
      _removeEntry('CFBundleURLTypes');
    }
    return true;
  }

  /// Removes [key] and its value. Returns whether it was present.
  bool removeKey(String key) {
    if (_keyIndex(key) == -1) return false;
    _removeEntry(key);
    return true;
  }

  /// Turns `<array/>` at [open] into an open/close pair and returns the
  /// index of the matching `</array>`.
  int _expandArray(int open) {
    if (content.startsWith('<array/>', open)) {
      final indent = _indentAt(_lineStart(open));
      content = content.replaceRange(
        open,
        open + '<array/>'.length,
        '<array>$_eol$indent</array>',
      );
    }
    return content.indexOf('</array>', open);
  }

  void _insertTopLevel(List<String> lines) {
    final close = content.lastIndexOf('</dict>');
    if (close == -1) throw const FormatException('No top-level <dict>');
    final lineStart = _lineStart(close);
    _insertLines(lineStart, '${_indentAt(lineStart)}$_unit', lines);
  }

  void _insertLines(int at, String indent, List<String> lines) {
    final eol = _eol;
    final text = lines.map((line) => '$indent$line$eol').join();
    content = content.replaceRange(at, at, text);
  }

  /// The `<string>value</string>` element between [from] and [to].
  ({int start, int end})? _stringLine(String value, int from, int to) {
    final element = '<string>$value</string>';
    final at = content.indexOf(element, from);
    if (at == -1 || at > to) return null;
    return (start: at, end: at + element.length);
  }

  /// Removes `<key>key</key>` and the value right after it.
  void _removeEntry(String key) {
    final keyAt = _keyIndex(key);
    final valueAt = content.indexOf('<', keyAt + '<key>$key</key>'.length);
    final end = content.startsWith(RegExp(r'<array\s*/>'), valueAt) ||
            content.startsWith(_bool, valueAt)
        ? content.indexOf('>', valueAt)
        : content.startsWith('<array', valueAt)
            ? _closingArray(valueAt)
            : content.indexOf('>', content.indexOf('</', valueAt));
    _removeLines(keyAt, end);
  }

  /// The index of the `</array>` that closes the `<array>` at [open].
  int _closingArray(int open) {
    var depth = 0;
    for (final m in RegExp(r'<array\s*>|</array>').allMatches(content, open)) {
      depth += m.group(0)!.startsWith('</') ? -1 : 1;
      if (depth == 0) return m.start;
    }
    return content.length;
  }

  /// Removes the whole lines that hold the text from [from] to [to].
  void _removeLines(int from, int to) {
    final start = _lineStart(from);
    final newline = content.indexOf('\n', to);
    final end = newline == -1 ? content.length : newline + 1;
    content = content.replaceRange(start, end, '');
  }

  int _lineStart(int index) => content.lastIndexOf('\n', index) + 1;

  String _indentAt(int lineStart) =>
      RegExp(r'[ \t]*').matchAsPrefix(content, lineStart)!.group(0)!;
}
