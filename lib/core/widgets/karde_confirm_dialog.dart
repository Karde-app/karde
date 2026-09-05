import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// FIX 5-1: a single confirmation dialog for destructive actions.
///
/// Deleting a card, deleting an ID and wiping the vault previously each used a
/// differently-styled `AlertDialog` — two took the default system styling and one
/// hardcoded dark-theme colours, so the same destructive gesture looked like
/// three unrelated prompts. This centralises the styling and, more importantly,
/// the emphasis: the destructive action is always the visually loud one, and
/// Cancel is always the safe default.
///
/// Returns true only if the user explicitly confirmed.
///
/// A third, non-destructive action can be offered alongside the usual two — see
/// [showWithAlternative]. That exists because the most useful thing to put in
/// front of somebody about to erase their vault is a way to back it up first.
enum KardeConfirmChoice { cancelled, alternative, confirmed }

class KardeConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;

  /// Optional third action, shown above the other two and styled as the safe
  /// suggestion rather than the destructive one.
  final String? alternativeLabel;

  /// Null means "the standard Cancel", resolved against the active locale in
  /// [build]. A default argument cannot do that, because it has no context.
  final String? cancelLabel;

  /// Renders the confirm action in the error colour. Leave true for anything
  /// that destroys data.
  final bool isDestructive;

  const KardeConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel,
    this.alternativeLabel,
    this.isDestructive = true,
  });

  /// Shows the dialog and resolves to true only on explicit confirmation.
  /// A dismissal (tap outside, back gesture) resolves to false, never null.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String? cancelLabel,
    bool isDestructive = true,
  }) async {
    final result = await showDialog<KardeConfirmChoice>(
      context: context,
      builder: (_) => KardeConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result == KardeConfirmChoice.confirmed;
  }

  /// As [show], but offers a third way out.
  ///
  /// Used by "Erase vault", where telling somebody to go and make a backup first
  /// is useless if they have to remember the way there themselves — by the time
  /// they are reading the warning, the button needs to be under their thumb.
  static Future<KardeConfirmChoice> showWithAlternative(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String alternativeLabel,
    String? cancelLabel,
    bool isDestructive = true,
  }) async {
    final result = await showDialog<KardeConfirmChoice>(
      context: context,
      builder: (_) => KardeConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        alternativeLabel: alternativeLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? KardeConfirmChoice.cancelled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = isDestructive ? theme.colorScheme.error : theme.colorScheme.primary;

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Icon(
        isDestructive ? Icons.warning_amber_rounded : Icons.help_outline,
        color: accent,
        size: 32,
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          height: 1.4,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        if (alternativeLabel != null)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.pop(context, KardeConfirmChoice.alternative),
              icon: const Icon(Icons.backup_outlined, size: 18),
              label: Text(alternativeLabel!),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, KardeConfirmChoice.cancelled),
              child: Text(
                cancelLabel ?? AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, KardeConfirmChoice.confirmed),
              style: TextButton.styleFrom(foregroundColor: accent),
              child: Text(
                confirmLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
