import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/settings_repository.dart';
import '../../cards/domain/virtual_card.dart';
import '../../ids/domain/virtual_id.dart';
import '../domain/vault_backup.dart';
import 'auto_backup_service.dart';

final autoBackupServiceProvider = Provider<AutoBackupService>((ref) {
  return AutoBackupService(settings: ref.watch(settingsRepositoryProvider));
});

final autoBackupRecorderProvider = Provider<AutoBackupRecorder>((ref) {
  return AutoBackupRecorder(ref.watch(autoBackupServiceProvider));
});

/// Turns a saved card or ID into the record the backup file holds.
///
/// Deliberately the same [BackupCard] and [BackupId] the manual export writes.
/// One shape means restore is one piece of code rather than two that must be
/// kept in step, and it means a record sealed automatically and a record sealed
/// by hand are the same thing — so nothing about a vault depends on how its
/// backup happened to be taken.
///
/// The identifiers are "card:12" and "id:3", the row's own primary key. Unique
/// within one vault, stable while the item exists, and namespaced so a card and
/// an ID with the same row number cannot overwrite each other — which they would
/// have, since the two tables number themselves independently.
class AutoBackupRecorder {
  const AutoBackupRecorder(this._service);

  final AutoBackupService _service;

  static String cardId(int id) => 'card:$id';
  static String idDocId(int id) => 'id:$id';

  /// Records a card the user has just saved.
  ///
  /// [secrets] is the payload before it was encrypted — the same map the vault
  /// holds. It arrives from the screen that built it rather than being read back
  /// out of the vault, and that is the entire trick: reading it back would cost
  /// an authentication prompt, and doing so on every save is what makes an
  /// automatic backup impossible.
  Future<void> cardSaved(VirtualCard card, Map<String, dynamic> secrets) async {
    final id = card.id;
    if (id == null) return;

    // The picture is lifted out of the payload into its own field, matching what
    // the manual export does, so a decrypted backup reads as "here is a card,
    // and here is its picture" rather than hiding a megabyte of base64 among the
    // card's fields.
    final withoutImage = Map<String, dynamic>.from(secrets);
    final image = withoutImage.remove('image');

    await _service.recordSave(
      id: cardId(id),
      plaintext: jsonEncode(
        BackupCard(
          nickname: card.nickname,
          cardBrand: card.cardBrand,
          lastFourDigits: card.lastFourDigits,
          secrets: withoutImage,
          image: image is String && image.isNotEmpty ? image : null,
          createdAt: card.createdAt,
          updatedAt: card.updatedAt,
          isPinnedToTop: card.isPinnedToTop,
          isPinnedToHomescreen: card.isPinnedToHomescreen,
        ).toJson(),
      ),
    );
  }

  /// Records an ID the user has just saved.
  Future<void> idSaved(VirtualId doc, Map<String, dynamic> payload) async {
    final id = doc.id;
    if (id == null) return;

    await _service.recordSave(
      id: idDocId(id),
      plaintext: jsonEncode(
        BackupId(
          nickname: doc.nickname,
          idType: doc.idType,
          fields: IdPayload.fieldsOf(payload),
          image: IdPayload.imageOf(payload),
          createdAt: doc.createdAt,
          updatedAt: doc.updatedAt,
          isPinnedToTop: doc.isPinnedToTop,
          isPinnedToHomescreen: doc.isPinnedToHomescreen,
        ).toJson(),
      ),
    );
  }

  Future<void> cardDeleted(int id) => _service.recordDelete(cardId(id));

  Future<void> idDeleted(int id) => _service.recordDelete(idDocId(id));
}
