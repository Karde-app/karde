import 'package:flutter_test/flutter_test.dart';
import 'package:ibank/core/utils/expiry.dart';

void main() {
  group('Reading a card expiry', () {
    test('MM/YY becomes the last day of that month', () {
      // A card marked 03/27 works to the end of March, not to the first of it.
      // Getting this wrong would tell somebody their card had expired while it
      // was still in their hand and still working.
      expect(Expiry.fromCardExpiry('03/27'), DateTime(2027, 3, 31));
    });

    test('February is the month this has to get right', () {
      expect(Expiry.fromCardExpiry('02/27'), DateTime(2027, 2, 28));
      expect(Expiry.fromCardExpiry('02/28'), DateTime(2028, 2, 29));
    });

    test('December rolls the year rather than becoming month thirteen', () {
      expect(Expiry.fromCardExpiry('12/29'), DateTime(2029, 12, 31));
    });

    test('anything unrecognised is no date rather than a wrong one', () {
      // A card can be saved with a malformed expiry, so this has to fail quietly.
      // No date means no reminder, which is right; a guessed date would mean a
      // confident warning about the wrong month.
      expect(Expiry.fromCardExpiry(null), isNull);
      expect(Expiry.fromCardExpiry(''), isNull);
      expect(Expiry.fromCardExpiry('3/27'), isNull);
      expect(Expiry.fromCardExpiry('13/27'), isNull);
      expect(Expiry.fromCardExpiry('00/27'), isNull);
      expect(Expiry.fromCardExpiry('03-27'), isNull);
    });
  });

  group('Reading a document expiry', () {
    test('dd/MM/yyyy becomes that exact day', () {
      expect(Expiry.fromDocumentExpiry('03/03/2027'), DateTime(2027, 3, 3));
    });

    test('a day that does not exist is refused, not rolled forward', () {
      // DateTime(2030, 2, 31) silently becomes the third of March. A passport
      // that quietly moved its own expiry into another month would be worse than
      // no reminder at all.
      expect(Expiry.fromDocumentExpiry('31/02/2030'), isNull);
    });

    test('blank and malformed text yield nothing', () {
      expect(Expiry.fromDocumentExpiry(null), isNull);
      expect(Expiry.fromDocumentExpiry('  '), isNull);
      expect(Expiry.fromDocumentExpiry('2027-03-03'), isNull);
      expect(Expiry.fromDocumentExpiry('03/2027'), isNull);
    });
  });

  group('Deciding how close the end is', () {
    final today = DateTime(2026, 9, 7);

    test('no date says nothing, and never says "fine" on purpose', () {
      // Null means Karde has not been told. It reads as "fine" here only because
      // there is nothing to warn about — not because the item has been checked.
      expect(
        Expiry.statusOf(null, noticeDays: 30, now: today),
        ExpiryStatus.fine,
      );
    });

    test('yesterday has expired', () {
      expect(
        Expiry.statusOf(DateTime(2026, 9, 6), noticeDays: 30, now: today),
        ExpiryStatus.expired,
      );
    });

    test('the last valid day has not expired yet', () {
      // The boundary that matters: a card expiring today still works today.
      expect(
        Expiry.statusOf(today, noticeDays: 30, now: today),
        ExpiryStatus.soon,
      );
    });

    test('the far edge of the window is still a warning', () {
      expect(
        Expiry.statusOf(DateTime(2026, 10, 7), noticeDays: 30, now: today),
        ExpiryStatus.soon,
      );
    });

    test('one day past the window says nothing', () {
      expect(
        Expiry.statusOf(DateTime(2026, 10, 8), noticeDays: 30, now: today),
        ExpiryStatus.fine,
      );
    });

    test('the time of day cannot change the answer', () {
      // Compared by whole days. Without that, opening the app in the evening
      // could class a document differently from opening it that morning.
      final lateInTheDay = DateTime(2026, 9, 7, 23, 59);
      expect(
        Expiry.statusOf(DateTime(2026, 10, 7, 0, 1),
            noticeDays: 30, now: lateInTheDay),
        ExpiryStatus.soon,
      );
    });

    test('a document gets its longer warning', () {
      // Sixty days out is silence for a card and a warning for a passport, which
      // is the whole reason the two windows differ: renewing a passport takes
      // months, replacing a card takes days.
      final sixtyDaysOut = DateTime(2026, 11, 6);
      expect(
        Expiry.statusOf(sixtyDaysOut,
            noticeDays: Expiry.cardNoticeDays, now: today),
        ExpiryStatus.fine,
      );
      expect(
        Expiry.statusOf(sixtyDaysOut,
            noticeDays: Expiry.documentNoticeDays, now: today),
        ExpiryStatus.soon,
      );
    });
  });
}
