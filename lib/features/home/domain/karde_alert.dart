/// Something Karde needs to tell the user about.
///
/// These were scattered across the home screen as separate banners, each one
/// competing for the same space above the cards. A screen lock removed, a
/// backup that has stopped, fingerprints that changed — all of them true, all of
/// them worth saying, and together they pushed the actual vault off the page.
///
/// Collected here instead, behind one bell, so the home screen can stay a home
/// screen and nothing has to be dropped to make room for something else.
class KardeAlert {
  const KardeAlert({
    required this.id,
    required this.severity,
    required this.title,
    required this.body,
    this.actionLabel,
  });

  /// Stable across rebuilds, so the list does not flicker and a future "seen"
  /// state has something to hang on.
  final String id;

  final KardeAlertSeverity severity;
  final String title;
  final String body;

  /// What the button says, or null when there is nothing for Karde to do about
  /// it — some of these are for the user to act on outside the app.
  final String? actionLabel;
}

/// How much the alert matters, which decides both order and colour.
///
/// Two levels rather than five. The distinction that earns its keep is "your
/// things are at risk right now" against "worth knowing"; anything finer would
/// be a judgement the user is better placed to make than Karde is.
enum KardeAlertSeverity {
  /// Something is wrong that puts the vault or its copy at risk.
  urgent,

  /// Worth knowing, nothing is in danger.
  notice,
}
