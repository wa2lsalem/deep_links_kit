import 'dart:io';

import 'cli_logger.dart';
import 'flutter_project.dart';
import 'well_known.dart';

/// Writes `assetlinks.json` and `apple-app-site-association` for the website.
class GenerateCommand {
  /// Prepares generation for [project] into [outputDir].
  GenerateCommand(this.project, this.logger, this.outputDir);

  /// The app the files describe.
  final FlutterProject project;

  /// Where progress is reported.
  final CliLogger logger;

  /// Receives a `.well-known` folder.
  final Directory outputDir;

  /// Writes the files that can be built from the configuration.
  void run() {
    final config = project.config;
    if (config.hosts.isEmpty) {
      return logger.warn('No `hosts` configured; nothing to generate');
    }
    final wellKnown = Directory('${outputDir.path}/.well-known')
      ..createSync(recursive: true);
    logger.section('Website files');
    _assetLinks(wellKnown);
    _aasa(wellKnown);
    logger.line();
    logger.info('Upload them to https://<host>/.well-known/ for each host:');
    for (final host in config.hosts) {
      logger.info('  - ${host.replaceFirst('*.', '')}');
    }
    logger.info('Serve both with HTTP 200, Content-Type: application/json and');
    logger.info('no redirects. Then run `dart run deep_links_kit doctor`.');
  }

  void _assetLinks(Directory wellKnown) {
    final package = project.androidPackage;
    if (package == null) {
      return logger.fail(
        'Android package unknown; set `android.package` in the config',
      );
    }
    final sha256 = project.config.sha256;
    File('${wellKnown.path}/assetlinks.json').writeAsStringSync(
      WellKnownFiles.assetLinks(package: package, sha256: sha256),
    );
    logger.ok('assetlinks.json for $package');
    if (sha256.isEmpty) {
      logger.warn(
        'No `android.sha256` configured; replace '
        '${WellKnownFiles.sha256Placeholder} in the file.',
      );
    }
    logger.info(
      'On Google Play, include the "App signing key" SHA-256 from '
      'Play Console > App integrity, not only your upload key.',
    );
  }

  void _aasa(Directory wellKnown) {
    final appId = project.iosAppId;
    if (appId == null) {
      return logger.fail(
        'iOS app id unknown; set `ios.team_id` and `ios.bundle_id`',
      );
    }
    File('${wellKnown.path}/apple-app-site-association').writeAsStringSync(
      WellKnownFiles.appleAppSiteAssociation(
        appIds: [appId],
        paths: project.config.paths,
      ),
    );
    logger.ok('apple-app-site-association for $appId');
  }
}
