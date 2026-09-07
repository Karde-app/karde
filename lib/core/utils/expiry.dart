/// Working out when a card or document runs out, and how close that is.
///
/// The whole feature rests on one uncomfortable fact: Karde cannot warn you
/// about an expiry it cannot read, and expiry dates live inside the encrypted
/// payload, which costs one authentication prompt per item to open. Warning
/// about them therefore means keeping the date — and nothing else — outside the
/// encryption, in the same row as the nickname and the last four digits that are
/// already in the clear.
///
/// That is a real trade and the user made it deliberately. It is confined to
/// this: the card number, the security code, the document number and the photo
/// all stay sealed. See `Settings → Expiry reminders`, which turns it off again
/// and erases every date it stored.
library;

/// How close an item is to the end of its life.
enum ExpiryStatus {
  /// Nothing to say.
  fine,

  /// Inside the warning window and still valid.
  soon,

  /// The last valid day has passed.
  expired,
}

class Expiry {
  Expiry._();

  /// How long before a card runs out that Karde starts saying so.
  ///
  /// A month. A replacement card arrives in days, and the bank usually sends it
  /// unasked, so the useful warning is "the one in your drawer is about to stop
  /// working", not a season of nagging.
  static const int cardNoticeDays = 30;

  /// The same for a document, and much longer on purpose.
  ///
  /// Three months. Renewing a passport is measured in weeks or months rather
  /// than days, and many countries refuse entry on a passport with less than six
  /// months left — so a warning that arrives thirty days out has already arrived
  /// too late to be useful.
  static const int documentNoticeDays = 90;

  /// Reads a card's `MM/YY` into the last day it is valid.
  ///
  /// A card expiring "03/27" works to the end of March 2027, which is what the
  /// date returned here means — the last day on which the thing is still good.
  /// Storing it that way lets cards and documents share one column and one
  /// comparison, instead of two nearly-identical ones that would drift apart.
  ///
  /// Null for anything it does not recognise. A card is allowed to be saved with
  /// a malformed expiry, so this has to fail quietly rather than throw: no date
  /// means no reminder, which is the right outcome and not an error.
  static DateTime? fromCardExpiry(String? raw) {
    final text = raw?.trim();
    if (text == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(text)) return null;

    final month = int.parse(text.substring(0, 2));
    final year = int.parse(text.substring(3, 5));
    if (month < 1 || month > 12) return null;

    // Day zero of the following month is the last day of this one, and it gets
    // February and leap years right without a table.
    return DateTime(2000 + year, month + 1, 0);
  }

  /// Reads a document's `dd/MM/yyyy` into the last day it is valid.
  ///
  /// Deliberately kept to the exact day rather than rounded to the month the way
  /// a card's is. A passport that runs out on the third of March is not valid for
  /// the rest of March, and rounding would have Karde quietly say it was.
  static DateTime? fromDocumentExpiry(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;

    final parts = text.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;

    final parsed = DateTime(year, month, day);
    // Refuses 31/02/2030, which DateTime would otherwise roll forward into
    // March and treat as a perfectly good date.
    if (parsed.day != day || parsed.month != month || parsed.year != year) {
      return null;
    }
    return parsed;
  }

  /// Where [expiresOn] stands, given how much notice this kind of thing needs.
  ///
  /// Compared by whole days, because the time of day the app happens to be
  /// opened must not decide whether a passport counts as expired.
  static ExpiryStatus statusOf(
    DateTime? expiresOn, {
    required int noticeDays,
    DateTime? now,
  }) {
    if (expiresOn == null) return ExpiryStatus.fine;

    final today = _dayOf(now ?? DateTime.now());
    final last = _dayOf(expiresOn);

    if (last.isBefore(today)) return ExpiryStatus.expired;
    return last.difference(today).inDays <= noticeDays
        ? ExpiryStatus.soon
        : ExpiryStatus.fine;
  }

  static DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
