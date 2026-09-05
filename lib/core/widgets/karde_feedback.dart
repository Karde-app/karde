import 'package:flutter/material.dart';

/// FIX 5-2: one place for user feedback messages.
///
/// Feedback was previously ad hoc: saving a card showed nothing at all, saving an
/// ID showed a plain SnackBar, deletions showed nothing, settings errors used a
/// floating SnackBar in the error colour, and card save errors used the default
/// styling. The same class of event looked different depending on which screen
/// the user happened to be on.
///
/// All three helpers share one presentation, so success and failure are
/// consistently distinguishable everywhere.
class KardeFeedback {
  KardeFeedback._();

  static void success(BuildContext context, String message) =>
      _show(context, message, _Kind.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, _Kind.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, _Kind.info);

  static void _show(BuildContext context, String message, _Kind kind) {
    if (!context.mounted) return;

    final theme = Theme.of(context);
    final (Color background, IconData icon) = switch (kind) {
      _Kind.success => (const Color(0xFF1B7F5A), Icons.check_circle_outline),
      _Kind.error => (theme.colorScheme.error, Icons.error_outline),
      _Kind.info => (theme.colorScheme.surfaceContainerHighest, Icons.info_outline),
    };

    final foreground = kind == _Kind.info
        ? theme.colorScheme.onSurface
        : Colors.white;

    ScaffoldMessenger.of(context)
      // Replace rather than queue, so a burst of events cannot leave the user
      // waiting through a backlog of stale messages.
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: background,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          content: Row(
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: foreground,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

enum _Kind { success, error, info }
