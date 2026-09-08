import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/notifications/expiry_notifications.dart';
import '../../../core/security/encryption_service.dart';
import '../../../core/security/window_security_service.dart';
import '../../../core/utils/expiry.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../core/security/vault_health_provider.dart';
import '../../backup/data/auto_backup_recorder.dart';
import '../../backup/data/backup_service.dart';
import '../../backup/presentation/backup_screen.dart';
import '../../backup/presentation/backup_setup_screen.dart';
import '../data/activity_log.dart';
import '../data/alerts_providers.dart';
import '../domain/activity_entry.dart';
import '../domain/karde_alert.dart';

/// Everything Karde has to say, and everything that has happened.
///
/// A screen rather than the bottom sheet this used to be. The sheet was fine
/// while there were three things in it; it is the wrong container for a page
/// that now has two sections, a history that scrolls, and actions that lead
/// elsewhere — a sheet that fills the screen is a screen with a worse title bar.
///
/// Two sections, deliberately kept apart:
///
/// **Needs your attention** is the part with teeth. It is what the bell counts,
/// it is what clears when this page is opened, and everything in it is a fact
/// about right now that Karde can re-check at any moment.
///
/// **Recent activity** is history, and never badges anything. The user asked for
/// the log and asked what I thought; this is the answer. A vault's history
/// genuinely earns its place — the one entry that matters is the one its owner
/// does not recognise — but folding "you added a card" into a count that means
/// "something needs looking at" would empty that count of meaning, and the day
/// it matters is the day it has to be believed.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final alerts = ref.watch(kardeAlertsProvider);
    final activity = ref.watch(activityLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.notificationsTitle),
        actions: [
          if (activity.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(activityLogProvider.notifier).clear(),
              child: Text(loc.activityClear),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _SectionHeader(
            label: alerts.isEmpty ? loc.alertsTitleCalm : loc.alertsTitle,
          ),
          if (alerts.isEmpty)
            const _AllClear()
          else
            ...alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AlertCard(alert: alert),
              ),
            ),
          const SizedBox(height: 28),
          _SectionHeader(label: loc.activityTitle),
          if (activity.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                loc.activityEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
            )
          else
            ...activity.map((entry) => _ActivityRow(entry: entry)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: KardeColors.champagneGold,
        ),
      ),
    );
  }
}

class _AllClear extends StatelessWidget {
  const _AllClear();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: KardeColors.signalTeal.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KardeColors.signalTeal.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline,
              size: 38, color: KardeColors.signalTeal.withValues(alpha: 0.85)),
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
}

class _AlertCard extends ConsumerWidget {
  const _AlertCard({required this.alert});

  final KardeAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final urgent = alert.severity == KardeAlertSeverity.urgent;
    final accent = urgent ? KardeColors.ember : KardeColors.champagneGold;
    final (title, body, actionLabel, action) = _contentFor(context, ref, loc);

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
                onPressed: action,
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

  (String, String, String, VoidCallback?) _contentFor(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations loc,
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
      case 'reminders-blocked':
        return (
          loc.remindersBlockedTitle,
          loc.settingsRemindersMayBeLate,
          loc.alertsFix,
          () async {
            // Whichever of the two is actually the problem. Asking for the
            // punctual-alarm permission first because Karde can raise that
            // itself; the battery list has to be found by hand.
            if (!await ExpiryNotifications.instance.canBeExact()) {
              await ExpiryNotifications.instance.requestExactAlarms();
            } else {
              await WindowSecurityService.openBatterySettings();
            }
            ref.invalidate(remindersCanArriveProvider);
          },
        );
      case 'biometrics-changed':
        return (
          loc.biometricChangeTitle,
          loc.biometricChangeMessage,
          loc.alertsGotIt,
          () => ref.read(biometricChangeNoticeProvider.notifier).acknowledge(),
        );
      default:
        if (alert.id.startsWith('expiry:')) return _expiryContent(ref, loc);
        return (alert.title, alert.body, '', null);
    }
  }

  /// What an expiry alert says.
  ///
  /// No button. Renewing a card or a passport happens with a bank or a
  /// government, not in this app, so an action here could only ever open the
  /// item the user is already being told about.
  ///
  /// The date is stated rather than counted down — "expires in March 2027", not
  /// "expires in three weeks". A countdown has to be recomputed to stay true and
  /// reads as pressure; the month is what a person needs in order to act.
  (String, String, String, VoidCallback?) _expiryContent(
    WidgetRef ref,
    AppLocalizations loc,
  ) {
    final item = ref
        .watch(expiringItemsProvider)
        .where((candidate) => candidate.alertId == alert.id)
        .firstOrNull;
    if (item == null) return (alert.title, '', '', null);

    final expired = item.status == ExpiryStatus.expired;
    // A card is spoken of by its month, because that is what is printed on it.
    // A document by its day, because a passport that runs out on the third of
    // March is not valid for the rest of March.
    final when = item.isCard
        ? DateFormat.yMMMM(loc.localeName).format(item.expiresOn)
        : DateFormat.yMMMd(loc.localeName).format(item.expiresOn);

    final body = item.isCard
        ? (expired ? loc.expiryCardPast(when) : loc.expiryCardSoon(when))
        : (expired ? loc.expiryDocumentPast(when) : loc.expiryDocumentSoon(when));

    return (item.nickname, body, '', null);
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final removed = entry.kind == ActivityKind.cardRemoved ||
        entry.kind == ActivityKind.documentRemoved;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _icon,
            size: 18,
            // Removals in the warning colour, everything else quiet. Not because
            // deleting is an error, but because it is the entry somebody is
            // scanning for when they scan this list at all.
            color: removed
                ? KardeColors.ember.withValues(alpha: 0.8)
                : theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _sentence(loc),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13.5,
                height: 1.35,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            DateFormat.MMMd(loc.localeName).add_jm().format(entry.at),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  IconData get _icon {
    switch (entry.kind) {
      case ActivityKind.cardAdded:
      case ActivityKind.documentAdded:
        return Icons.add_circle_outline;
      case ActivityKind.cardChanged:
      case ActivityKind.documentChanged:
        return Icons.edit_outlined;
      case ActivityKind.cardRemoved:
      case ActivityKind.documentRemoved:
        return Icons.remove_circle_outline;
    }
  }

  String _sentence(AppLocalizations loc) {
    switch (entry.kind) {
      case ActivityKind.cardAdded:
        return loc.activityCardAdded(entry.name);
      case ActivityKind.cardChanged:
        return loc.activityCardChanged(entry.name);
      case ActivityKind.cardRemoved:
        return loc.activityCardRemoved(entry.name);
      case ActivityKind.documentAdded:
        return loc.activityDocumentAdded(entry.name);
      case ActivityKind.documentChanged:
        return loc.activityDocumentChanged(entry.name);
      case ActivityKind.documentRemoved:
        return loc.activityDocumentRemoved(entry.name);
    }
  }
}
