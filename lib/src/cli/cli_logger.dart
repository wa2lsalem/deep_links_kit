/// Plain-text output with status tags that render in every terminal.
class CliLogger {
  /// Writes to [sink].
  CliLogger(this.sink);

  /// Where lines go, usually `stdout`.
  final StringSink sink;

  /// Number of [fail] calls so far.
  int failures = 0;

  /// Number of [warn] calls so far.
  int warnings = 0;

  /// A passed check or a completed change.
  void ok(String message) => sink.writeln('  [OK]   $message');

  /// Something that works but deserves attention, with optional [details]
  /// printed under it.
  void warn(String message, {Iterable<String> details = const []}) {
    warnings++;
    sink.writeln('  [WARN] $message');
    details.forEach(info);
  }

  /// Something that will break deep links.
  void fail(String message) {
    failures++;
    sink.writeln('  [FAIL] $message');
  }

  /// Extra context.
  void info(String message) => sink.writeln('         $message');

  /// A section title.
  void section(String title) => sink.writeln('\n$title');

  /// A raw line.
  void line([String message = '']) => sink.writeln(message);
}
