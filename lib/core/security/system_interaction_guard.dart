/// Tracks whether Karde has deliberately handed the foreground to a system UI.
///
/// Android reports the activity as `inactive`/`paused` whether the user walked
/// away or the app itself put a system window on top. The auto-lock timer cannot
/// tell those apart on its own, so anything that raises system UI on purpose —
/// the vault's BiometricPrompt, the Storage Access Framework file picker — marks
/// itself here and the timer stands down for the duration.
///
/// This started life as a private counter inside `EncryptionService` (added when
/// a slow authentication was found to lock the app behind the very prompt the
/// user was answering). Backup needs exactly the same suppression while the
/// system file picker is up — the picker can stay open for minutes if the user
/// browses cloud storage — so the counter now lives in one place both can reach.
///
/// The window is genuinely a trade-off: auto-lock does not run while a system
/// window is up. It is a narrow one, because in every such case the app's own
/// content is covered by that window rather than exposed.
class SystemInteractionGuard {
  SystemInteractionGuard._();

  static int _depth = 0;

  /// True while at least one deliberate system interaction is on screen.
  static bool get isActive => _depth > 0;

  /// Runs [action] with the auto-lock timer suppressed.
  ///
  /// Counted rather than boolean so nested or overlapping operations cannot
  /// have the inner one clear the flag while the outer is still on screen.
  static Future<T> run<T>(Future<T> Function() action) async {
    _depth++;
    try {
      return await action();
    } finally {
      if (_depth > 0) _depth--;
    }
  }
}
