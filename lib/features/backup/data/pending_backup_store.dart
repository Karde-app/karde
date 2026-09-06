import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Changes that have not reached the backup folder yet.
///
/// Without this, a failed write did not just fail — it lost the change. Each
/// save read the folder's file, added its one record and wrote it back, so a
/// save that could not reach the folder left that card missing from the backup
/// permanently, or until the user happened to edit it again. The user found the
/// case immediately: a cloud folder and no signal.
///
/// Being offline is not an exception for a cloud folder. It is a plane, a train,
/// a basement, a country with no data. So changes queue here and are pushed when
/// the folder can be reached, and the warning is for a backup that has been
/// behind for a while rather than for every moment of poor signal.
///
/// What is stored is already sealed — ciphertext under the backup's public half,
/// exactly as it would sit in the file. Karde could not read it back if it
/// wanted to, so keeping it in the app's private storage costs nothing.
class PendingBackupStore {
  PendingBackupStore({Directory? directory}) : _directory = directory;

  final Directory? _directory;

  static const String fileName = 'pending_backup.json';

  Future<File> _file() async {
    final dir = _directory ?? await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  /// Everything waiting to be written, or an empty set.
  ///
  /// Unreadable is treated as empty. The queue is a convenience holding
  /// ciphertext Karde can rebuild by other means; refusing to work because of a
  /// damaged one would turn a small problem into a stopped backup.
  Future<PendingBackupChanges> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return PendingBackupChanges.empty();
      return PendingBackupChanges.decode(await file.readAsString());
    } catch (_) {
      return PendingBackupChanges.empty();
    }
  }

  Future<void> write(PendingBackupChanges changes) async {
    final file = await _file();
    if (changes.isEmpty) {
      if (await file.exists()) await file.delete();
      return;
    }
    await file.writeAsString(changes.encode(), flush: true);
  }

  Future<void> clear() => write(PendingBackupChanges.empty());
}

/// A set of changes waiting for the backup folder.
class PendingBackupChanges {
  PendingBackupChanges({
    required Map<String, String> saved,
    required Set<String> deleted,
    required this.since,
  })  : _saved = saved,
        _deleted = deleted;


  /// Sealed records by id. One entry per item, so a card saved five times while
  /// offline arrives once rather than five times.
  final Map<String, String> _saved;

  /// Items deleted while the folder was out of reach.
  final Set<String> _deleted;

  /// When the queue stopped being empty.
  ///
  /// The difference between "no signal for a minute" and "this backup has not
  /// worked for a week", which are the same fact and very different messages.
  final DateTime? since;

  bool get isEmpty => _saved.isEmpty && _deleted.isEmpty;
  int get count => _saved.length + _deleted.length;
  Map<String, String> get saved => Map.unmodifiable(_saved);
  Set<String> get deleted => Set.unmodifiable(_deleted);

  /// How long the backup has been behind, or null if it is not.
  Duration? get behindFor =>
      since == null ? null : DateTime.now().toUtc().difference(since!);

  static PendingBackupChanges empty() =>
      PendingBackupChanges(saved: {}, deleted: {}, since: null);

  PendingBackupChanges withSave(String id, String sealed) {
    return PendingBackupChanges(
      // A later save replaces an earlier one, and cancels a pending delete of
      // the same item: whatever happened last is what the backup should hold.
      saved: {..._saved, id: sealed},
      deleted: {..._deleted}..remove(id),
      since: since ?? DateTime.now().toUtc(),
    );
  }

  PendingBackupChanges withDelete(String id) {
    return PendingBackupChanges(
      saved: {..._saved}..remove(id),
      deleted: {..._deleted, id},
      since: since ?? DateTime.now().toUtc(),
    );
  }

  String encode() => jsonEncode({
        'since': (since ?? DateTime.now().toUtc()).toIso8601String(),
        'saved': _saved,
        'deleted': _deleted.toList(),
      });

  static PendingBackupChanges decode(String contents) {
    final json = jsonDecode(contents) as Map<String, dynamic>;
    final saved = <String, String>{};
    final rawSaved = json['saved'];
    if (rawSaved is Map) {
      rawSaved.forEach((key, value) {
        if (key is String && value is String) saved[key] = value;
      });
    }
    final deleted = <String>{};
    final rawDeleted = json['deleted'];
    if (rawDeleted is List) {
      for (final id in rawDeleted) {
        if (id is String) deleted.add(id);
      }
    }
    final since = json['since'];
    return PendingBackupChanges(
      saved: saved,
      deleted: deleted,
      since: since is String ? DateTime.tryParse(since)?.toUtc() : null,
    );
  }
}
