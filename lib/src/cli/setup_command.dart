import 'dart:io';

import 'android_manifest.dart';
import 'cli_logger.dart';
import 'flutter_project.dart';
import 'plist_editor.dart';
import 'setup_lock.dart';

/// Applies the configuration to the Android and iOS projects.
class SetupCommand {
  /// Prepares setup for [project]. With [dryRun], nothing is written.
  SetupCommand(this.project, this.logger, {this.dryRun = false});

  /// The app being configured.
  final FlutterProject project;

  /// Where progress is reported.
  final CliLogger logger;

  /// Whether to only report what would change.
  final bool dryRun;

  static const _associatedDomains = 'com.apple.developer.associated-domains';
  static const _defaultEntitlements = 'Runner/Runner.entitlements';

  /// Runs every step.
  void run() {
    final previous = SetupLock.read(project.root);
    if (project.hasAndroid) {
      _android();
    } else {
      logger.warn('No Android project found, skipped');
    }
    if (project.hasIos) {
      _iosEntitlements(previous);
      _iosInfoPlist(previous);
    } else {
      logger.warn('No iOS project found, skipped');
    }
    logger.line();
    _save(
      SetupLock.file(project.root),
      SetupLock.fromConfig(project.config).encode(),
      SetupLock.fileName,
    );
  }

  void _android() {
    logger.section('Android');
    final file = project.androidManifest;
    final edit = AndroidManifestEditor.apply(
      file.readAsStringSync(),
      project.config,
    );
    _save(file, edit.content, 'AndroidManifest.xml intent filters');
    edit.warnings.forEach(logger.warn);
    final launchMode = AndroidManifestEditor.launchModeWarning(edit.content);
    if (launchMode != null) {
      logger.warn(launchMode.first, details: launchMode.skip(1));
    }
  }

  void _iosEntitlements(SetupLock? previous) {
    logger.section('iOS');
    final hosts = project.config.hosts;
    final domains = [for (final host in hosts) 'applinks:$host'];
    final stale = [
      for (final host in previous?.hosts ?? const <String>[])
        if (!hosts.contains(host)) 'applinks:$host',
    ];
    var paths = project.entitlementsPaths;
    if (paths.isEmpty) {
      if (hosts.isEmpty) return;
      final xcode = project.xcodeProject!;
      if (xcode.useEntitlements(_defaultEntitlements)) {
        _save(
          project.xcodeProjectFile,
          xcode.content,
          'CODE_SIGN_ENTITLEMENTS in project.pbxproj',
        );
      }
      paths = {_defaultEntitlements};
    }
    for (final path in paths) {
      final file = project.iosFile(path);
      if (!file.existsSync() && hosts.isEmpty) continue;
      final plist = PlistEditor(
        file.existsSync() ? file.readAsStringSync() : PlistEditor.emptyDocument,
      );
      final changes = [
        for (final d in plist.removeFromStringArray(_associatedDomains, stale))
          'removed $d',
        for (final d in plist.addToStringArray(_associatedDomains, domains))
          'added $d',
      ];
      if (changes.isEmpty) {
        logger.ok('$path is up to date');
      } else {
        _save(file, plist.content, '$path: ${changes.join(', ')}');
      }
      if (previous == null) {
        _warnUntracked(path, [
          for (final d in plist.stringArray(_associatedDomains))
            if (d.startsWith('applinks:') && !domains.contains(d)) d,
        ]);
      }
    }
    if (hosts.isEmpty) return;
    logger.info(
      'Enable "Associated Domains" for this App ID in the Apple Developer '
      'portal, or signing will fail.',
    );
  }

  void _iosInfoPlist(SetupLock? previous) {
    final file = project.infoPlist;
    if (!file.existsSync()) return logger.warn('ios/Runner/Info.plist missing');
    final config = project.config;
    final plist = PlistEditor(file.readAsStringSync());
    const flag = 'FlutterDeepLinkingEnabled';
    final changes = <String>[
      for (final scheme in previous?.schemes ?? const <String>[])
        if (!config.schemes.contains(scheme) && plist.removeUrlScheme(scheme))
          'removed $scheme://',
      for (final scheme in config.schemes)
        if (plist.addUrlScheme(scheme)) 'added $scheme://',
      if (config.disableFlutterDeepLinking && plist.setBool(flag, false))
        '$flag = false',
      if (!config.disableFlutterDeepLinking &&
          (previous?.disabledFlutterDeepLinking ?? false) &&
          plist.removeKey(flag))
        'removed $flag',
    ];
    if (changes.isEmpty) {
      logger.ok('Info.plist is up to date');
    } else {
      _save(file, plist.content, 'Info.plist: ${changes.join(', ')}');
    }
    if (previous == null) {
      _warnUntracked('Info.plist', [
        for (final scheme in plist.urlSchemes)
          if (!config.schemes.contains(scheme)) '$scheme://',
      ]);
    }
  }

  /// On the first run there is no lock yet, so values outside the config
  /// cannot be told apart from other plugins' entries. They are only listed.
  void _warnUntracked(String file, List<String> values) {
    if (values.isEmpty) return;
    logger.warn(
      '$file also has ${values.join(', ')}, which is not in your config.',
      details: [
        'setup has no record of adding it, so it was left alone.',
        'Remove it by hand if it came from an earlier setup; from now on',
        'setup records its changes in ${SetupLock.fileName}.',
      ],
    );
  }

  void _save(File file, String content, String label) {
    final unchanged = file.existsSync() && file.readAsStringSync() == content;
    if (unchanged) return logger.ok('$label (no change)');
    if (!dryRun) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }
    logger.ok(dryRun ? 'Would update $label' : 'Updated $label');
  }
}
