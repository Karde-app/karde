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

/// Whether automatic backup is set up on this phone.
///
/// autoDispose so it is asked again on each fresh listen, since setup can happen
/// while nothing is watching — during onboarding, most obviously.
final autoBackupConfiguredProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(autoBackupServiceProvider).isConfigured;
});

/// How backup is set up, for screens that need to name the folder.
final autoBackupSetupProvider =
    FutureProvider.autoDispose<AutoBackupSetup?>((ref) {
  return ref.watch(autoBackupServiceProvider).setup();
});

/// Whether Karde is holding a copy of the passphrase for this phone's owner to
/// look up.
///
/// Drives one row on the Backup screen between two readings: "show me my
/// passphrase" when there is a copy, and "keep a copy" when there is not. False
/// is a real state rather than an error — the copy is sealed by the vault key,
/// so removing the phone's screen lock destroys it while leaving the backup
/// itself perfectly good.
///
/// autoDispose for the same reason as the others here: it changes during setup
/// and during a passphrase change, sometimes with this screen not yet built.
final backupPassphraseSavedProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(autoBackupServiceProvider).hasPassphraseReminder;
});

/// Whether the last attempt to write the backup failed.
///
/// A plain flag rather than something derived, because the thing worth reporting
/// is not "can the folder be reached right now" but "the copy on disk is older
/// than the vault". Those differ in exactly the case that matters: the user adds
/// a card with no signal, the write to their cloud folder fails, and by the time
/// anyone asks about the folder again it is reachable and perfectly healthy —
/// while the card that was added is still missing from the backup.
final autoBackupFailingProvider = StateProvider<bool>((ref) => false);

final autoBackupRecorderProvider = Provider<AutoBackupRecorder>((ref) {
  return AutoBackupRecorder(ref.watch(autoBackupServiceProvider), ref);
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
  AutoBackupRecorder(this._service, this._ref);

  final AutoBackupService _service;
  final Ref _ref;

  bool _lastWriteFailed = false;

  /// Runs a backup write, remembering rather than raising a failure.
  ///
  /// See [lastWriteFailed]. Every caller reaches here having already written to
  /// the vault, so nothing above this line can usefully treat a backup failure
  /// as a failed save — and treating it that way actively misled the user.
  /// How long to wait before deciding a failed write really failed.
  ///
  /// A cloud folder is not a disk. The user reported the first card after setup
  /// saying "could not be copied", the alert appearing with a Fix button, and
  /// then the whole thing clearing itself a few seconds later with the file
  /// correctly updated — the provider had simply not finished settling after
  /// creating the folder's first file.
  ///
  /// Everything about that was working as designed, and all of it was wrong to
  /// show. An alert that resolves itself before the user has finished reading it
  /// teaches them that alerts are noise, which is expensive on the day one is
  /// not. So a save waits and tries once more before saying anything.
  ///
  /// Only on the user's own save, where somebody is watching and a moment costs
  /// nothing. The background retry does not wait: nobody is reading it.
  static const Duration _settlePause = Duration(milliseconds: 1200);

  Future<void> _record(Future<void> Function() write) async {
    try {
      await write();
      _lastWriteFailed = false;
    } catch (_) {
      try {
        await Future<void>.delayed(_settlePause);
        await _service.flushPending();
        _lastWriteFailed = false;
      } catch (_) {
        _lastWriteFailed = true;
      }
    }
    // Published so the dashboard can say the backup has fallen behind. Only ever
    // cleared by a write that succeeds, which is the point: a folder that comes
    // back online has not thereby copied the card that was added while it was
    // away.
    _ref.read(autoBackupFailingProvider.notifier).state = _lastWriteFailed;
  }

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

    await _record(() => _service.recordSave(
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
        ));
  }

  /// Records an ID the user has just saved.
  Future<void> idSaved(VirtualId doc, Map<String, dynamic> payload) async {
    final id = doc.id;
    if (id == null) return;

    await _record(() => _service.recordSave(
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
        ));
  }

  Future<void> cardDeleted(int id) =>
      _record(() => _service.recordDelete(cardId(id)));

  Future<void> idDeleted(int id) =>
      _record(() => _service.recordDelete(idDocId(id)));

  /// Pushes anything waiting, quietly.
  ///
  /// Called when Karde comes back to the foreground, which is the moment a phone
  /// that was underground or on a plane is most likely to have a connection
  /// again. Failure is swallowed on purpose: nobody wants a message every time a
  /// phone comes out of a pocket, and the dashboard already says the backup is
  /// behind for as long as it is.
  Future<void> retryQuietly() async {
    try {
      await _service.flushPending();
      _lastWriteFailed = false;
    } catch (_) {
      _lastWriteFailed = true;
    }
    _ref.read(autoBackupFailingProvider.notifier).state = _lastWriteFailed;
  }

  /// Whether the last attempt to write the backup failed.
  ///
  /// The item is already safely in the vault by the time any of this runs, so a
  /// backup that cannot be written must not be reported as a failed save. It
  /// was: the exception travelled up through the save, the form showed "could
  /// not save", and the user — whose card was sitting in the vault the whole
  /// time — would reasonably have typed it in again.
  ///
  /// So the failure is remembered here rather than thrown at the form, and the
  /// screen asks afterwards. What it means is not "your card is lost" but "your
  /// backup has stopped", which is a different message at a different moment.
  bool get lastWriteFailed => _lastWriteFailed;
}
