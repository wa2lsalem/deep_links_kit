import 'package:deep_links_kit/src/cli/cli_logger.dart';
import 'package:deep_links_kit/src/cli/http_fetch.dart';
import 'package:deep_links_kit/src/cli/remote_checks.dart';
import 'package:flutter_test/flutter_test.dart';

const _assetLinks = '''
[{"relation":["delegate_permission/common.handle_all_urls"],
  "target":{"namespace":"android_app","package_name":"com.example.app",
  "sha256_cert_fingerprints":["AA:BB"]}}]
''';

const _aasa = '''
{"applinks":{"apps":[],"details":[{"appID":"T.com.example.app",
  "paths":["/share/*"]}]}}
''';

void main() {
  late StringBuffer output;
  late CliLogger logger;

  setUp(() {
    output = StringBuffer();
    logger = CliLogger(output);
  });

  RemoteChecks checks(FetchedFile file) =>
      RemoteChecks(logger, (_) async => file);

  FetchedFile json(String body) =>
      FetchedFile(status: 200, body: body, contentType: 'application/json');

  test('passes a matching assetlinks.json', () async {
    await checks(json(_assetLinks)).assetLinks('a.com', 'com.example.app', [
      'aa:bb',
    ]);
    expect(logger.failures, 0);
    expect(logger.warnings, 0);
  });

  test('fails a missing fingerprint or package', () async {
    final check = checks(json(_assetLinks));
    await check.assetLinks('a.com', 'com.example.app', ['CC:DD']);
    await check.assetLinks('a.com', 'com.other', const []);
    expect(logger.failures, 2);
  });

  test('fails redirects, errors and invalid JSON', () async {
    await checks(
      const FetchedFile(status: 301, body: '', location: 'https://b.com'),
    ).aasa('a.com', 'T.x', const []);
    await checks(const FetchedFile(status: 404, body: '')).aasa(
      'a.com',
      'T.x',
      const [],
    );
    await checks(json('<html>')).aasa('a.com', 'T.x', const []);
    await RemoteChecks(
      logger,
      (_) async => throw Exception('offline'),
    ).aasa('a.com', 'T.x', const []);
    expect(logger.failures, 4);
  });

  test('warns about the wrong content type', () async {
    await checks(
      const FetchedFile(status: 200, body: _aasa, contentType: 'text/plain'),
    ).aasa('a.com', 'T.com.example.app', const []);
    expect(logger.warnings, 1);
    expect(logger.failures, 0);
  });

  test('checks the app id and paths in the legacy AASA format', () async {
    final check = checks(json(_aasa));
    await check.aasa('a.com', 'T.com.example.app', ['/share/*', '/p/*']);
    expect(logger.failures, 0);
    expect(logger.warnings, 1);
    expect(output.toString(), contains('"/p/*"'));
    await check.aasa('a.com', 'T.other', const []);
    expect(logger.failures, 1);
  });

  test('accepts every path when the server allows all', () async {
    const all = '{"applinks":{"details":[{"appIDs":["T.x"],'
        '"components":[{"/":"/*"}]}]}}';
    await checks(json(all)).aasa('a.com', 'T.x', ['/p/*']);
    expect(logger.warnings, 0);
  });
}
