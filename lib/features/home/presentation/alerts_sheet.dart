import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/security/device_security_service.dart';
import '../../../core/security/encryption_service.dart';
import '../../../core/security/vault_health_provider.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../core/utils/expiry.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../backup/data/auto_backup_recorder.dart';
import '../../backup/data/backup_service.dart';
import '../../backup/presentation/backup_screen.dart';
import '../../backup/presentation/backup_setup_screen.dart';
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

/// The bell's badge count.
final kardeAlertCountProvider = Provider<int>((ref) {
  return ref.watch(kardeAlertsProvider).length;
});

/// The list behind the bell.
///
/// A sheet rather than a screen: these are things to glance at and act on, and
/// making them a destination would imply there is something to browse.
class AlertsSheet extends ConsumerWidget {
  const AlertsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AlertsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final alerts = ref.watch(kardeAlertsProvider);

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              // The bell is on screen even when it has nothing to say, so this
              // sheet is now opened most often by somebody checking that all is
              // well. "Needs your attention" over a green tick would answer the
              // wrong question.
              alerts.isEmpty ? loc.alertsTitleCalm : loc.alertsTitle,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (alerts.isEmpty)
              _buildNothing(context, loc, theme)
            else
              ...alerts.map((alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAlert(context, ref, loc, theme, alert),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildNothing(
      BuildContext context, AppLocalizations loc, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline,
              size: 40, color: KardeColors.signalTeal.withValues(alpha: 0.8)),
          const SizedBox(height: 12),
          Text(
            loc.alertsNone,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.alertsNoneBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAlert(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations loc,
    ThemeData theme,
    KardeAlert alert,
  ) {
    final urgent = alert.severity == KardeAlertSeverity.urgent;
    final accent = urgent ? KardeColors.ember : KardeColors.champagneGold;
    final (title, body, actionLabel, action) = _contentFor(context, ref, loc, alert);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(urgent ? Icons.warning_amber_rounded : Icons.info_outline,
                  color: accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontSize: 13, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  action();
                },
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The words and the button for one alert.
  ///
  /// Kept out of [kardeAlertsProvider] because that provider has no
  /// BuildContext and therefore no locale. Deciding *what* is wrong and deciding
  /// how to say it are separate jobs, and only the second one needs translating.
  (String, String, String, VoidCallback?) _contentFor(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations loc,
    KardeAlert alert,
  ) {
    switch (alert.id) {
      case 'no-screen-lock':
        return (
          loc.noScreenLockTitle,
          loc.settingsNoScreenLockWarning,
          loc.openPhoneSettings,
          () => EncryptionService().openSecuritySettings(),
        );
      case 'backup-failing':
        // Try again, rather than opening setup. Backup is already set up — that
        // is why this alert exists — and sending someone to the setup screen
        // invites them to configure it a second time over the top of a folder
        // that already holds their backup. The commonest cause here is no
        // signal, which needs nothing configured and only another attempt.
        return (
          loc.backupFailedTitle,
          loc.backupNotSavingShort,
          loc.alertsFix,
          () => ref.read(autoBackupRecorderProvider).retryQuietly(),
        );
      case 'backup-not-set-up':
        return (
          loc.setUpBackupTitle,
          loc.setUpBackupBody,
          loc.alertsSetUp,
          () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupSetupScreen()),
              ),
        );
      case 'backup-incomplete':
        // Sends them to the Backup screen rather than acting from here. The
        // copying costs one authentication prompt per item, so it needs a
        // progress bar and somewhere to report a dismissed prompt — neither of
        // which a sheet that closes on the first tap can offer.
        final missing =
            ref.watch(autoBackupMissingCountProvider).valueOrNull ?? 0;
        return (
          loc.backupIncompleteTitle,
          loc.backupIncompleteBody(missing),
          loc.alertsFix,
          () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupScreen()),
              ),
        );
      case 'biometrics-changed':
        return (
          loc.biometricChangeTitle,
          loc.biometricChangeMessage,
          loc.alertsGotIt,
          () => ref.read(biometricChangeNoticeProvider.notifier).acknowledge(),
        );
      default:
        if (alert.id.startsWith('expiry:')) {
          return _expiryContent(ref, loc, alert);
        }
        return (alert.title, alert.body, '', null);
    }
  }

  /// What an expiry alert says.
  ///
  /// No button. Renewing a card or a passport happens with a bank or a
  /// government, not in this app, so an action here could only ever open the
  /// item the user is already being told about. Telling them is the whole job.
  ///
  /// The date is stated rather than counted down — "expires in March 2027", not
  /// "expires in three weeks". A countdown has to be recomputed to stay true and
  /// reads as pressure; the month is the thing a person actually needs in order
  /// to go and do something about it.
  (String, String, String, VoidCallback?) _expiryContent(
    WidgetRef ref,
    AppLocalizations loc,
    KardeAlert alert,
  ) {
    final item = ref
        .watch(expiringItemsProvider)
        .where((candidate) => candidate.alertId == alert.id)
        .firstOrNull;
    // Gone between the list being built and this being drawn — deleted, or the
    // reminders switched off in another tab. Nothing useful to say about it.
    if (item == null) return (alert.title, '', '', null);

    final expired = item.status == ExpiryStatus.expired;
    final String when;
    if (item.isCard) {
      // A card is spoken of by its month, because that is what is printed on it
      // and what the user typed. Saying "31 March" would be technically true and
      // would not match anything they have ever seen.
      when = DateFormat.yMMMM(loc.localeName).format(item.expiresOn);
    } else {
      when = DateFormat.yMMMd(loc.localeName).format(item.expiresOn);
    }

    final body = item.isCard
        ? (expired ? loc.expiryCardPast(when) : loc.expiryCardSoon(when))
        : (expired ? loc.expiryDocumentPast(when) : loc.expiryDocumentSoon(when));

    return (item.nickname, body, '', null);
  }
}
