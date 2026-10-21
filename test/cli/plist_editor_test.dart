import 'package:deep_links_kit/src/cli/plist_editor.dart';
import 'package:flutter_test/flutter_test.dart';

const _domains = 'com.apple.developer.associated-domains';

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
\t<key>FlutterDeepLinkingEnabled</key>
\t<true/>
</dict>
</plist>
''';

void main() {
  test('creates a string array in an empty document', () {
    final plist = PlistEditor(PlistEditor.emptyDocument);
    expect(plist.addToStringArray(_domains, ['applinks:a.com']), [
      'applinks:a.com',
    ]);
    expect(
      plist.content,
      contains(
        '<dict>\n\t<key>$_domains</key>\n\t<array>\n'
        '\t\t<string>applinks:a.com</string>\n\t</array>\n</dict>',
      ),
    );
  });

  test('adds only missing strings to an existing array', () {
    final plist = PlistEditor(PlistEditor.emptyDocument)
      ..addToStringArray(_domains, ['applinks:a.com']);
    final added = plist.addToStringArray(_domains, [
      'applinks:a.com',
      'applinks:b.com',
    ]);
    expect(added, ['applinks:b.com']);
    expect(plist.stringArray(_domains), ['applinks:a.com', 'applinks:b.com']);
  });

  test('fills an empty <array/>', () {
    final plist = PlistEditor(
      PlistEditor.emptyDocument.replaceFirst(
        '<dict>\n',
        '<dict>\n\t<key>$_domains</key>\n\t<array/>\n',
      ),
    );
    plist.addToStringArray(_domains, ['applinks:a.com']);
    expect(plist.stringArray(_domains), ['applinks:a.com']);
    expect(plist.content, isNot(contains('<array/>')));
  });

  test('sets booleans in place or appends them', () {
    final plist = PlistEditor(_info);
    expect(plist.boolValue('FlutterDeepLinkingEnabled'), isTrue);
    expect(plist.setBool('FlutterDeepLinkingEnabled', false), isTrue);
    expect(plist.boolValue('FlutterDeepLinkingEnabled'), isFalse);
    expect(plist.setBool('FlutterDeepLinkingEnabled', false), isFalse);
    expect(plist.setBool('Other', true), isTrue);
    expect(plist.content, contains('\t<key>Other</key>\n\t<true/>\n</dict>'));
  });

  test('adds a URL scheme next to existing ones', () {
    final plist = PlistEditor(_info);
    expect(plist.hasUrlScheme('fb123'), isTrue);
    expect(plist.addUrlScheme('fb123'), isFalse);
    expect(plist.addUrlScheme('myapp'), isTrue);
    expect(plist.hasUrlScheme('myapp'), isTrue);
    expect(plist.hasUrlScheme('fb123'), isTrue);
    expect(plist.content, contains('\t\t\t\t<string>myapp</string>'));
  });

  test('removes strings and drops the key once the array is empty', () {
    final plist = PlistEditor(PlistEditor.emptyDocument)
      ..addToStringArray(_domains, ['applinks:a.com', 'applinks:b.com']);
    expect(plist.removeFromStringArray(_domains, ['applinks:a.com', 'x']), [
      'applinks:a.com',
    ]);
    expect(plist.stringArray(_domains), ['applinks:b.com']);
    plist.removeFromStringArray(_domains, ['applinks:b.com']);
    expect(plist.content, PlistEditor.emptyDocument);
  });

  test('removes a scheme without touching the others', () {
    final plist = PlistEditor(_info)..addUrlScheme('myapp');
    expect(plist.removeUrlScheme('myapp'), isTrue);
    expect(plist.removeUrlScheme('myapp'), isFalse);
    expect(plist.content, _info);
  });

  test('removes only the scheme when its entry has others', () {
    final plist = PlistEditor(
      _info.replaceFirst(
        '\t\t\t\t<string>fb123</string>\n',
        '\t\t\t\t<string>fb123</string>\n\t\t\t\t<string>myapp</string>\n',
      ),
    );
    plist.removeUrlScheme('myapp');
    expect(plist.content, _info);
  });

  test('removes a key with its value', () {
    final plist = PlistEditor(_info);
    expect(plist.removeKey('FlutterDeepLinkingEnabled'), isTrue);
    expect(plist.removeKey('CFBundleURLTypes'), isTrue);
    expect(plist.removeKey('Missing'), isFalse);
    expect(plist.content, isNot(contains('FlutterDeepLinkingEnabled')));
    expect(plist.content, isNot(contains('fb123')));
    expect(plist.content, contains('<key>CFBundleName</key>'));
  });

  test('creates CFBundleURLTypes when missing', () {
    final plist = PlistEditor(PlistEditor.emptyDocument);
    expect(plist.addUrlScheme('myapp'), isTrue);
    expect(plist.hasUrlScheme('myapp'), isTrue);
    expect(plist.content, contains('\t<key>CFBundleURLTypes</key>'));
  });
}
