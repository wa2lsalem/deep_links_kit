import 'package:deep_links_kit/deep_links_kit.dart';
import 'package:flutter_test/flutter_test.dart';

DeepLink _link(String url) => DeepLink.fromUri(Uri.parse(url));

DeepLinkRoute _route(String pattern) => DeepLinkRoute(pattern, to: (_) => '/x');

void main() {
  group('DeepLink', () {
    test('uses the path of web links', () {
      final link = _link('https://example.com/p/42/?ref=share');
      expect(link.path, '/p/42');
      expect(link.queryParameters, {'ref': 'share'});
      expect(link.isWebLink, isTrue);
    });

    test('folds the host of custom-scheme links into the path', () {
      expect(_link('myapp://p/42').path, '/p/42');
      expect(_link('myapp:///p/42').path, '/p/42');
      expect(_link('myapp://p/42').isWebLink, isFalse);
    });

    test('decodes segments', () {
      expect(_link('https://example.com/s/1/caf%C3%A9').pathSegments, [
        's',
        '1',
        'café',
      ]);
    });
  });

  group('DeepLinkRoute.match', () {
    test('captures parameters', () {
      final match = _route('/p/:id').match(_link('https://e.com/p/42'));
      expect(match?['id'], '42');
    });

    test('rejects different lengths and literals', () {
      final route = _route('/p/:id');
      expect(route.match(_link('https://e.com/p')), isNull);
      expect(route.match(_link('https://e.com/p/1/2')), isNull);
      expect(route.match(_link('https://e.com/s/1')), isNull);
    });

    test('ignores letter case of literals unless asked', () {
      final link = _link('https://e.com/Share/1');
      expect(_route('/share/:id').match(link), isNotNull);
      final strict = DeepLinkRoute(
        '/share/:id',
        to: (_) => '/x',
        caseSensitive: true,
      );
      expect(strict.match(link), isNull);
    });

    test('supports optional trailing parameters', () {
      final route = _route('/p/:id/:name?');
      expect(route.match(_link('https://e.com/p/1'))?.params, {'id': '1'});
      expect(route.match(_link('https://e.com/p/1/ali'))?.params, {
        'id': '1',
        'name': 'ali',
      });
    });

    test('captures the rest with a trailing wildcard', () {
      final route = _route('/share/*');
      expect(route.match(_link('https://e.com/share/a/b'))?.rest, ['a', 'b']);
      expect(route.match(_link('https://e.com/share'))?.rest, isEmpty);
      expect(route.match(_link('https://e.com/other')), isNull);
    });

    test('rejects captures that would change the in-app path', () {
      final route = _route('/p/:id');
      for (final id in ['..%2Fadmin', '42%3Fx=1', '42%23top', '..', '.']) {
        expect(route.match(_link('https://e.com/p/$id')), isNull, reason: id);
      }
      expect(
          _route('/docs/*').match(_link('https://e.com/docs/a%2Fb')), isNull);
      expect(route.match(_link('https://e.com/p/%D8%B9%D9%84%D9%8A'))?['id'],
          'علي');
    });

    test('matches the root path', () {
      expect(_route('/').match(_link('https://e.com/')), isNotNull);
      expect(_route('/').match(_link('https://e.com/p')), isNull);
    });

    test('rejects invalid patterns', () {
      expect(() => _route('/*/p'), throwsArgumentError);
      expect(() => _route('/:a?/:b'), throwsArgumentError);
      expect(() => _route('/:id/:id'), throwsArgumentError);
      expect(() => _route('/:'), throwsArgumentError);
    });
  });
}
