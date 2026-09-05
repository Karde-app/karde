import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

import '../../../../theme/theme.dart';

/// Collects the passphrase that protects a backup file.
///
/// This passphrase is the only thing standing between the file and whoever ends
/// up holding it, and — unlike the Karde PIN — there is no failed-attempt lockout
/// behind it, because an attacker with the file can guess offline at whatever
/// rate their hardware allows. The KDF is deliberately expensive for that reason,
/// but a short passphrase still falls, so a minimum length is enforced here
/// rather than merely suggested.
///
/// There is also no recovery. Karde cannot reset a backup passphrase, because it
/// never sees it and the file carries nothing derived from anything else. The
/// dialog says so plainly when creating one.
/// How a passphrase reads on the strength meter.
///
/// A band rather than a sentence, so the reading can be translated and so the
/// dialog can pick its colour by comparing bands instead of comparing English
/// text — which it used to do, and which quietly breaks in any other language.
enum PassphraseStrength { empty, tooShort, weak, reasonable, strong }

class PassphraseDialog extends StatefulWidget {
  /// Creating a passphrase asks twice and enforces a minimum length; entering an
  /// existing one asks once and validates nothing, since the file itself is the
  /// authority on whether the passphrase is right.
  final bool isCreating;

  const PassphraseDialog({super.key, required this.isCreating});

  /// Returns the passphrase, or null if the user backed out.
  static Future<String?> show(
    BuildContext context, {
    required bool isCreating,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PassphraseDialog(isCreating: isCreating),
    );
  }

  /// Shared by the dialog and by anything that wants to describe the rule.
  ///
  /// Lowered from 12 at the user's request. 12 is genuinely awkward for
  /// something typed rarely, but the floor cannot go much below this and still
  /// mean anything: the attacker holds the file and guesses offline, so the only
  /// defences are the 600,000-round KDF and the size of the search space. Eight
  /// mixed characters is on the order of 10^11 combinations, which the KDF turns
  /// into an impractical amount of compute. Five would have been about 10^7 —
  /// hours on an ordinary desktop — so the meter below exists to push people
  /// past the floor rather than let them sit on it.
  static const int minimumLength = 8;

  /// A rough, deliberately conservative strength read for the meter.
  ///
  /// Not an entropy calculation and not presented as one: it rewards length
  /// first, because length dominates, and character variety second. Anything
  /// clever here would only invite trusting it.
  static ({double fraction, PassphraseStrength band, bool weak}) strengthOf(String value) {
    if (value.isEmpty) {
      return (fraction: 0, band: PassphraseStrength.empty, weak: true);
    }

    var classes = 0;
    if (RegExp(r'[a-z]').hasMatch(value)) classes++;
    if (RegExp(r'[A-Z]').hasMatch(value)) classes++;
    if (RegExp(r'[0-9]').hasMatch(value)) classes++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) classes++;

    // Length is worth up to 0.7, variety up to 0.3.
    final lengthScore = (value.length / 20).clamp(0.0, 1.0) * 0.7;
    final varietyScore = (classes / 4) * 0.3;
    final score = lengthScore + varietyScore;

    if (value.length < minimumLength) {
      return (fraction: score, band: PassphraseStrength.tooShort, weak: true);
    }
    if (score < 0.45) {
      return (fraction: score, band: PassphraseStrength.weak, weak: true);
    }
    if (score < 0.7) {
      return (fraction: score, band: PassphraseStrength.reasonable, weak: false);
    }
    return (fraction: score, band: PassphraseStrength.strong, weak: false);
  }

  @override
  State<PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<PassphraseDialog> {
  final _passphrase = TextEditingController();
  final _confirmation = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscured = true;

  @override
  void dispose() {
    // FIX 2-4, applied to the same class of data: the passphrase is a secret, so
    // the controllers are emptied before they are released rather than being left
    // holding it until the objects are collected.
    _passphrase.clear();
    _confirmation.clear();
    _passphrase.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _passphrase.text);
  }

  /// Shows how much protection the passphrase actually buys.
  ///
  /// The minimum length is a floor, not a target, and a floor on its own tends
  /// to become the target. This makes the difference visible at the moment the
  /// choice is being made — which is the only moment it can be changed, since
  /// the passphrase cannot be recovered or altered afterwards.
  /// The translated reading for a strength band.
  String _strengthLabel(AppLocalizations loc, PassphraseStrength band) {
    switch (band) {
      case PassphraseStrength.empty:
        return '';
      case PassphraseStrength.tooShort:
        return loc.passphraseTooShort;
      case PassphraseStrength.weak:
        return loc.passphraseWeak;
      case PassphraseStrength.reasonable:
        return loc.passphraseReasonable;
      case PassphraseStrength.strong:
        return loc.passphraseStrong;
    }
  }

  Widget _buildStrengthMeter(ThemeData theme, AppLocalizations loc) {
    final strength = PassphraseDialog.strengthOf(_passphrase.text);
    if (_passphrase.text.isEmpty) return const SizedBox.shrink();

    final label = _strengthLabel(loc, strength.band);
    final Color colour = strength.weak
        ? theme.colorScheme.error
        : (strength.band == PassphraseStrength.reasonable
            ? KardeColors.champagneGold
            : KardeColors.signalTeal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: strength.fraction,
            minHeight: 5,
            backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(colour),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          strength.weak ? loc.passphraseWeakHint(label) : label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colour,
          ),
        ),
      ],
    );
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
              widget.isCreating ? loc.passphraseChooseTitle : loc.passphraseEnterTitle,
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
      // Lets the dialog shrink and scroll when the keyboard is up. Without it
      // the fixed-height content pushed Cancel and Continue down behind the
      // hint text as soon as the field was focused.
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isCreating
                  ? loc.passphraseCreateExplainer
                  : loc.passphraseUnlockExplainer,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passphrase,
              obscureText: _obscured,
              autofocus: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: loc.passphraseFieldLabel,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility),
                  tooltip: _obscured ? loc.passphraseShow : loc.passphraseHide,
                  onPressed: () => setState(() => _obscured = !_obscured),
                ),
              ),
              validator: (value) {
                final text = value ?? '';
                if (text.isEmpty) return loc.passphraseRequired;
                if (widget.isCreating && text.length < PassphraseDialog.minimumLength) {
                  return loc.passphraseMinimumLength(PassphraseDialog.minimumLength);
                }
                return null;
              },
              onChanged: widget.isCreating ? (_) => setState(() {}) : null,
              onFieldSubmitted: (_) {
                if (!widget.isCreating) _submit();
              },
            ),
            if (widget.isCreating) ...[
              const SizedBox(height: 10),
              _buildStrengthMeter(theme, loc),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmation,
                obscureText: _obscured,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: loc.passphraseConfirmLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != _passphrase.text) return loc.passphraseMismatch;
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
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
                      loc.passphraseAdvice,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: KardeColors.champagneGold,
            foregroundColor: KardeColors.obsidian,
          ),
          onPressed: _submit,
          child: Text(widget.isCreating ? loc.continueBtn : loc.unlock),
        ),
      ],
    );
  }
}
