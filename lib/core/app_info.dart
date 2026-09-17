/// FIX 9-4: single source of truth for the app version.
///
/// The version was previously typed out by hand in three places — twice in the
/// settings screen and once in `pubspec.yaml` — so a release bump silently left
/// the UI reporting the old number.
///
/// Keep [version] in step with the `version:` field in `pubspec.yaml`. Reading it
/// at runtime would need `package_info_plus`, which is a network-free plugin but
/// still a dependency; for a deliberately minimal offline app a single constant
/// is the smaller change. If the dependency is ever added, replace the constant
/// here and every call site follows.
class AppInfo {
  AppInfo._();

  static const String version = '1.0.1';
  static const String name = 'Karde';

  /// e.g. "Karde v1.0.0"
  static const String nameWithVersion = '$name v$version';
}
