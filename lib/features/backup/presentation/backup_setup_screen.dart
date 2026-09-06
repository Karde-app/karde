import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/backup_folder_service.dart';
import '../../../core/security/backup_identity_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../data/auto_backup_recorder.dart';
import 'widgets/passphrase_dialog.dart';

/// Setting up the copy Karde keeps for the user.
///
/// Two decisions and nothing else: a passphrase, and a folder. They are asked
/// for in that order because the passphrase is the one that matters and the one
/// people need a moment to think about, and burying it after a file picker is a
/// good way to have it typed carelessly.
///
/// Deliberately part of onboarding rather than something to find later. The
/// backup is the only thing that survives losing the phone or turning off its
/// screen lock, and a vault whose owner has not arranged one is a vault waiting
/// to be lost. Everything else in setup can be changed afterwards; this one
/// cannot be usefully added *after* the data it was meant to protect is gone.
class BackupSetupScreen extends ConsumerStatefulWidget {
  const BackupSetupScreen({super.key, required this.onDone});

  /// Called once the backup is on. Onboarding uses this to enter the app.
  final VoidCallback onDone;

  @override
  ConsumerState<BackupSetupScreen> createState() => _BackupSetupScreenState();
}

class _BackupSetupScreenState extends ConsumerState<BackupSetupScreen> {
  String? _passphrase;
  BackupFolderChoice? _folder;
  bool _working = false;
  String? _error;

  /// True once the phone has shown it cannot offer a folder picker.
  ///
  /// Setup is required, and it stays required — but a requirement nobody can
  /// satisfy is not a requirement, it is a locked door. If the picker itself is
  /// unavailable, the user is let through and told plainly what they are
  /// carrying on without. It appears only after a genuine failure, so nobody
  /// meets a skip button on the way past a working one.
  bool _pickerUnavailable = false;

  bool get _ready => _passphrase != null && _folder != null;

  Future<void> _choosePassphrase() async {
    // Strength enforced here and not for the hand-taken export. That one is a
    // deliberate act on a file the user then puts somewhere of their choosing;
    // this one is complete, always current, and sits in a folder where somebody
    // who obtains it can guess offline for as long as they like.
    final chosen = await PassphraseDialog.show(
      context,
      isCreating: true,
      requireStrong: true,
    );
    if (chosen == null || !mounted) return;
    setState(() {
      _passphrase = chosen;
      _error = null;
    });
  }

  Future<void> _chooseFolder() async {
    try {
      final chosen = await BackupFolderService().choose();
      if (!mounted) return;
      setState(() {
        _folder = chosen;
        _error = null;
      });
    } on BackupFolderNotChosen {
      // Closing the picker is not a failure and gets no message.
    } on BackupFolderUnavailable {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.backupSetupFolderFailed;
        _pickerUnavailable = true;
      });
    }
  }

  /// Lets someone past a picker that will not open.
  ///
  /// The vault is not left unprotected by this: the dashboard says so on every
  /// visit until backup is set up, and Settings can do it at any time. What it
  /// avoids is a phone on which Karde cannot be used at all.
  void _continueWithout() {
    widget.onDone();
  }

  Future<void> _finish() async {
    final passphrase = _passphrase;
    final folder = _folder;
    if (passphrase == null || folder == null) return;

    setState(() {
      _working = true;
      _error = null;
    });

    final loc = AppLocalizations.of(context)!;
    try {
      await ref
          .read(autoBackupServiceProvider)
          .configure(passphrase: passphrase, folderChoice: folder);
      if (!mounted) return;
      await _confirmItIsOn(loc, folder.label);
      if (mounted) widget.onDone();
    } on BackupSelfTestFailed {
      // The phone wrote a backup it could not read back. Nothing here is the
      // user's doing and nothing they can fix, so the message says what happened
      // rather than asking them to change something.
      if (mounted) setState(() => _error = loc.backupSelfTestFailed);
    } on BackupFolderUnavailable {
      if (mounted) setState(() => _error = loc.backupSetupFolderFailed);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /// The one dialog, shown once.
  ///
  /// After this, saving a card says "Backup updated" on the confirmation it
  /// already shows. Someone adding five cards in a sitting should not dismiss
  /// five dialogs to be told something they were told the first time.
  Future<void> _confirmItIsOn(AppLocalizations loc, String folderLabel) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: KardeColors.obsidian,
        icon: const Icon(Icons.cloud_done_outlined,
            color: KardeColors.signalTeal, size: 40),
        title: Text(
          loc.backupSetupDoneTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          loc.backupSetupDoneBody(folderLabel),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(loc.done),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: KardeColors.graphite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      loc.backupSetupTitle,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.backupSetupIntro,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildStep(
                      done: _passphrase != null,
                      title: loc.backupSetupPassphraseTitle,
                      body: loc.backupSetupPassphraseBody,
                      doneLabel: loc.backupSetupPassphraseDone,
                      action: loc.backupSetupPassphraseTitle,
                      onTap: _working ? null : _choosePassphrase,
                    ),
                    const SizedBox(height: 16),
                    _buildStep(
                      done: _folder != null,
                      title: loc.backupSetupFolderTitle,
                      body: loc.backupSetupFolderBody,
                      doneLabel: _folder?.label ?? '',
                      action: loc.backupSetupFolderAction,
                      onTap: _working ? null : _chooseFolder,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: KardeColors.ember.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: KardeColors.ember.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: KardeColors.ember, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _pickerUnavailable ? loc.backupSetupLaterNote : _error!,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _ready && !_working ? _finish : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KardeColors.champagneGold,
                    foregroundColor: KardeColors.obsidian,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _working
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: KardeColors.obsidian,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(loc.backupSetupWorking),
                          ],
                        )
                      : Text(
                          loc.backupSetupFinish,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (_pickerUnavailable) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _working ? null : _continueWithout,
                  child: Text(
                    loc.backupSetupLater,
                    style: const TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required bool done,
    required String title,
    required String body,
    required String doneLabel,
    required String action,
    required VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done
              ? KardeColors.signalTeal.withValues(alpha: 0.5)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.circle_outlined,
                color: done ? KardeColors.signalTeal : Colors.white38,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            done ? doneLabel : body,
            style: TextStyle(
              fontFamily: 'Inter',
              color: done ? KardeColors.signalTeal : Colors.white60,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: KardeColors.champagneGold.withValues(alpha: 0.55),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                action,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: KardeColors.champagneGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
