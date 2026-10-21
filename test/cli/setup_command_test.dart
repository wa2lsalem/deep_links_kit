import 'dart:io';

import 'package:deep_links_kit/src/cli/cli_logger.dart';
import 'package:deep_links_kit/src/cli/flutter_project.dart';
import 'package:deep_links_kit/src/cli/kit_config.dart';
import 'package:deep_links_kit/src/cli/plist_editor.dart';
import 'package:deep_links_kit/src/cli/setup_command.dart';
import 'package:deep_links_kit/src/cli/setup_lock.dart';
import 'package:flutter_test/flutter_test.dart';

const _manifest = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <activity android:name=".MainActivity" android:launchMode="singleTask">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
''';

const _pbxproj = '''
			buildSettings = {
				CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;
				DEVELOPMENT_TEAM = ABCDE12345;
				INFOPLIST_FILE = Runner/Info.plist;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.app;
			};
''';

/// An Info.plist where another plugin (Facebook) registered `fb123`.
const _info = '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
\t<key>CFBundleName</key>
\t<string>App</string>
\t<key>CFBundleURLTypes</key>
\t<array>
\t\t<dict>
\t\t\t<key>CFBundleURLSchemes</key>
\t\t\t<array>
\t\t\t\t<string>fb123</string>
\t\t\t</array>
\t\t</dict>
\t</array>
</dict>
</plist>
''';

void main() {
  late Directory root;
  late StringBuffer output;

  setUp(() {
    root = Directory.systemTemp.createTempSync('deep_links_kit_setup');
    output = StringBuffer();
    void write(String path, String content) =>
        (File('${root.path}/$path')..createSync(recursive: true))
            .writeAsStringSync(content);
    write('android/app/src/main/AndroidManifest.xml', _manifest);
    write('ios/Runner.xcodeproj/project.pbxproj', _pbxproj);
    write('ios/Runner/Runner.entitlements', PlistEditor.emptyDocument);
    write('ios/Runner/Info.plist', _info);
  });

  tearDown(() => root.deleteSync(recursive: true));

  void setup(KitConfig config) =>
      SetupCommand(FlutterProject(root, config), CliLogger(output)).run();

  PlistEditor plist(String path) =>
      PlistEditor(File('${root.path}/ios/Runner/$path').readAsStringSync());

  String manifest() => File(
        '${root.path}/android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

  const domains = 'com.apple.developer.associated-domains';

  test('replaces old values on both platforms and keeps foreign ones', () {
    setup(const KitConfig(hosts: ['old.com'], schemes: ['namaa']));
    setup(const KitConfig(hosts: ['new.com'], schemes: ['nama']));

    expect(plist('Info.plist').urlSchemes, unorderedEquals(['fb123', 'nama']));
    expect(plist('Runner.entitlements').stringArray(domains), [
      'applinks:new.com',
    ]);
    expect(manifest(), contains('android:scheme="nama"'));
    expect(manifest(), isNot(contains('namaa')));
    expect(manifest(), isNot(contains('old.com')));
  });

  test('cleans up completely when everything is removed', () {
    setup(const KitConfig(hosts: ['a.com'], schemes: ['myapp']));
    setup(
      const KitConfig(schemes: ['other'], disableFlutterDeepLinking: false),
    );

    final info = plist('Info.plist');
    expect(info.urlSchemes, unorderedEquals(['fb123', 'other']));
    expect(info.boolValue('FlutterDeepLinkingEnabled'), isNull);
    expect(plist('Runner.entitlements').content, isNot(contains(domains)));
  });

  test('removes CFBundleURLTypes once its last entry is gone', () {
    File('${root.path}/ios/Runner/Info.plist').writeAsStringSync(
      _info.replaceFirst('fb123', 'myapp'),
    );
    setup(const KitConfig(hosts: ['a.com'], schemes: ['myapp']));
    setup(const KitConfig(hosts: ['a.com']));
    expect(plist('Info.plist').content, isNot(contains('CFBundleURLTypes')));
  });

  test('records its changes in the lock file', () {
    setup(const KitConfig(hosts: ['a.com'], schemes: ['myapp']));
    final lock = SetupLock.read(root)!;
    expect(lock.hosts, ['a.com']);
    expect(lock.schemes, ['myapp']);
    expect(lock.disabledFlutterDeepLinking, isTrue);
  });

  test('only warns about unknown values on the first run', () {
    setup(const KitConfig(schemes: ['myapp']));
    expect(output.toString(), contains('also has fb123://'));

    output.clear();
    setup(const KitConfig(schemes: ['myapp']));
    expect(output.toString(), isNot(contains('also has')));
  });

  test('a dry run changes nothing, not even the lock', () {
    SetupCommand(
      FlutterProject(root, const KitConfig(schemes: ['myapp'])),
      CliLogger(output),
      dryRun: true,
    ).run();
    expect(plist('Info.plist').content, _info);
    expect(SetupLock.read(root), isNull);
  });
}
