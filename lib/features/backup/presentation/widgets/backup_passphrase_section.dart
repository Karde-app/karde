import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/security/bundle_crypto_service.dart';
import '../../../../core/security/encryption_service.dart';
import '../../../../core/widgets/karde_confirm_dialog.dart';
import '../../../../core/widgets/karde_feedback.dart';
import '../../../../theme/theme.dart';
import '../../data/auto_backup_recorder.dart';
import 'passphrase_dialog.dart';

/// Looking up and changing the passphrase that opens the automatic backup.
///
/// Both of these exist because of the same complaint: the passphrase is asked
/// for once, at setup, and then never again until the day it is needed — on a
/// phone that has been lost, which is the one day nobody can be reminded of it.
/// Somebody who is not sure they remember it correctly had no way to find out,
/// and no way to move to one they would remember.
///
/// What is stored, and what is not. Karde keeps a copy of the passphrase on this
/// phone, sealed by the same key that seals the cards, so reading it back raises
/// the phone's own fingerprint or screen-lock prompt. It is a reminder and
/// nothing else: it dies with the phone, and it dies if the screen lock is
/// removed. That is not a flaw to design around — a copy that survived the loss
/// of the phone would be a copy that travelled with the backup file, which is
/// the one place it must never be. So the reveal says plainly that this is why
/// the passphrase still has to be written down somewhere else.
class BackupPassphraseSection extends ConsumerStatefulWidget {
  const BackupPassphraseSection({super.key});

  @override
  ConsumerState<BackupPassphraseSection> createState() =>
      _BackupPassphraseSectionState();
}

class _BackupPassphraseSectionState
    extends ConsumerState<BackupPassphraseSection> {
  bool _busy = false;

  /// Reads the stored copy back and shows it.
  ///
  /// The prompt the user answers here is raised by the Keystore itself, not by
  /// Karde asking politely — the key that sealed the reminder cannot be used
  /// without it. So there is no version of this screen that shows the passphrase
  /// to somebody who cannot unlock the phone.
  Future<void> _reveal() async {
    final loc = AppLocalizations.of(context)!;
    final service = ref.read(autoBackupServiceProvider);

    setState(() => _busy = true);
    String? passphrase;
    try {
      passphrase = await service.revealPassphrase();
    } on VaultAuthCancelled {
      return; // A dismissed prompt is an answer.
    } catch (e) {
      if (mounted) KardeFeedback.error(context, _describe(loc, e));
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (!mounted) return;
    if (passphrase == null) {
      // The stored copy went away between the row being drawn and being tapped,
      // which in practice means the screen lock changed and the key with it.
      ref.invalidate(backupPassphraseSavedProvider);
      KardeFeedback.info(context, loc.passphraseNotOnThisPhone);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => _RevealedPassphraseDialog(passphrase: passphrase!),
    );
  }

  /// Stores the passphrase for the first time, or again after it was lost.
  ///
  /// Asks for it rather than assuming, and checks the answer against the sealed
  /// key before keeping it. Saving an unchecked string would be worse than
  /// saving nothing: it would show somebody a confident-looking passphrase that
  /// does not open their backup.
  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    final service = ref.read(autoBackupServiceProvider);

    final entered = await PassphraseDialog.show(context, isCreating: false);
    if (entered == null || !mounted) return;

    setState(() => _busy = true);
    try {
      if (!await service.passphraseOpensBackup(entered)) {
        if (mounted) KardeFeedback.error(context, loc.backupWrongPassphrase);
        return;
      }
      await service.rememberPassphrase(entered);
      if (!await service.hasPassphraseReminder) {
        if (mounted) KardeFeedback.error(context, loc.passphraseCouldNotSave);
        return;
      }
      ref.invalidate(backupPassphraseSavedProvider);
      if (mounted) KardeFeedback.success(context, loc.passphraseSavedOnPhone);
    } catch (e) {
      if (mounted) KardeFeedback.error(context, _describe(loc, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Moves the backup to a new passphrase.
  ///
  /// Warned about first, because of the part nobody would guess: the dated
  /// copies sitting beside the current file keep their old wrapping, so the old
  /// passphrase is still the only thing that opens them. Rewriting those was the
  /// alternative, and it would mean overwriting backups that are currently
  /// intact in order to tidy up — the wrong trade for the one kind of file that
  /// has to survive mistakes.
  Future<void> _change() async {
    final loc = AppLocalizations.of(context)!;
    final service = ref.read(autoBackupServiceProvider);

    final proceed = await KardeConfirmDialog.show(
      context,
      title: loc.passphraseChangeTitle,
      message: loc.passphraseChangeWarning,
      confirmLabel: loc.continueBtn,
      isDestructive: false,
    );
    if (!proceed || !mounted) return;

    final current = await PassphraseDialog.show(context, isCreating: false);
    if (current == null || !mounted) return;

    // Checked before the new one is asked for, so a wrong answer costs one
    // dialog rather than three.
    setState(() => _busy = true);
    final bool opens;
    try {
      opens = await service.passphraseOpensBackup(current);
    } catch (e) {
      if (mounted) KardeFeedback.error(context, _describe(loc, e));
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (!opens) {
      KardeFeedback.error(context, loc.backupWrongPassphrase);
      return;
    }

    final replacement = await PassphraseDialog.show(
      context,
      isCreating: true,
      requireStrong: true,
    );
    if (replacement == null || !mounted) return;
    if (replacement == current) {
      KardeFeedback.info(context, loc.passphraseUnchanged);
      return;
    }

    setState(() => _busy = true);
    try {
      await service.changePassphrase(
        oldPassphrase: current,
        newPassphrase: replacement,
      );
      ref.invalidate(autoBackupSetupProvider);
      ref.invalidate(backupPassphraseSavedProvider);
      if (mounted) KardeFeedback.success(context, loc.passphraseChanged);
    } catch (e) {
      if (mounted) KardeFeedback.error(context, _describe(loc, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _describe(AppLocalizations loc, Object error) {
    if (error is BackupPassphraseIncorrect) return loc.backupWrongPassphrase;
    if (error is BackupFileUnreadable) return loc.backupProblemFileDamaged;
    if (error is VaultUnavailable) return loc.backupNeedsScreenLock;
    if (error is VaultKeyInvalidated) return loc.backupKeyInvalidated;
    return loc.genericError;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Nothing to show anyone who has not set automatic backup up: there is no
    // passphrase yet to look up or change.
    final setup = ref.watch(autoBackupSetupProvider).valueOrNull;
    if (setup == null) return const SizedBox.shrink();

    final saved = ref.watch(backupPassphraseSavedProvider).valueOrNull ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.passphraseSectionTitle,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          loc.passphraseSectionBody,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12.5, height: 1.5),
        ),
        const SizedBox(height: 14),
        _PassphraseRow(
          icon: saved ? Icons.visibility_outlined : Icons.save_outlined,
          title: saved ? loc.passphraseShowTitle : loc.passphraseSaveTitle,
          subtitle: saved ? loc.passphraseShowBody : loc.passphraseSaveBody,
          enabled: !_busy,
          onTap: saved ? _reveal : _save,
        ),
        const SizedBox(height: 10),
        _PassphraseRow(
          icon: Icons.key_outlined,
          title: loc.passphraseChangeTitle,
          subtitle: loc.passphraseChangeBody,
          enabled: !_busy,
          onTap: _change,
        ),
      ],
    );
  }
}

class _PassphraseRow extends StatelessWidget {
  const _PassphraseRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: KardeColors.champagneGold),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the passphrase, once, behind a prompt the user has already answered.
///
/// Selectable rather than merely displayed, because a passphrase read off a
/// screen and typed into a password manager is a passphrase transcribed wrongly
/// half the time. The copy button clears the clipboard after a minute, the same
/// rule a card number already follows here.
class _RevealedPassphraseDialog extends StatelessWidget {
  const _RevealedPassphraseDialog({required this.passphrase});

  final String passphrase;

  void _copy(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: passphrase));
    KardeFeedback.success(context, loc.passphraseCopied);

    Timer(const Duration(seconds: 60), () async {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current != null && current.text == passphrase) {
        Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.key_outlined, color: KardeColors.champagneGold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc.passphraseRevealTitle,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: KardeColors.champagneGold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: KardeColors.champagneGold.withValues(alpha: 0.35)),
            ),
            child: SelectableText(
              passphrase,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                  size: 16, color: theme.textTheme.bodyMedium?.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.passphraseRevealWarning,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontSize: 12, height: 1.45),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _copy(context),
          child: Text(loc.copyLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: KardeColors.champagneGold,
            foregroundColor: KardeColors.obsidian,
          ),
          onPressed: () => Navigator.pop(context),
          child: Text(loc.done),
        ),
      ],
    );
  }
}
