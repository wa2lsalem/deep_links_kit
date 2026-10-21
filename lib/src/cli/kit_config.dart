import 'dart:io';

import 'package:yaml/yaml.dart';

/// Thrown when the configuration or the project cannot be used.
class CliException implements Exception {
  /// Creates an exception with a user-facing [message].
  const CliException(this.message);

  /// What went wrong and, ideally, how to fix it.
  final String message;

  @override
  String toString() => message;
}

/// The `deep_links_kit` section of `pubspec.yaml` or `deep_links_kit.yaml`.
class KitConfig {
  /// Creates a configuration.
  const KitConfig({
    this.hosts = const [],
    this.schemes = const [],
    this.paths = const ['/*'],
    this.disableFlutterDeepLinking = true,
    this.androidPackage,
    this.sha256 = const [],
    this.iosTeamId,
    this.iosBundleId,
  });

  /// Web hosts for App Links / Universal Links, e.g. `app.example.com`.
  final List<String> hosts;

  /// Custom URL schemes, e.g. `myapp`.
  final List<String> schemes;

  /// Paths handled on [hosts]; `*` is a wildcard. Defaults to everything.
  final List<String> paths;

  /// Whether to turn off Flutter's built-in deep linking, which would
  /// otherwise hand the same link to the router a second time.
  final bool disableFlutterDeepLinking;

  /// Overrides the Android application id read from Gradle.
  final String? androidPackage;

  /// SHA-256 certificate fingerprints for `assetlinks.json`.
  final List<String> sha256;

  /// Overrides the Apple Team ID read from the Xcode project.
  final String? iosTeamId;

  /// Overrides the iOS bundle id read from the Xcode project.
  final String? iosBundleId;

  static const _section = 'deep_links_kit';

  /// Reads the configuration from [projectDir].
  static KitConfig load(Directory projectDir) {
    final standalone = File('${projectDir.path}/deep_links_kit.yaml');
    if (standalone.existsSync()) {
      final yaml = loadYaml(standalone.readAsStringSync());
      final map = yaml is YamlMap ? yaml : null;
      return fromYaml(map?[_section] is YamlMap ? map![_section] : map);
    }
    final pubspec = File('${projectDir.path}/pubspec.yaml');
    if (!pubspec.existsSync()) {
      throw CliException('No pubspec.yaml found in ${projectDir.path}');
    }
    final yaml = loadYaml(pubspec.readAsStringSync());
    final section = yaml is YamlMap ? yaml[_section] : null;
    if (section == null) {
      throw const CliException(
        'Add a `$_section:` section to pubspec.yaml '
        '(or create deep_links_kit.yaml). See the README.',
      );
    }
    return fromYaml(section);
  }

  /// Parses and validates a YAML map.
  static KitConfig fromYaml(Object? yaml) {
    if (yaml is! Map) throw const CliException('`$_section` must be a map');
    final android = _map(yaml, 'android');
    final ios = _map(yaml, 'ios');
    final config = KitConfig(
      hosts: _list(yaml, 'hosts', single: 'host'),
      schemes: _list(yaml, 'schemes', single: 'scheme'),
      paths: _list(yaml, 'paths').ifEmpty(const ['/*']),
      disableFlutterDeepLinking:
          yaml['disable_flutter_deep_linking'] as bool? ?? true,
      androidPackage: android['package']?.toString(),
      sha256: _list(android, 'sha256'),
      iosTeamId: ios['team_id']?.toString(),
      iosBundleId: ios['bundle_id']?.toString(),
    );
    config._validate();
    return config;
  }

  void _validate() {
    if (hosts.isEmpty && schemes.isEmpty) {
      throw const CliException('Configure at least one `hosts` or `schemes`');
    }
    for (final host in hosts) {
      if (host.contains('://') || host.contains('/')) {
        throw CliException(
            'Host "$host" must be a bare domain, no scheme/path');
      }
    }
    for (final scheme in schemes) {
      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*$').hasMatch(scheme)) {
        throw CliException('Scheme "$scheme" is not a valid URL scheme');
      }
    }
    for (final path in paths) {
      if (!path.startsWith('/')) {
        throw CliException('Path "$path" must start with "/"');
      }
    }
  }

  static Map<Object?, Object?> _map(Map<Object?, Object?> yaml, String key) {
    final value = yaml[key];
    if (value == null) return const {};
    if (value is Map) return value;
    throw CliException('`$key` must be a map');
  }

  static List<String> _list(
    Map<Object?, Object?> yaml,
    String key, {
    String? single,
  }) {
    final value = yaml[key] ?? (single == null ? null : yaml[single]);
    if (value == null) return const [];
    if (value is List) return [for (final v in value) v.toString().trim()];
    return [value.toString().trim()];
  }
}

extension on List<String> {
  List<String> ifEmpty(List<String> fallback) => isEmpty ? fallback : this;
}
