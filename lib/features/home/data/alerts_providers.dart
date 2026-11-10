import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/expiry_notifications.dart';
import '../../../core/security/device_security_service.dart';
import '../../../core/security/vault_health_provider.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../core/utils/expiry.dart';
import '../../backup/data/auto_backup_recorder.dart';
import '../../backup/data/backup_service.dart';
import '../../cards/data/card_repository.dart';
import '../../ids/data/id_repository.dart';
import '../domain/karde_alert.dart';

/// One card or document that is running out, or has.
///
/// Assembled from the list summaries, which carry the expiry date in the clear
/// and nothing else new — no payload is opened and no authentication prompt is
/// spent, which is the entire reason the date is stored where it is.
class ExpiringItem {
  const ExpiringItem({
    required this.alertId,
    required this.nickname,
    required this.expiresOn,
    required this.isCard,
    required this.status,
  });

  final String alertId;
  final String nickname;
  final DateTime expiresOn;

  /// Decides both the wording and how the date is written: a card runs out at
  /// the end of a month and is spoken of that way, a passport on a given day.
  final bool isCard;

  final ExpiryStatus status;
}

/// Everything expiring or expired, the most pressing first.
///
/// Empty whenever the reminders are switched off, without looking at anything —
/// the dates are erased when the switch goes off, so there would be nothing to
/// find, but not looking makes the intent explicit rather than incidental.
final expiringItemsProvider = Provider<List<ExpiringItem>>((ref) {
  if (!ref.watch(expiryRemindersProvider)) return const [];

  final items = <ExpiringItem>[];

  for (final card in ref.watch(cardsProvider).valueOrNull ?? const []) {
    final status = Expiry.statusOf(
      card.expiresOn,
      noticeDays: Expiry.cardNoticeDays,
    );
    if (status == ExpiryStatus.fine) continue;
    items.add(ExpiringItem(
      alertId: 'expiry:card:${card.id}',
      nickname: card.nickname,
      expiresOn: card.expiresOn!,
      isCard: true,
      status: status,
    ));
  }

  for (final doc in ref.watch(idsProvider).valueOrNull ?? const []) {
    final status = Expiry.statusOf(
      doc.expiresOn,
      noticeDays: Expiry.documentNoticeDays,
    );
    if (status == ExpiryStatus.fine) continue;
    items.add(ExpiringItem(
      alertId: 'expiry:id:${doc.id}',
      nickname: doc.nickname,
      expiresOn: doc.expiresOn!,
      isCard: false,
      status: status,
    ));
  }

  // Soonest first, so the passport that ran out last year sits above the card
  // that has three weeks left.
  items.sort((a, b) => a.expiresOn.compareTo(b.expiresOn));
  return items;
});

/// Everything Karde currently wants to say, worst first.
///
/// Assembled rather than stored. Every one of these is a fact about the phone,
/// the backup or the vault's contents that Karde can look up whenever it is
/// asked, so there is nothing to keep in step and nothing to go stale — an alert
/// about a missing screen lock disappears the moment a screen lock exists,
/// without anyone having to remember to clear it.
///
/// Expiry alerts were the one thing this list could not do for a long time, and
/// the reason was not laziness: expiry dates live inside the encrypted payload,
/// which costs one authentication prompt per item to open, so checking them
/// would have meant a fingerprint for every card every time the app started.
/// They are here now because the user chose to have the date — and only the
/// date — stored where Karde can read it. See the v7 migration in
/// `database.dart`, and [expiryRemindersProvider], which undoes that choice.
final kardeAlertsProvider = Provider<List<KardeAlert>>((ref) {
  final alerts = <KardeAlert>[];

  final health = ref.watch(vaultHealthProvider).valueOrNull;
  if (health == VaultHealthStatus.atRisk) {
    alerts.add(const KardeAlert(
      id: 'no-screen-lock',
      severity: KardeAlertSeverity.urgent,
      title: '',
      body: '',
      actionLabel: '',
    ));
  }

  if (ref.watch(autoBackupFailingProvider)) {
    alerts.add(const KardeAlert(
      id: 'backup-failing',
      severity: KardeAlertSeverity.urgent,
      title: '',
      body: '',
      actionLabel: '',
    ));
  }

  // A reminder that cannot arrive is worse than no reminder, because its owner
  // has stopped watching the date themselves.
  //
  // Raised here, in the bell, and not only in Settings. Settings is the one
  // place a user has no reason to visit — and the phones that cause this are
  // the ones that freeze apps people rarely open, which is exactly the profile
  // of somebody who set their cards up once and has not been back since. The
  // notice would have sat unread in the only room nobody enters.
  //
  // A notice rather than urgent: nothing is at risk, and a date is still on the
  // card. It is the reminder about it that will not come.
  if (ref.watch(expiryRemindersProvider) &&
      ref.watch(remindersCanArriveProvider).valueOrNull == false) {
    alerts.add(const KardeAlert(
      id: 'reminders-blocked',
      severity: KardeAlertSeverity.notice,
      title: '',
      body: '',
      actionLabel: '',
    ));
  }

  // Only once there is something to lose. An empty vault has nothing to back up,
  // and a bell on a brand new install — before the user has added anything at
  // all — is the app asking for work before it has done any.
  final hasItems = (ref.watch(cardsProvider).valueOrNull?.length ?? 0) +
          (ref.watch(idsProvider).valueOrNull?.length ?? 0) >
      0;
  final configured = ref.watch(autoBackupConfiguredProvider).valueOrNull;
  if (hasItems && configured == false) {
    alerts.add(const KardeAlert(
      id: 'backup-not-set-up',
      severity: KardeAlertSeverity.notice,
      title: '',
      body: '',
      actionLabel: '',
    ));
  }

  // Urgent for the same reason "backup-failing" is: part of the vault has no
  // copy anywhere, and the owner has been told their backup is on. The provider
  // answers zero whenever it cannot be sure, so an unreachable folder never
  // raises this.
  if ((ref.watch(autoBackupMissingCountProvider).valueOrNull ?? 0) > 0) {
    alerts.add(const KardeAlert(
      id: 'backup-incomplete',
      severity: KardeAlertSeverity.urgent,
      title: '',
      body: '',
      actionLabel: '',
    ));
  }

  // One per item rather than "3 things are expiring". Which passport is the
  // whole question, and the nickname is already in the clear and already on the
  // home screen, so naming it here gives nothing away that the app does not
  // already show.
  for (final item in ref.watch(expiringItemsProvider)) {
    alerts.add(KardeAlert(
      id: item.alertId,
      severity: item.status == ExpiryStatus.expired
          ? KardeAlertSeverity.urgent
          : KardeAlertSeverity.notice,
      title: item.nickname,
      body: '',
    ));
  }

  if (ref.watch(biometricChangeNoticeProvider).valueOrNull == true) {
    alerts.add(const KardeAlert(
      id: 'biometrics-changed',
      severity: KardeAlertSeverity.notice,
      title: '',
      body: '',
      actionLabel: '',
    ));
  }

  // Worst first, which the list only claimed to be until expiry alerts arrived
  // and started slotting urgent items in behind notices. Partitioned rather than
  // sorted because Dart's sort is not stable, and the order things were added in
  // carries meaning of its own within each half.
  return [
    ...alerts.where((a) => a.severity == KardeAlertSeverity.urgent),
    ...alerts.where((a) => a.severity == KardeAlertSeverity.notice),
  ];
});

/// Which alerts the user has already looked at.
///
/// Persisted, so the badge does not come back every time Karde is opened.
///
/// What is stored is the set of ids that were on screen the last time the sheet
/// was opened — not a growing history. That is what makes a problem that goes
/// away and returns badge again: its id is dropped the moment it stops being an
/// active alert, so its return is genuinely new.
class SeenAlertsNotifier extends StateNotifier<Set<String>> {
  SeenAlertsNotifier(this._repository)
      : super(_repository.getSeenAlertIds().toSet());

  final SettingsRepository _repository;

  /// Records exactly what is on screen now as read.
  Future<void> markSeen(Iterable<String> activeIds) async {
    final ids = activeIds.toSet();
    if (ids.length == state.length && ids.containsAll(state)) return;
    state = ids;
    await _repository.setSeenAlertIds(ids.toList());
  }
}

final seenAlertsProvider =
    StateNotifierProvider<SeenAlertsNotifier, Set<String>>((ref) {
  return SeenAlertsNotifier(ref.watch(settingsRepositoryProvider));
});

/// The alerts the user has not looked at yet.
///
/// The bell badges on these rather than on everything. A count that never goes
/// down after it has been read is not a count, it is a permanent decoration.
/// Opening the bell clears it.
///
/// The alerts themselves do not disappear — the sheet still lists everything
/// that is true, because a screen lock that is still missing is still missing.
/// Only the demand for attention is answered.
final unseenAlertsProvider = Provider<List<KardeAlert>>((ref) {
  final seen = ref.watch(seenAlertsProvider);
  return ref
      .watch(kardeAlertsProvider)
      .where((alert) => !seen.contains(alert.id))
      .toList();
});

/// The bell's badge count.
final kardeAlertCountProvider = Provider<int>((ref) {
  return ref.watch(unseenAlertsProvider).length;
});
