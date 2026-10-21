/// Reads and edits the build settings of the `Runner` target in
/// `project.pbxproj`, without touching anything else in the file.
class XcodeProject {
  /// Wraps the text of a `project.pbxproj` file.
  XcodeProject(this.content);

  /// The current file text.
  String content;

  static final _block = RegExp(r'buildSettings = \{(.*?)\};', dotAll: true);
  static final _runnerPlist =
      RegExp(r'INFOPLIST_FILE = "?Runner/Info\.plist"?;');
  static final _entitlements = RegExp(
    r'CODE_SIGN_ENTITLEMENTS = "?([^";\n]+)"?;',
  );
  static final _bundleId = RegExp(
    r'PRODUCT_BUNDLE_IDENTIFIER = "?([^";\s]+)"?;',
  );
  static final _team = RegExp(r'DEVELOPMENT_TEAM = "?([A-Z0-9]{10})"?;');

  Iterable<String> get _runnerBlocks => _block
      .allMatches(content)
      .map((m) => m.group(1)!)
      .where(_runnerPlist.hasMatch);

  /// Entitlements files used by the Runner target, relative to `ios/`.
  Set<String> get entitlementsPaths => _values(_entitlements);

  /// Literal bundle ids of the Runner target (variables are skipped).
  Set<String> get bundleIds =>
      _values(_bundleId).where((id) => !id.contains(r'$')).toSet();

  /// Apple Team IDs of the Runner target.
  Set<String> get teamIds => _values(_team);

  Set<String> _values(RegExp pattern) => {
        for (final block in _runnerBlocks)
          for (final match in pattern.allMatches(block)) match.group(1)!.trim(),
      };

  /// Points every Runner configuration without entitlements at
  /// [relativePath]. Returns whether anything changed.
  bool useEntitlements(String relativePath) {
    var changed = false;
    content = content.replaceAllMapped(_block, (match) {
      final block = match.group(0)!;
      if (!_runnerPlist.hasMatch(block) || _entitlements.hasMatch(block)) {
        return block;
      }
      changed = true;
      return block.replaceFirstMapped(
        RegExp(r'([ \t]*)INFOPLIST_FILE = '),
        (m) => '${m[1]}CODE_SIGN_ENTITLEMENTS = $relativePath;\n'
            '${m[1]}INFOPLIST_FILE = ',
      );
    });
    return changed;
  }
}
