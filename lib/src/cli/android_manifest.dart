import 'kit_config.dart';
import 'link_paths.dart';

/// The result of editing `AndroidManifest.xml`.
class ManifestEdit {
  /// Creates a result.
  const ManifestEdit(this.content, this.warnings);

  /// The new manifest text.
  final String content;

  /// Things the user should look at.
  final List<String> warnings;
}

/// Inserts a generated block of intent filters into the launcher activity.
///
/// The block sits between two marker comments, so running setup again
/// replaces it instead of adding a second copy.
class AndroidManifestEditor {
  /// Marks the beginning of the generated block.
  static const startMarker = 'deep_links_kit:start';

  /// Marks the end of the generated block.
  static const endMarker = 'deep_links_kit:end';

  static final _managedBlock = RegExp(
    '[ \\t]*<!-- $startMarker.*?$endMarker -->[ \\t]*\\r?\\n?',
    dotAll: true,
  );

  /// Returns [manifest] with the block for [config] in place.
  static ManifestEdit apply(String manifest, KitConfig config) {
    final clean = manifest.replaceAll(_managedBlock, '');
    final close = _launcherActivityEnd(clean);
    final lineStart = clean.lastIndexOf('\n', close) + 1;
    final indent = clean.substring(lineStart, close);
    final warnings = _duplicateWarnings(clean, config);
    final hasOwnFlag = clean.contains('flutter_deeplinking_enabled');
    final block = _block(
      config,
      '$indent    ',
      clean.contains('\r\n') ? '\r\n' : '\n',
      addFlag: config.disableFlutterDeepLinking && !hasOwnFlag,
    );
    if (config.disableFlutterDeepLinking && hasOwnFlag) {
      warnings.add(
        'The manifest already sets flutter_deeplinking_enabled; '
        'make sure its value is "false".',
      );
    }
    final content = clean.replaceRange(lineStart, lineStart, block);
    return ManifestEdit(content, warnings);
  }

  /// Whether [manifest] already contains a generated block.
  static bool hasManagedBlock(String manifest) =>
      manifest.contains(startMarker) && manifest.contains(endMarker);

  /// Explains why a link would start a second copy of the app, or returns
  /// `null` when the launcher activity keeps a single copy.
  ///
  /// The first line is the problem; the others are details printed under it.
  static List<String>? launchModeWarning(String manifest) {
    final tag = _launcherActivityTag(manifest);
    if (tag == null) return null;
    final mode = _attribute(tag, 'launchMode');
    if (mode != null && mode != 'standard' && mode != 'singleTop') {
      return null;
    }
    final name = _attribute(tag, 'name')?.split('.').last ?? 'MainActivity';
    final label = '${mode ?? 'standard'}:'.padRight(12);
    return [
      if (mode == null)
        '$name has no launchMode, so Android uses "standard".'
      else
        '$name uses launchMode="$mode".',
      '${label}a link tapped in another app (WhatsApp, Chrome) starts a',
      '            second copy of the app: the splash runs again and',
      '            in-memory state (like the session) starts empty.',
      'singleTask: the link goes to the copy that is already open, and the',
      '            page opens on top of the current screen.',
      'Use android:launchMode="singleTask" on that activity.',
    ];
  }

  /// The opening `<activity ...>` tag of the launcher activity.
  static String? _launcherActivityTag(String manifest) {
    final main = manifest.indexOf('android.intent.action.MAIN');
    if (main == -1) return null;
    final opening = RegExp(r'<activity[\s>]')
        .allMatches(manifest.substring(0, main))
        .lastOrNull;
    if (opening == null) return null;
    return manifest.substring(
      opening.start,
      manifest.indexOf('>', opening.start),
    );
  }

  static String? _attribute(String tag, String name) =>
      RegExp('android:$name\\s*=\\s*"([^"]*)"').firstMatch(tag)?.group(1);

  static int _launcherActivityEnd(String manifest) {
    final main = manifest.indexOf('android.intent.action.MAIN');
    if (main == -1) {
      throw StateError('No launcher activity (action.MAIN) in the manifest');
    }
    final close = manifest.indexOf('</activity>', main);
    if (close == -1) throw StateError('The launcher activity is not closed');
    return close;
  }

  static List<String> _duplicateWarnings(String manifest, KitConfig config) {
    return [
      for (final host in config.hosts)
        if (manifest.contains('android:host="$host"'))
          'An intent-filter for host "$host" already exists outside the '
              'generated block. Remove it to avoid duplicates.',
      for (final scheme in config.schemes)
        if (manifest.contains('android:scheme="$scheme"'))
          'An intent-filter for scheme "$scheme" already exists outside the '
              'generated block. Remove it to avoid duplicates.',
    ];
  }

  static String _block(
    KitConfig config,
    String i,
    String eol, {
    required bool addFlag,
  }) {
    final lines = <String>[
      '<!-- $startMarker: generated by `dart run deep_links_kit setup` -->',
      if (addFlag) ...[
        '<meta-data',
        '    android:name="flutter_deeplinking_enabled"',
        '    android:value="false" />',
      ],
      if (config.hosts.isNotEmpty) ...[
        '<intent-filter android:autoVerify="true">',
        ..._viewIntentBody,
        '    <data android:scheme="https" />',
        for (final host in config.hosts) '    <data android:host="$host" />',
        if (!config.paths.any((path) => LinkPath(path).matchesAll))
          for (final path in config.paths)
            '    <data ${LinkPath(path).androidAttribute} />',
        '</intent-filter>',
      ],
      if (config.schemes.isNotEmpty) ...[
        '<intent-filter>',
        ..._viewIntentBody,
        for (final scheme in config.schemes)
          '    <data android:scheme="$scheme" />',
        '</intent-filter>',
      ],
      '<!-- $endMarker -->',
    ];
    return lines.map((line) => '$i$line$eol').join();
  }

  static const _viewIntentBody = [
    '    <action android:name="android.intent.action.VIEW" />',
    '    <category android:name="android.intent.category.DEFAULT" />',
    '    <category android:name="android.intent.category.BROWSABLE" />',
  ];
}
