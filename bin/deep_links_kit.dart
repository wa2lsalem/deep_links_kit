import 'dart:io';

import 'package:deep_links_kit/src/cli/cli_runner.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await CliRunner(stdout).run(arguments);
}
