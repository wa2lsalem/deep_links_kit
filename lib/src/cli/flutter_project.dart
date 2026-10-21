import 'dart:io';

import 'kit_config.dart';
import 'xcode_project.dart';

/// Locates the native files of a Flutter app and reads its identifiers.
class FlutterProject {
  /// Wraps the app at [root].
  FlutterProject(this.root, this.config);

  /// The app's root directory (the one holding `pubspec.yaml`).
  final Directory root;

  /// The loaded configuration.
  final KitConfig config;

  /// `android/app/src/main/AndroidManifest.xml`.
  File get androidManifest => _file('android/app/src/main/AndroidManifest.xml');

  /// `ios/Runner/Info.plist`.
  File get infoPlist => _file('ios/Runner/Info.plist');

  /// `ios/Runner.xcodeproj/project.pbxproj`.
  File get xcodeProjectFile => _file('ios/Runner.xcodeproj/project.pbxproj');

  /// Whether the app has an Android / iOS folder.
  bool get hasAndroid => androidManifest.existsSync();

  /// See [hasAndroid].
  bool get hasIos => xcodeProjectFile.existsSync();

  /// The Xcode project, or `null` without an iOS folder.
  late final XcodeProject? xcodeProject =
      hasIos ? XcodeProject(xcodeProjectFile.readAsStringSync()) : null;

  /// The configured or Gradle-declared application id.
  String? get androidPackage =>
      config.androidPackage ?? _gradleApplicationIds().firstOrNull;

  /// The configured or Xcode-declared bundle id.
  String? get iosBundleId =>
      config.iosBundleId ?? xcodeProject?.bundleIds.firstOrNull;

  /// The configured or Xcode-declared Team ID.
  String? get iosTeamId =>
      config.iosTeamId ?? xcodeProject?.teamIds.firstOrNull;

  /// `TEAMID.bundle.id`, the id used by `apple-app-site-association`.
  String? get iosAppId {
    final team = iosTeamId;
    final bundle = iosBundleId;
    return team == null || bundle == null ? null : '$team.$bundle';
  }

  /// Entitlements files of the Runner target, relative to `ios/`.
  Set<String> get entitlementsPaths =>
      xcodeProject?.entitlementsPaths ?? const {};

  /// Resolves a path relative to `ios/`.
  File iosFile(String relative) => _file('ios/$relative');

  List<String> _gradleApplicationIds() {
    for (final name in ['build.gradle.kts', 'build.gradle']) {
      final gradle = _file('android/app/$name');
      if (!gradle.existsSync()) continue;
      final pattern = RegExp(r'''applicationId\s*=?\s*["']([^"']+)["']''');
      return [
        for (final m in pattern.allMatches(gradle.readAsStringSync()))
          m.group(1)!,
      ];
    }
    return const [];
  }

  File _file(String relative) => File('${root.path}/$relative');
}
