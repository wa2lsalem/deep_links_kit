import 'package:deep_links_kit/src/cli/android_manifest.dart';
import 'package:deep_links_kit/src/cli/kit_config.dart';
import 'package:deep_links_kit/src/cli/link_paths.dart';
import 'package:flutter_test/flutter_test.dart';

const _manifest = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <activity android:name=".Other" />
    </application>
</manifest>
''';

const _config = KitConfig(
  hosts: ['app.example.com'],
  schemes: ['myapp'],
  paths: ['/share/*', '/p/*'],
);

void main() {
  test('adds the block inside the launcher activity', () {
    final edit = AndroidManifestEditor.apply(_manifest, _config);
    final block = edit.content.substring(
      edit.content.indexOf(AndroidManifestEditor.startMarker),
      edit.content.indexOf('</activity>'),
    );
    expect(block, contains('android:host="app.example.com"'));
    expect(block, contains('android:pathPrefix="/share/"'));
    expect(block, contains('android:scheme="myapp"'));
    expect(block, contains('flutter_deeplinking_enabled'));
    expect(block, contains('android:autoVerify="true"'));
    expect(
      edit.content,
      contains('            <intent-filter android:autoVerify="true">'),
    );
    expect(edit.warnings, isEmpty);
  });

  test('replaces its own block when run again', () {
    final first = AndroidManifestEditor.apply(_manifest, _config).content;
    final second = AndroidManifestEditor.apply(first, _config).content;
    expect(second, first);
    const changed = KitConfig(hosts: ['new.example.com']);
    final third = AndroidManifestEditor.apply(second, changed).content;
    expect(third, isNot(contains('app.example.com')));
    expect(third, contains('new.example.com'));
    expect(AndroidManifestEditor.startMarker.allMatches(third), hasLength(1));
  });

  test('omits path filters when every path is accepted', () {
    const config = KitConfig(hosts: ['a.com'], paths: ['/*', '/p/*']);
    final content = AndroidManifestEditor.apply(_manifest, config).content;
    expect(content, isNot(contains('android:path')));
  });

  test('warns about hand-written filters for the same host or scheme', () {
    final manual = _manifest.replaceFirst(
      '</intent-filter>',
      '</intent-filter>\n<data android:host="app.example.com" />'
          '<data android:scheme="myapp" />',
    );
    final edit = AndroidManifestEditor.apply(manual, _config);
    expect(edit.warnings, hasLength(2));
  });

  test('keeps an existing flutter_deeplinking_enabled entry', () {
    final withFlag = _manifest.replaceFirst(
      '<intent-filter>',
      '<meta-data android:name="flutter_deeplinking_enabled" '
          'android:value="false" />\n<intent-filter>',
    );
    final edit = AndroidManifestEditor.apply(withFlag, _config);
    expect(
        'flutter_deeplinking_enabled'.allMatches(edit.content), hasLength(1));
    expect(edit.warnings.single, contains('flutter_deeplinking_enabled'));
  });

  test('keeps Windows line endings', () {
    final crlf = _manifest.replaceAll('\n', '\r\n');
    final content = AndroidManifestEditor.apply(crlf, _config).content;
    expect(RegExp(r'[^\r]\n').hasMatch(content), isFalse);
  });

  test('fails without a launcher activity', () {
    expect(
      () => AndroidManifestEditor.apply('<manifest></manifest>', _config),
      throwsStateError,
    );
  });

  group('launchModeWarning', () {
    String withMode(String attribute) => _manifest.replaceFirst(
          'android:name=".MainActivity"',
          'android:name=".MainActivity"\n            $attribute',
        );

    test('warns about singleTop and standard', () {
      final singleTop = AndroidManifestEditor.launchModeWarning(
        withMode('android:launchMode="singleTop"'),
      );
      expect(singleTop!.first, 'MainActivity uses launchMode="singleTop".');
      expect(singleTop[1], startsWith('singleTop:  a link tapped'));
      expect(singleTop.last, contains('android:launchMode="singleTask"'));

      final standard = AndroidManifestEditor.launchModeWarning(
        withMode('android:launchMode="standard"'),
      );
      expect(standard![1], startsWith('standard:   a link tapped'));
    });

    test('warns when launchMode is missing', () {
      final warning = AndroidManifestEditor.launchModeWarning(_manifest);
      expect(
        warning!.first,
        'MainActivity has no launchMode, so Android uses "standard".',
      );
    });

    test('accepts modes that keep a single copy', () {
      for (final mode in ['singleTask', 'singleInstance']) {
        final manifest = withMode('android:launchMode="$mode"');
        expect(AndroidManifestEditor.launchModeWarning(manifest), isNull);
      }
    });

    test('reads the launcher activity only', () {
      final manifest = withMode('android:launchMode="singleTop"').replaceFirst(
        '<activity android:name=".Other" />',
        '<activity android:name=".Other" android:launchMode="singleTask" />',
      );
      expect(AndroidManifestEditor.launchModeWarning(manifest), isNotNull);
      expect(
        AndroidManifestEditor.launchModeWarning('<manifest></manifest>'),
        isNull,
      );
    });
  });

  group('LinkPath.androidAttribute', () {
    String? attr(String path) => LinkPath(path).androidAttribute;

    test('translates globs', () {
      expect(attr('/*'), isNull);
      expect(attr('/about'), 'android:path="/about"');
      expect(attr('/share/*'), 'android:pathPrefix="/share/"');
      expect(attr('/p/*/edit'), 'android:pathPattern="/p/.*/edit"');
      expect(attr('/v?'), 'android:pathPattern="/v."');
    });
  });
}
