import 'dart:io';

import 'package:deep_links_kit/src/cli/cli_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('dlk_runner_'));
  tearDown(() => root.deleteSync(recursive: true));

  Future<(int, String)> run(List<String> args) async {
    final out = StringBuffer();
    final code = await CliRunner(out).run([...args, '--project', root.path]);
    return (code, out.toString());
  }

  test('exits with 64 on usage errors', () async {
    expect((await run([])).$1, 64);
    expect((await run(['nope'])).$1, 64);
  });

  test('reports broken YAML as a failure instead of crashing', () async {
    File('${root.path}/pubspec.yaml').writeAsStringSync('name: [unclosed\n');
    final (code, output) = await run(['doctor', '--offline']);
    expect(code, 1);
    expect(output, contains('[FAIL]'));
  });

  test('reports a missing config section', () async {
    File('${root.path}/pubspec.yaml').writeAsStringSync('name: app\n');
    final (code, output) = await run(['setup']);
    expect(code, 1);
    expect(output, contains('deep_links_kit:'));
  });
}
