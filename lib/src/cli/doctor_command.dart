import 'android_manifest.dart';
import 'cli_logger.dart';
import 'flutter_project.dart';
import 'http_fetch.dart';
import 'plist_editor.dart';
import 'remote_checks.dart';

/// Checks the native setup and the website files, without changing anything.
class DoctorCommand {
  /// Prepares checks for [project]. With [offline], the website is skipped.
  DoctorCommand(
    this.project,
    this.logger, {
    this.offline = false,
    this.fetch = fetchWithoutRedirects,
  });

  /// The app being checked.
  final FlutterProject project;

  /// Where results are reported.
  final CliLogger logger;

  /// Whether to skip the website checks.
  final bool offline;

  /// Downloads files; replaced in tests.
  final Fetcher fetch;

  /// Runs every check.
  Future<void> run() async {
    if (project.hasAndroid) _android();
    if (project.hasIos) _ios();
    if (!offline) await _website();
  }

  void _android() {
    logger.section('Android');
    final manifest = project.androidManifest.readAsStringSync();
    final hosts = project.config.hosts;
    if (AndroidManifestEditor.hasManagedBlock(manifest)) {
      logger.ok('AndroidManifest.xml has the generated intent filters');
    } else if (hosts.every((h) => manifest.contains('android:host="$h"'))) {
      logger.warn('Intent filters were added by hand; setup can manage them');
    } else {
      logger.fail('No generated block; run `dart run deep_links_kit setup`');
    }
    final disabled = RegExp(
      r'flutter_deeplinking_enabled"\s+android:value="false"',
    ).hasMatch(manifest);
    if (project.config.disableFlutterDeepLinking && !disabled) {
      logger.warn('Flutter deep linking is on; links may open twice');
    }
    final launchMode = AndroidManifestEditor.launchModeWarning(manifest);
    if (launchMode != null) {
      logger.warn(launchMode.first, details: launchMode.skip(1));
    }
  }

  void _ios() {
    logger.section('iOS');
    final hosts = project.config.hosts;
    final paths = project.entitlementsPaths;
    if (hosts.isNotEmpty && paths.isEmpty) {
      logger.fail('Runner has no entitlements file; run setup');
    }
    for (final path in paths) {
      final file = project.iosFile(path);
      final domains = file.existsSync()
          ? PlistEditor(file.readAsStringSync()).stringArray(
              'com.apple.developer.associated-domains',
            )
          : const <String>[];
      for (final host in hosts) {
        domains.contains('applinks:$host')
            ? logger.ok('$path has applinks:$host')
            : logger.fail('$path is missing applinks:$host');
      }
    }
    if (!project.infoPlist.existsSync()) return;
    final info = PlistEditor(project.infoPlist.readAsStringSync());
    for (final scheme in project.config.schemes) {
      info.hasUrlScheme(scheme)
          ? logger.ok('Info.plist registers $scheme://')
          : logger.fail('Info.plist does not register $scheme://');
    }
    final flutterLinks = info.boolValue('FlutterDeepLinkingEnabled');
    if (project.config.disableFlutterDeepLinking && flutterLinks != false) {
      logger
          .warn('FlutterDeepLinkingEnabled is not false; links may open twice');
    }
  }

  Future<void> _website() async {
    final checks = RemoteChecks(logger, fetch);
    final package = project.androidPackage;
    final appId = project.iosAppId;
    if (project.hasAndroid && package == null) {
      logger.warn('Android package unknown; set `android.package`');
    }
    if (project.hasIos && appId == null) {
      logger.warn('iOS app id unknown; set `ios.team_id` and `ios.bundle_id`');
    }
    for (final host in project.config.hosts) {
      final served = host.replaceFirst('*.', '');
      logger.section('Website: $served');
      if (project.hasAndroid && package != null) {
        await checks.assetLinks(served, package, project.config.sha256);
      }
      if (project.hasIos && appId != null) {
        await checks.aasa(served, appId, project.config.paths);
      }
    }
  }
}
