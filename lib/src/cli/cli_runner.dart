import 'dart:io';

import 'package:args/args.dart';

import 'cli_logger.dart';
import 'doctor_command.dart';
import 'flutter_project.dart';
import 'generate_command.dart';
import 'kit_config.dart';
import 'setup_command.dart';

/// Parses arguments, runs a command and returns the process exit code.
class CliRunner {
  /// Creates a runner that writes to [sink].
  CliRunner(StringSink sink) : logger = CliLogger(sink);

  /// Where output goes.
  final CliLogger logger;

  static const _usage = '''
Usage: dart run deep_links_kit <command> [options]

Commands:
  setup     Add App Links, Universal Links and URL schemes to android/ and ios/
  generate  Write assetlinks.json and apple-app-site-association for the website
  doctor    Check the native setup and the files served by each host
''';

  ArgParser get _parser => ArgParser()
    ..addOption('project', help: 'Path to the Flutter app.', defaultsTo: '.')
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addCommand(
      'setup',
      ArgParser()..addFlag('dry-run', help: 'Only print what would change.'),
    )
    ..addCommand(
      'generate',
      ArgParser()
        ..addOption(
          'output',
          help: 'Folder that receives .well-known/.',
          defaultsTo: 'build/deep_links_kit',
        ),
    )
    ..addCommand(
      'doctor',
      ArgParser()..addFlag('offline', help: 'Skip the website checks.'),
    );

  /// Runs [arguments] and returns the exit code (0 ok, 1 failed, 64 usage).
  Future<int> run(List<String> arguments) async {
    final ArgResults args;
    try {
      args = _parser.parse(arguments);
    } on FormatException catch (error) {
      logger.line('${error.message}\n\n$_usage');
      return 64;
    }
    final command = args.command;
    if (args.flag('help') || command == null) {
      logger.line('$_usage\n${_parser.usage}');
      return command == null && !args.flag('help') ? 64 : 0;
    }
    try {
      await _run(command, Directory(args.option('project')!));
    } on CliException catch (error) {
      logger.fail(error.message);
    } on StateError catch (error) {
      logger.fail(error.message);
    }
    _summary();
    return logger.failures > 0 ? 1 : 0;
  }

  Future<void> _run(ArgResults command, Directory root) async {
    final project = FlutterProject(root, KitConfig.load(root));
    switch (command.name) {
      case 'setup':
        SetupCommand(project, logger, dryRun: command.flag('dry-run')).run();
      case 'generate':
        final output = command.option('output')!;
        final dir = Directory(
          Directory(output).isAbsolute ? output : '${root.path}/$output',
        );
        GenerateCommand(project, logger, dir).run();
      case 'doctor':
        await DoctorCommand(
          project,
          logger,
          offline: command.flag('offline'),
        ).run();
    }
  }

  void _summary() {
    final failures = logger.failures;
    final warnings = logger.warnings;
    logger.line();
    logger.line(
      failures == 0 && warnings == 0
          ? 'Done.'
          : 'Done with $failures failure(s) and $warnings warning(s).',
    );
  }
}
