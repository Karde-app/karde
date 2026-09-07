import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../core/platform/file_transfer_service.dart';
import '../../../core/security/bundle_crypto_service.dart';
import '../../../core/security/encryption_service.dart';
import '../../../core/widgets/karde_confirm_dialog.dart';
import '../../../core/widgets/karde_feedback.dart';
import '../../../theme/theme.dart';
import '../../cards/data/card_repository.dart';
import '../../ids/data/id_repository.dart';
import '../data/auto_backup_recorder.dart';
import '../data/backup_service.dart';
import '../domain/vault_backup.dart';
import 'widgets/backup_passphrase_section.dart';
import 'widgets/passphrase_dialog.dart';

/// Encrypted export and restore of the whole vault.
///
/// The vault otherwise exists only in app-private storage with `allowBackup`
/// disabled, so before this screen existed a lost or replaced phone meant the
/// permanent loss of everything in it, with no path to a new device.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  /// Non-null while an export or restore is running. Both operations raise a
  /// series of system prompts, so the screen has to say where it has got to
  /// rather than showing an unqualified spinner.
  _Progress? _progress;

  bool get _isBusy => _progress != null;

  void _report(String label, int completed, int total) {
    if (!mounted) return;
    setState(() => _progress = _Progress(label, completed, total));
  }

  void _done() {
    if (!mounted) return;
    setState(() => _progress = null);
  }

  Future<void> _export() async {
    // Captured before the first await: this is plain data, so holding it avoids
    // reaching back into `context` after every asynchronous gap.
    final loc = AppLocalizations.of(context)!;
    final service = ref.read(backupServiceProvider);

    final int itemCount;
    try {
      itemCount = await service.countExportableItems();
    } catch (_) {
      if (mounted) {
        KardeFeedback.error(context, loc.backupCouldNotReadVault);
      }
      return;
    }

    if (!mounted) return;
    if (itemCount == 0) {
      KardeFeedback.info(context, loc.backupVaultEmpty);
      return;
    }

    // Told before they commit, not discovered half way through: every item costs
    // one authentication, because the vault key requires it for every use. An
    // attached photo adds nothing to the count — it comes out inside the item's
    // own payload.
    final proceed = await KardeConfirmDialog.show(
      context,
      title: loc.backupConfirmTitle(itemCount),
      message: loc.backupConfirmMessage,
      confirmLabel: loc.continueBtn,
      isDestructive: false,
    );
    if (!proceed || !mounted) return;

    final passphrase = await _passphraseForExport(loc);
    if (passphrase == null || !mounted) return;

    _report(loc.backupPreparing, 0, itemCount);
    try {
      final fileName = await service.exportVault(
        passphrase: passphrase,
        onProgress: (completed, total) => _report(loc.backupUnlockingVault, completed, total),
      );
      await ref.read(lastBackupProvider.notifier).recordBackup();
      if (!mounted) return;
      KardeFeedback.success(context, loc.backupSavedAs(fileName));
    } on VaultAuthCancelled {
      // A dismissed prompt is a decision. Nothing was written.
    } on FileTransferCancelled {
      // The user backed out of choosing a location. Nothing was written.
    } on BackupVaultEmpty {
      if (mounted) {
        KardeFeedback.info(context, loc.backupVaultEmpty);
      }
    } catch (e) {
      if (mounted) KardeFeedback.error(context, _describe(loc, e));
    } finally {
      _done();
    }
  }

  /// Which passphrase locks the file this export is about to write.
  ///
  /// Offers the one the automatic backup already uses, when Karde is holding a
  /// copy of it. Two passphrases for two kinds of backup was the honest design
  /// and the wrong one: they protect the same vault, they are typed months
  /// apart, and the second one exists only because this screen had no way to
  /// reach the first. Somebody who has to remember two is more likely to end up
  /// remembering neither.
  ///
  /// Still an offer rather than a rule. A file being handed to somebody else, or
  /// put somewhere the automatic backup is not, is a fair reason to want a
  /// different passphrase on it — so the other answer is one tap away, and
  /// backing out of the question cancels rather than quietly choosing.
  Future<String?> _passphraseForExport(AppLocalizations loc) async {
    final auto = ref.read(autoBackupServiceProvider);
    if (await auto.hasPassphraseReminder && mounted) {
      // Reusing the saved passphrase is in the *alternative* slot rather than
      // the confirm slot, which reads backwards in code and correctly on screen:
      // that slot is the full-width emphasised button, and this is the answer
      // being recommended. Typing a fresh one is the quieter choice beside
      // Cancel.
      final choice = await KardeConfirmDialog.showWithAlternative(
        context,
        title: loc.passphraseReuseTitle,
        message: loc.passphraseReuseMessage,
        confirmLabel: loc.passphraseReuseAlternative,
        alternativeLabel: loc.passphraseReuseConfirm,
        isDestructive: false,
      );
      if (choice == KardeConfirmChoice.cancelled) return null;
      if (choice == KardeConfirmChoice.alternative) {
        try {
          final stored = await auto.revealPassphrase();
          if (stored != null) return stored;
        } on VaultAuthCancelled {
          return null;
        } catch (e) {
          if (mounted) KardeFeedback.error(context, _describe(loc, e));
          return null;
        }
      }
    }

    if (!mounted) return null;
    return PassphraseDialog.show(context, isCreating: true);
  }

  /// Puts items saved before backup was switched on into the backup.
  ///
  /// Offered rather than done quietly, because it costs one authentication
  /// prompt per item and nobody can answer a prompt they are not standing in
  /// front of. The count is told first, the same way the manual export tells it,
  /// so the number of times the sensor will ask is never a surprise.
  Future<void> _copyExisting(int missing) async {
    final loc = AppLocalizations.of(context)!;
    final service = ref.read(backupServiceProvider);

    final proceed = await KardeConfirmDialog.show(
      context,
      title: loc.backupCopyConfirmTitle(missing),
      message: loc.backupCopyConfirmMessage,
      confirmLabel: loc.continueBtn,
      isDestructive: false,
    );
    if (!proceed || !mounted) return;

    _report(loc.backupCopying, 0, missing);
    try {
      final copied = await service.copyExistingItemsIntoBackup(
        onProgress: (completed, total) =>
            _report(loc.backupCopying, completed, total),
      );
      ref.invalidate(autoBackupMissingCountProvider);
      if (mounted) KardeFeedback.success(context, loc.backupCopyDone(copied));
    } on VaultAuthCancelled {
      // A dismissed prompt is a decision. Whatever was sealed before it is
      // still queued, so a second attempt costs only what is left.
      ref.invalidate(autoBackupMissingCountProvider);
    } catch (e) {
      ref.invalidate(autoBackupMissingCountProvider);
      if (mounted) KardeFeedback.error(context, _describe(loc, e));
    } finally {
      _done();
    }
  }

  Future<void> _restore() async {
    final loc = AppLocalizations.of(context)!;
    final service = ref.read(backupServiceProvider);

    final String envelope;
    try {
      envelope = await service.chooseBackupFile();
    } on FileTransferCancelled {
      return;
    } catch (e) {
      if (mounted) KardeFeedback.error(context, _describe(loc, e));
      return;
    }

    if (!mounted) return;
    final passphrase = await PassphraseDialog.show(context, isCreating: false);
    if (passphrase == null || !mounted) return;

    _report(loc.backupOpening, 0, 0);
    final ImportPlan plan;
    try {
      plan = await service.planImport(envelope: envelope, passphrase: passphrase);
    } catch (e) {
      if (mounted) KardeFeedback.error(context, _describe(loc, e));
      _done();
      return;
    }
    _done();

    if (!mounted) return;
    if (plan.hasNothingToDo) {
      KardeFeedback.info(
        context,
        plan.duplicateCount > 0
            ? loc.backupAllDuplicates
            : loc.backupNoItems,
      );
      return;
    }

    final skipped = plan.duplicateCount > 0
        ? '\n\n${loc.backupSkippedNote(plan.duplicateCount)}'
        : '';

    final proceed = await KardeConfirmDialog.show(
      context,
      title: loc.backupRestoreConfirmTitle(plan.newItemCount),
      message: loc.backupRestoreConfirmMessage(skipped),
      confirmLabel: loc.backupRestoreConfirmAction,
      isDestructive: false,
    );
    if (!proceed || !mounted) return;

    _report(loc.backupRestoring, 0, plan.newItemCount);
    try {
      final restored = await service.restore(
        plan: plan,
        onProgress: (completed, total) => _report(loc.backupRestoring, completed, total),
      );
      ref.invalidate(cardsProvider);
      ref.invalidate(idsProvider);
      if (!mounted) return;
      KardeFeedback.success(
        context,
        loc.backupRestoredCount(restored),
      );
    } on VaultAuthCancelled {
      if (mounted) {
        KardeFeedback.info(context, loc.backupRestoreCancelled);
      }
    } catch (e) {
      if (mounted) KardeFeedback.error(context, _describe(loc, e));
    } finally {
      _done();
    }
  }

  /// Turns the typed failures into something a user can act on. Anything
  /// unrecognised gets a generic sentence rather than a raw exception
  /// (audit finding 4-2).
  String _describe(AppLocalizations loc, Object error) {
    if (error is BackupPassphraseIncorrect) return loc.backupWrongPassphrase;
    if (error is BackupFileUnreadable) return loc.backupProblemFileDamaged;
    if (error is BackupContentInvalid) return _describeContent(loc, error);
    if (error is FileTransferFailure) return loc.backupFileChooseAgain;
    if (error is VaultUnavailable) return loc.backupNeedsScreenLock;
    if (error is VaultKeyInvalidated) return loc.backupKeyInvalidated;
    return loc.genericError;
  }

  /// Puts a sentence to a [BackupContentProblem]. The domain layer reports the
  /// code; the wording only exists here, where there is a locale to pick it in.
  String _describeContent(AppLocalizations loc, BackupContentInvalid error) {
    switch (error.problem) {
      case BackupContentProblem.damaged:
        return loc.backupProblemDamaged;
      case BackupContentProblem.notAKardeBackup:
        return loc.backupProblemNotKardeBackup;
      case BackupContentProblem.newerVersion:
        return loc.backupProblemNewerVersion;
      case BackupContentProblem.photoDamaged:
        return loc.backupProblemPhotoDamaged;
      case BackupContentProblem.recordUnreadable:
        return loc.backupProblemRecordUnreadable;
      case BackupContentProblem.missingValue:
        return loc.backupProblemMissingValue(error.key ?? '');
      case BackupContentProblem.unreadableValue:
        return loc.backupProblemUnreadableValue(error.key ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final missing = ref.watch(autoBackupMissingCountProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(loc.backupTitle)),
      body: AbsorbPointer(
        absorbing: _isBusy,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Explainer(
              icon: Icons.lock_outline,
              text: loc.backupExplainerPassphrase,
            ),
            const SizedBox(height: 12),
            _Explainer(
              icon: Icons.cloud_off_outlined,
              text: loc.backupExplainerOffline,
            ),
            const SizedBox(height: 28),
            // Above the two ordinary actions, because an incomplete backup is
            // the one thing on this screen that is actually wrong. Absent
            // entirely when nothing is missing, which is the normal case.
            if (missing > 0) ...[
              _ActionCard(
                icon: Icons.playlist_add_check_outlined,
                title: loc.backupCopyExistingTitle,
                subtitle: loc.backupCopyExistingSubtitle(missing),
                actionLabel: loc.backupCopyExistingAction,
                enabled: !_isBusy,
                onPressed: () => _copyExisting(missing),
              ),
              const SizedBox(height: 16),
            ],
            _ActionCard(
              icon: Icons.ios_share,
              title: loc.backupCreateTitle,
              subtitle: loc.backupCreateSubtitle,
              actionLabel: loc.backupCreateAction,
              enabled: !_isBusy,
              onPressed: _export,
            ),
            const SizedBox(height: 16),
            _ActionCard(
              icon: Icons.settings_backup_restore,
              title: loc.backupRestoreCardTitle,
              subtitle: loc.backupRestoreCardSubtitle,
              actionLabel: loc.backupRestoreCardAction,
              enabled: !_isBusy,
              onPressed: _restore,
            ),
            if (_progress != null) ...[
              const SizedBox(height: 28),
              _ProgressPanel(progress: _progress!),
            ],
            const SizedBox(height: 28),
            // Only draws anything once automatic backup is set up, so this
            // screen stays two cards and an explanation for everyone else.
            const BackupPassphraseSection(),
            const SizedBox(height: 28),
            Text(
              loc.backupKeepFileSafe,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12.5, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _Progress {
  final String label;
  final int completed;
  final int total;

  const _Progress(this.label, this.completed, this.total);

  /// Null while the total is unknown, which drives an indeterminate bar.
  double? get fraction => total > 0 ? completed / total : null;
}

class _ProgressPanel extends StatelessWidget {
  final _Progress progress;

  const _ProgressPanel({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final counted = progress.total > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KardeColors.champagneGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            counted
                ? loc.backupProgressCount(progress.label, progress.completed, progress.total)
                : progress.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 6,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(KardeColors.champagneGold),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            loc.backupConfirmIdentityHint,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Explainer extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Explainer({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: KardeColors.champagneGold),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: KardeColors.champagneGold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: KardeColors.champagneGold,
                foregroundColor: KardeColors.obsidian,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: enabled ? onPressed : null,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
