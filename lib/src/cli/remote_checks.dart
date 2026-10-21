import 'dart:convert';

import 'cli_logger.dart';
import 'http_fetch.dart';
import 'link_paths.dart';

/// Verifies the `.well-known` files a host serves.
class RemoteChecks {
  /// Prepares checks that report to [logger] and download with [fetch].
  RemoteChecks(this.logger, this.fetch);

  /// Where results are reported.
  final CliLogger logger;

  /// Downloads files without following redirects.
  final Fetcher fetch;

  /// Checks `assetlinks.json` on [host] for [package] and [sha256].
  Future<void> assetLinks(
    String host,
    String package,
    List<String> sha256,
  ) async {
    final json = await _download(host, 'assetlinks.json');
    if (json == null) return;
    final statements = json is List ? json : const [];
    final fingerprints = <String>{
      for (final s in statements.whereType<Map>())
        if (_isFor(s, package))
          for (final fp in s['target']['sha256_cert_fingerprints'] ?? const [])
            fp.toString().toUpperCase(),
    };
    if (fingerprints.isEmpty) {
      return logger.fail('assetlinks.json has no entry for $package');
    }
    logger.ok('assetlinks.json lists $package');
    final missing = [
      for (final fp in sha256)
        if (!fingerprints.contains(fp.toUpperCase())) fp,
    ];
    for (final fp in missing) {
      logger.fail('assetlinks.json is missing SHA-256 $fp');
    }
    if (sha256.isEmpty) {
      logger.info('Fingerprints on the server: ${fingerprints.join(', ')}');
      logger
          .info('Make sure the Play "App signing key" SHA-256 is one of them.');
    }
  }

  /// Checks `apple-app-site-association` on [host] for [appId] and [paths].
  Future<void> aasa(String host, String appId, List<String> paths) async {
    final json = await _download(host, 'apple-app-site-association');
    if (json == null) return;
    final details = json is Map && json['applinks'] is Map
        ? json['applinks']['details']
        : null;
    final detail = (details is List ? details : const [])
        .whereType<Map>()
        .where((d) => _appIds(d).contains(appId))
        .firstOrNull;
    if (detail == null) {
      return logger.fail('apple-app-site-association has no entry for $appId');
    }
    logger.ok('apple-app-site-association lists $appId');
    final served = _paths(detail);
    if (served.contains('*') || served.contains('/*')) return;
    for (final path in paths) {
      if (!served.contains(LinkPath(path).pattern)) {
        logger.warn('iOS will not open "$path" (served: ${served.join(', ')})');
      }
    }
  }

  Future<Object?> _download(String host, String name) async {
    final uri = Uri.https(host, '/.well-known/$name');
    final FetchedFile file;
    try {
      file = await fetch(uri);
    } catch (error) {
      logger.fail('$uri could not be fetched: $error');
      return null;
    }
    if (file.isRedirect) {
      logger.fail('$uri redirects to ${file.location}; serve it directly');
      return null;
    }
    if (file.status != 200) {
      logger.fail('$uri returned HTTP ${file.status}');
      return null;
    }
    if (file.contentType != 'application/json') {
      logger
          .warn('$uri is served as ${file.contentType}, not application/json');
    }
    try {
      return jsonDecode(file.body);
    } on FormatException {
      logger.fail('$uri is not valid JSON');
      return null;
    }
  }

  static bool _isFor(Map<Object?, Object?> statement, String package) {
    final target = statement['target'];
    final relation = statement['relation'];
    return target is Map &&
        target['package_name'] == package &&
        relation is List &&
        relation.contains('delegate_permission/common.handle_all_urls');
  }

  static List<String> _appIds(Map<Object?, Object?> detail) => [
        if (detail['appID'] case final String id) id,
        if (detail['appIDs'] case final List ids) ...ids.map((id) => '$id'),
      ];

  static List<String> _paths(Map<Object?, Object?> detail) => [
        if (detail['paths'] case final List paths) ...paths.map((p) => '$p'),
        if (detail['components'] case final List components)
          for (final c in components.whereType<Map>())
            if (c['/'] case final String path) path,
      ];
}
