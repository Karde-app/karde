import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/encryption_service.dart';
import '../../../core/storage/database.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../core/utils/expiry.dart';
import '../../cards/data/card_repository.dart';
import '../../cards/domain/virtual_card.dart';
import '../../ids/data/id_repository.dart';
import '../../ids/domain/virtual_id.dart';

/// Progress across the authentication prompts this costs.
typedef ExpiryProgress = void Function(int completed, int total);

/// Reads the expiry dates out of items that were saved before Karde was keeping
/// them where it could see them.
///
/// Anything saved from now on records its expiry as it is typed, for free —
/// Karde already has the record in plain form at that moment. Anything saved
/// earlier has its expiry sealed, and getting at it means one authentication
/// prompt per item. That is the entire reason this is a button the user presses
/// rather than something that happens quietly on startup.
///
/// Only the date is taken. The card number, the security code, the document
/// number, the holder's name and the photograph are decrypted along the way —
/// they share one payload, so there is no way to open less — and then dropped.
class ExpiryBackfill {
  const ExpiryBackfill({
    required this.cards,
    required this.ids,
    required this.vault,
    required this.database,
  });

  final CardRepository cards;
  final IdRepository ids;
  final EncryptionService vault;
  final DatabaseHelper database;

  /// The key an ID document's expiry travels under. Matches
  /// `IdFieldType.expiryDate.name`, which is what the form writes.
  ///
  /// A plain string rather than the enum, so this layer does not have to import
  /// a screen. If the enum is ever renamed, the field name on every saved
  /// document changes with it and this constant has to change too — which is
  /// true of the form's own reading code as well, and is why the name is worth
  /// treating as part of the stored format rather than an implementation detail.
  static const String documentExpiryField = 'expiryDate';

  /// How many items Karde cannot see an expiry for.
  ///
  /// Counted from the lists, which carry the date but no payload, so asking is
  /// free. Items with no expiry recorded *and* nothing readable inside — a card
  /// saved with a malformed date — will be counted here every time, because
  /// there is no way to tell them apart without opening them. Reading them once
  /// costs a prompt and changes nothing; that is a fair price for not having to
  /// keep a second flag saying "we looked and there was nothing".
  Future<int> missingCount() async {
    final storedCards = await cards.getAllCards();
    final storedIds = await ids.getAllIds();
    return storedCards.where((c) => c.id != null && c.expiresOn == null).length +
        storedIds.where((i) => i.id != null && i.expiresOn == null).length;
  }

  /// Opens each of them and writes down when it runs out.
  ///
  /// Returns how many dates were actually recorded, which can be fewer than the
  /// number of prompts spent: an item whose expiry was typed in a form Karde
  /// cannot parse yields nothing, and saying "8 dates saved" when six were found
  /// would be a lie about what the user just paid for.
  ///
  /// Throws [VaultAuthCancelled] if a prompt is dismissed. Whatever was written
  /// before that point stays written — unlike a backup or a restore, there is no
  /// half-finished state to unpick here, and a second run simply picks up the
  /// ones that are still missing.
  Future<int> fillMissing({required ExpiryProgress onProgress}) async {
    final pendingCards = (await cards.getAllCards())
        .where((c) => c.id != null && c.expiresOn == null)
        .toList();
    final pendingIds = (await ids.getAllIds())
        .where((i) => i.id != null && i.expiresOn == null)
        .toList();

    final total = pendingCards.length + pendingIds.length;
    if (total == 0) return 0;

    var completed = 0;
    var written = 0;
    onProgress(completed, total);

    for (final card in pendingCards) {
      final secrets = CardSecrets.fromJson(
        await vault.decrypt(await cards.payloadFor(card)),
      );
      final expiresOn = Expiry.fromCardExpiry(secrets.expiry);
      if (expiresOn != null) {
        await database.setCardExpiry(card.id!, expiresOn);
        written++;
      }
      onProgress(++completed, total);
    }

    for (final doc in pendingIds) {
      final payload = jsonDecode(await vault.decrypt(await ids.payloadFor(doc)))
          as Map<String, dynamic>;
      final expiresOn = Expiry.fromDocumentExpiry(
        IdPayload.fieldsOf(payload)[documentExpiryField],
      );
      if (expiresOn != null) {
        await database.setIdExpiry(doc.id!, expiresOn);
        written++;
      }
      onProgress(++completed, total);
    }

    return written;
  }
}

final expiryBackfillProvider = Provider<ExpiryBackfill>((ref) {
  return ExpiryBackfill(
    cards: ref.watch(cardRepositoryProvider),
    ids: ref.watch(idRepositoryProvider),
    vault: EncryptionService(),
    database: DatabaseHelper.instance,
  );
});

/// How many saved items Karde still cannot see an expiry for.
///
/// Zero whenever the reminders are switched off, because offering to read items
/// for a feature that is not running would be asking for fingerprints in
/// exchange for nothing.
///
/// autoDispose so it is asked again on each visit to Settings: it changes when a
/// card is saved, when the reading runs, and when the switch is flipped.
final expiryMissingCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  if (!ref.watch(expiryRemindersProvider)) return 0;
  return ref.watch(expiryBackfillProvider).missingCount();
});
