import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/file_transfer_service.dart';
import '../../../core/security/bundle_crypto_service.dart';
import '../../../core/security/encryption_service.dart';
import '../../../core/widgets/karde_confirm_dialog.dart';
import '../../../core/widgets/karde_feedback.dart';
import '../../../theme/theme.dart';
import '../../cards/data/card_repository.dart';
import '../../ids/data/id_repository.dart';
import '../data/backup_service.dart';
import '../domain/vault_backup.dart';
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
    final service = ref.read(backupServiceProvider);

    final int itemCount;
    try {
      itemCount = await service.countExportableItems();
    } catch (_) {
      if (mounted) {
        KardeFeedback.error(context, 'Could not read your vault. Please try again.');
      }
      return;
    }

    if (!mounted) return;
    if (itemCount == 0) {
      KardeFeedback.info(context, 'There is nothing in your vault to back up yet.');
      return;
    }

    // Told before they commit, not discovered half way through: every item costs
    // one authentication, because the vault key requires it for every use. An
    // attached photo adds nothing to the count — it comes out inside the item's
    // own payload.
    final proceed = await KardeConfirmDialog.show(
      context,
      title: 'Back up $itemCount item${itemCount == 1 ? '' : 's'}',
      message: 'Your phone will ask you to confirm your identity a few times '
          'while this runs.\n\n'
          'Next you will choose a passphrase and where to save the file.',
      confirmLabel: 'Continue',
      isDestructive: false,
    );
    if (!proceed || !mounted) return;

    final passphrase = await PassphraseDialog.show(context, isCreating: true);
    if (passphrase == null || !mounted) return;

    _report('Preparing backup', 0, itemCount);
    try {
      final fileName = await service.exportVault(
        passphrase: passphrase,
        onProgress: (completed, total) => _report('Unlocking your vault', completed, total),
      );
      if (!mounted) return;
      KardeFeedback.success(context, 'Backup saved as $fileName.');
    } on VaultAuthCancelled {
      // A dismissed prompt is a decision. Nothing was written.
    } on FileTransferCancelled {
      // The user backed out of choosing a location. Nothing was written.
    } on BackupVaultEmpty {
      if (mounted) {
        KardeFeedback.info(context, 'There is nothing in your vault to back up yet.');
      }
    } catch (e) {
      if (mounted) KardeFeedback.error(context, _describe(e));
    } finally {
      _done();
    }
  }

  Future<void> _restore() async {
    final service = ref.read(backupServiceProvider);

    final String envelope;
    try {
      envelope = await service.chooseBackupFile();
    } on FileTransferCancelled {
      return;
    } catch (e) {
      if (mounted) KardeFeedback.error(context, _describe(e));
      return;
    }

    if (!mounted) return;
    final passphrase = await PassphraseDialog.show(context, isCreating: false);
    if (passphrase == null || !mounted) return;

    _report('Opening backup', 0, 0);
    final ImportPlan plan;
    try {
      plan = await service.planImport(envelope: envelope, passphrase: passphrase);
    } catch (e) {
      if (mounted) KardeFeedback.error(context, _describe(e));
      _done();
      return;
    }
    _done();

    if (!mounted) return;
    if (plan.hasNothingToDo) {
      KardeFeedback.info(
        context,
        plan.duplicateCount > 0
            ? 'Everything in that backup is already in your vault.'
            : 'That backup does not contain any items.',
      );
      return;
    }

    final skipped = plan.duplicateCount > 0
        ? '\n\n${plan.duplicateCount} item${plan.duplicateCount == 1 ? ' is' : 's are'} '
            'already in your vault and will be skipped.'
        : '';

    final proceed = await KardeConfirmDialog.show(
      context,
      title: 'Restore ${plan.newItemCount} item${plan.newItemCount == 1 ? '' : 's'}',
      message: 'Your phone will ask you to confirm your identity a few times '
          'while this runs.$skipped\n\n'
          'Nothing already in your vault is removed or changed.',
      confirmLabel: 'Restore',
      isDestructive: false,
    );
    if (!proceed || !mounted) return;

    _report('Restoring', 0, plan.newItemCount);
    try {
      final restored = await service.restore(
        plan: plan,
        onProgress: (completed, total) => _report('Restoring', completed, total),
      );
      ref.invalidate(cardsProvider);
      ref.invalidate(idsProvider);
      if (!mounted) return;
      KardeFeedback.success(
        context,
        'Restored $restored item${restored == 1 ? '' : 's'} to your vault.',
      );
    } on VaultAuthCancelled {
      if (mounted) {
        KardeFeedback.info(context, 'Restore cancelled. Nothing was changed.');
      }
    } catch (e) {
      if (mounted) KardeFeedback.error(context, _describe(e));
    } finally {
      _done();
    }
  }

  /// Turns the typed failures into something a user can act on. Anything
  /// unrecognised gets a generic sentence rather than a raw exception
  /// (audit finding 4-2).
  String _describe(Object error) {
    if (error is BackupPassphraseIncorrect) {
      return 'That passphrase does not open this backup. Check it and try again.';
    }
    if (error is BackupFileUnreadable) return error.message;
    if (error is BackupContentInvalid) return error.message;
    if (error is FileTransferFailure) {
      return 'That file could not be read. Try choosing it again.';
    }
    if (error is VaultUnavailable) {
      return 'Set a screen lock on your device before backing up or restoring.';
    }
    if (error is VaultKeyInvalidated) {
      return 'Your vault key is no longer valid, so existing items cannot be read. '
          'Restoring from a backup will still work.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & restore')),
      body: AbsorbPointer(
        absorbing: _isBusy,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Explainer(
              icon: Icons.lock_outline,
              text: 'Your backup is locked with a passphrase you choose. Without '
                  'it the file is unreadable — and Karde cannot recover it for '
                  'you, so keep it somewhere safe.',
            ),
            const SizedBox(height: 12),
            _Explainer(
              icon: Icons.cloud_off_outlined,
              text: 'Nothing is uploaded. You pick where the file goes, and it can '
                  'be restored on this phone or on a new one.',
            ),
            const SizedBox(height: 28),
            _ActionCard(
              icon: Icons.ios_share,
              title: 'Create a backup',
              subtitle: 'Save a locked copy of everything in your vault, '
                  'wherever you choose.',
              actionLabel: 'Back up now',
              enabled: !_isBusy,
              onPressed: _export,
            ),
            const SizedBox(height: 16),
            _ActionCard(
              icon: Icons.settings_backup_restore,
              title: 'Restore a backup',
              subtitle: 'Add the items from a backup file to this vault. Existing '
                  'items are kept, and anything already here is skipped.',
              actionLabel: 'Choose a file',
              enabled: !_isBusy,
              onPressed: _restore,
            ),
            if (_progress != null) ...[
              const SizedBox(height: 28),
              _ProgressPanel(progress: _progress!),
            ],
            const SizedBox(height: 28),
            Text(
              'Keep the backup file somewhere you trust. It holds everything in '
              'your vault, protected only by the passphrase you chose.',
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
                ? '${progress.label} — ${progress.completed} of ${progress.total}'
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
            'Confirm your identity when your phone asks. Cancelling stops '
            'everything safely — nothing is changed.',
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
