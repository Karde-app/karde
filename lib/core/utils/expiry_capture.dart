import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/database.dart';
import '../../features/cards/data/card_repository.dart';
import '../../features/ids/data/id_repository.dart';
import 'expiry.dart';

/// Notices an item's expiry date whenever the item is open anyway, and writes it
/// down where the bell can see it.
///
/// This replaces a whole screen's worth of machinery. Karde used to offer to
/// "read what you already saved" — a button, a count, a warning about how many
/// times the sensor would ask, and a progress bar — because expiry dates were
/// treated as secrets that had to be extracted from the vault one authentication
/// at a time.
///
/// They are not secrets. An expiry date is printed on the front of the card, and
/// on the back of a passport, and the user said so. So it is simply kept in the
/// clear from now on, and for anything saved before that was decided, this fills
/// the gap for free: every time a card is revealed or opened for editing, the
/// payload is already decrypted and the date is already in memory. Writing it to
/// the row at that moment costs nothing — no prompt, no dialog, no progress bar.
///
/// Nothing here ever asks for a prompt of its own. If an item is never opened, it
/// simply has no reminder, which is the honest outcome and not worth a chore to
/// avoid.
class ExpiryCapture {
  const ExpiryCapture._();

  /// The key a document's expiry travels under inside its payload. Matches
  /// `IdFieldType.expiryDate.name`, which is what the form writes.
  ///
  /// Kept here as a plain string so the widgets that read it do not have to
  /// import a screen to name a stored field. If the enum is ever renamed, every
  /// document already saved keeps the old key, so this constant is part of the
  /// stored format rather than an implementation detail.
  static const String documentExpiryField = 'expiryDate';

  /// Records a card's expiry if Karde does not already have it.
  ///
  /// [rawExpiry] is the `MM/YY` string as the user typed it, straight out of the
  /// decrypted payload. Silent about everything: a malformed date, a row that has
  /// since been deleted, a database that will not write. None of it is worth
  /// interrupting somebody who was only looking at their card.
  static Future<void> rememberCard(
    WidgetRef ref, {
    required int? cardId,
    required DateTime? knownExpiry,
    required String? rawExpiry,
  }) async {
    if (cardId == null || knownExpiry != null) return;
    final expiresOn = Expiry.fromCardExpiry(rawExpiry);
    if (expiresOn == null) return;

    try {
      await DatabaseHelper.instance.setCardExpiry(cardId, expiresOn);
      // Or the bell keeps its old answer until the app is next started, and the
      // reminder that was just learned goes unsaid for a day.
      ref.invalidate(cardsProvider);
    } catch (_) {
      // Nothing to say and nothing lost: the date is still in the payload, and
      // the next time this card is opened the same chance comes round again.
    }
  }

  /// As [rememberCard], for a document. [rawExpiry] is `dd/MM/yyyy`.
  static Future<void> rememberDocument(
    WidgetRef ref, {
    required int? documentId,
    required DateTime? knownExpiry,
    required String? rawExpiry,
  }) async {
    if (documentId == null || knownExpiry != null) return;
    final expiresOn = Expiry.fromDocumentExpiry(rawExpiry);
    if (expiresOn == null) return;

    try {
      await DatabaseHelper.instance.setIdExpiry(documentId, expiresOn);
      ref.invalidate(idsProvider);
    } catch (_) {
      // See rememberCard.
    }
  }
}
