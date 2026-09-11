import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// What Karde shows in place of Flutter's own error widget.
///
/// Flutter's default is a red screen covered in stack traces during
/// development, and in a release build a bare grey box with nothing on it.
/// Neither belongs in front of somebody who keeps their passport in this app:
/// the red one looks like the app has been broken into, and the grey one says
/// nothing at all.
///
/// This replaces both. It is deliberately plain, says the part that matters —
/// that nothing saved has been touched — and it never shows the underlying
/// error, which would be meaningless to the reader and is already on the
/// developer log.
///
/// It is built to survive being rendered in a broken tree, so it depends on as
/// little as possible: no theme lookup, no provider, and localisation only if
/// it happens to be available. A widget that throws while reporting a throw
/// would loop.
class QuietErrorPanel extends StatelessWidget {
  const QuietErrorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // Localisations may be missing entirely — this can render above or outside
    // the MaterialApp that provides them. Falling back to no text is better
    // than crashing, and far better than a red screen.
    final loc = AppLocalizations.of(context);

    return Container(
      // Karde's own dark ground, hardcoded rather than read from the theme,
      // because the theme is one of the things that might have failed.
      color: const Color(0xFF14130F),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 40,
            color: Color(0xFFC9A961),
          ),
          if (loc != null) ...[
            const SizedBox(height: 16),
            Text(
              loc.startupFailedTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF4F1EA),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.startupFailedBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFB5AEA1),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
