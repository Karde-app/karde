import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/cards/data/card_repository.dart';
import '../../features/ids/data/id_repository.dart';
import '../../l10n/app_localizations.dart';
import '../storage/settings_repository.dart';
import '../utils/expiry.dart';
import 'expiry_notifications.dart';

/// Keeps the scheduled reminders in step with what is actually in the vault.
///
/// Wrapped around the app's main shell rather than fired from each save site.
/// There are a dozen places a card or document can change — added, edited,
/// deleted, restored from a backup, erased with the vault — and a scheduler
/// invoked from each of them is a scheduler that will one day be forgotten in the
/// thirteenth. Watching the lists catches all of it, including the changes that
/// happen while nobody is looking.
///
/// The reminder text is built here rather than in the service because it needs a
/// locale, and the service has no BuildContext. It is also why the schedule is
/// rebuilt when the app language changes: a French user should not be left with a
/// year of English reminders queued on their phone.
class ExpiryScheduleKeeper extends ConsumerStatefulWidget {
  const ExpiryScheduleKeeper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ExpiryScheduleKeeper> createState() =>
      _ExpiryScheduleKeeperState();
}

class _ExpiryScheduleKeeperState extends ConsumerState<ExpiryScheduleKeeper> {
  /// What the last schedule was built from. Rebuilding is cheap but not free —
  /// it cancels and re-registers every pending alarm — and the lists this
  /// watches rebuild for reasons that have nothing to do with expiry dates.
  String? _lastSignature;

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(expiryRemindersProvider);
    final cards = ref.watch(cardsProvider).valueOrNull;
    final ids = ref.watch(idsProvider).valueOrNull;
    final loc = AppLocalizations.of(context);

    // Not until the vault has actually loaded. Scheduling from an empty list
    // during the first frame would cancel every real reminder and then schedule
    // nothing, leaving the user with silence until the next app start.
    if (loc != null && cards != null && ids != null) {
      final things = <ExpiringThing>[
        for (final card in cards)
          if (card.expiresOn != null)
            ExpiringThing(
              expiresOn: card.expiresOn!,
              noticeDays: Expiry.cardNoticeDays,
            ),
      ];
      final documents = <ExpiringThing>[
        for (final doc in ids)
          if (doc.expiresOn != null)
            ExpiringThing(
              expiresOn: doc.expiresOn!,
              noticeDays: Expiry.documentNoticeDays,
            ),
      ];

      final signature = [
        enabled,
        loc.localeName,
        ...things.map((t) => 'c${t.expiresOn.toIso8601String()}'),
        ...documents.map((t) => 'd${t.expiresOn.toIso8601String()}'),
      ].join('|');

      if (signature != _lastSignature) {
        _lastSignature = signature;
        // Deliberately not awaited. Nothing on screen depends on it, and making
        // the first frame wait on the notification plugin would delay the vault
        // for a reminder that is months away.
        ExpiryNotifications.instance.reschedule(
          enabled: enabled,
          cards: things,
          documents: documents,
          expiringTitle: loc.notifyExpiringTitle,
          expiringBody: loc.notifyExpiringBody,
          expiredTitle: loc.notifyExpiredTitle,
          expiredBody: loc.notifyExpiredBody,
        );
      }
    }

    return widget.child;
  }
}
