import 'dart:convert';

import 'link_paths.dart';

/// Builds the files the website must serve under `/.well-known/`.
class WellKnownFiles {
  const WellKnownFiles._();

  /// Placeholder written when no fingerprint is configured yet.
  static const sha256Placeholder = 'REPLACE_WITH_RELEASE_SHA256';

  static const _encoder = JsonEncoder.withIndent('  ');

  /// `assetlinks.json` for Android App Links.
  static String assetLinks({
    required String package,
    required List<String> sha256,
  }) =>
      '${_encoder.convert([
            {
              'relation': ['delegate_permission/common.handle_all_urls'],
              'target': {
                'namespace': 'android_app',
                'package_name': package,
                'sha256_cert_fingerprints': sha256.isEmpty
                    ? [sha256Placeholder]
                    : [for (final fp in sha256) fp.toUpperCase()],
              },
            },
          ])}\n';

  /// `apple-app-site-association` for iOS Universal Links.
  static String appleAppSiteAssociation({
    required List<String> appIds,
    required List<String> paths,
  }) =>
      '${_encoder.convert({
            'applinks': {
              'details': [
                {
                  'appIDs': appIds,
                  'components': [
                    for (final path in paths) {'/': LinkPath(path).pattern},
                  ],
                },
              ],
            },
          })}\n';
}
