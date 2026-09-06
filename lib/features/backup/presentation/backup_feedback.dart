import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../data/auto_backup_recorder.dart';

/// Says what happened to the item, and what happened to its copy.
///
/// One sentence, not two messages. Saving a card and copying it to the backup
/// are one action to the user even though they are two to Karde, and reporting
/// them separately would mean two notifications for every card added.
///
/// Three outcomes, and the difference between them matters:
///
///  - Backup is not set up: say nothing about it. Someone who has not arranged a
///    backup does not need reminding on every save; the dashboard says it once,
///    quietly, and that is enough.
///  - It worked: "Backup updated" on the end. This is the reassurance that
///    replaces the dialog after the first one — enough to notice, not enough to
///    interrupt.
///  - It failed: say so plainly. The card is safe, which is why this is not an
///    error, but the copy is now behind the vault and only the user can fix it.
///    Being offline with a cloud folder is the ordinary way this happens.
String backupAwareMessage(
  BuildContext context,
  WidgetRef ref,
  String message,
) {
  final loc = AppLocalizations.of(context)!;
  final configured = ref.read(autoBackupConfiguredProvider).valueOrNull ?? false;
  if (!configured) return message;

  return ref.read(autoBackupFailingProvider)
      ? loc.savedButNotBackedUp(message)
      : loc.andBackedUp(message);
}
