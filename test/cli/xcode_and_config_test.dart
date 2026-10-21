import 'package:deep_links_kit/src/cli/kit_config.dart';
import 'package:deep_links_kit/src/cli/well_known.dart';
import 'package:deep_links_kit/src/cli/xcode_project.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

const _pbxproj = '''
		97C147061CF9000F007C117D /* Debug */ = {
			buildSettings = {
				DEVELOPMENT_TEAM = ABCDE12345;
				INFOPLIST_FILE = Runner/Info.plist;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.app;
			};
			name = Debug;
		};
		331C8088294A63A400263BE5 /* Debug */ = {
			buildSettings = {
				PRODUCT_BUNDLE_IDENTIFIER = com.example.app.RunnerTests;
			};
		};
		97C147071CF9000F007C117D /* Release */ = {
			buildSettings = {
				CODE_SIGN_ENTITLEMENTS = Runner/Release.entitlements;
				INFOPLIST_FILE = Runner/Info.plist;
				PRODUCT_BUNDLE_IDENTIFIER = "\$(BASE_ID)\$(SUFFIX)";
			};
		};
''';

void main() {
  group('XcodeProject', () {
    test('reads ids from the Runner target only', () {
      final project = XcodeProject(_pbxproj);
      expect(project.bundleIds, {'com.example.app'});
      expect(project.teamIds, {'ABCDE12345'});
      expect(project.entitlementsPaths, {'Runner/Release.entitlements'});
    });

    test('adds entitlements to Runner configurations that lack them', () {
      final project = XcodeProject(_pbxproj);
      expect(project.useEntitlements('Runner/Runner.entitlements'), isTrue);
      expect(
        project.content,
        contains(
          '\t\t\t\tCODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;\n'
          '\t\t\t\tINFOPLIST_FILE = Runner/Info.plist;',
        ),
      );
      expect(project.entitlementsPaths, {
        'Runner/Runner.entitlements',
        'Runner/Release.entitlements',
      });
      expect(project.useEntitlements('Runner/Runner.entitlements'), isFalse);
    });
  });

  group('KitConfig', () {
    KitConfig parse(String yaml) => KitConfig.fromYaml(loadYaml(yaml));

    test('reads single values, lists and platform sections', () {
      final config = parse('''
host: app.example.com
scheme: myapp
android:
  sha256: AB:CD
ios:
  team_id: ABCDE12345
''');
      expect(config.hosts, ['app.example.com']);
      expect(config.schemes, ['myapp']);
      expect(config.paths, ['/*']);
      expect(config.sha256, ['AB:CD']);
      expect(config.iosTeamId, 'ABCDE12345');
      expect(config.disableFlutterDeepLinking, isTrue);
    });

    test('rejects invalid values', () {
      expect(() => parse('paths: [/a]'), throwsA(isA<CliException>()));
      expect(
        () => parse('hosts: [https://a.com]'),
        throwsA(isA<CliException>()),
      );
      expect(() => parse('scheme: "1bad"'), throwsA(isA<CliException>()));
      expect(
        () => parse('hosts: [a.com]\npaths: [share]'),
        throwsA(isA<CliException>()),
      );
    });
  });

  test('builds website files', () {
    final assetLinks = WellKnownFiles.assetLinks(
      package: 'com.example.app',
      sha256: ['ab:cd'],
    );
    expect(assetLinks, contains('"package_name": "com.example.app"'));
    expect(assetLinks, contains('"AB:CD"'));
    final aasa = WellKnownFiles.appleAppSiteAssociation(
      appIds: ['T.com.example.app'],
      paths: ['/share/*'],
    );
    expect(aasa, contains('"T.com.example.app"'));
    expect(aasa, contains('"/": "/share/*"'));
  });
}
