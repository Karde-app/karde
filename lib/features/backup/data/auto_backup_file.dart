import 'dart:convert';

import '../../../core/security/bundle_crypto_service.dart';

/// The shape of an automatic backup on disk.
///
/// One file, holding many separately sealed records rather than one sealed lump.
/// That is the whole reason automatic backup is possible: rebuilding a single
/// sealed lump means reading every item back out of the vault, and the vault key
/// demands an authentication prompt per item, so ten saved cards would be ten
/// fingerprint touches for a single edit. Sealing one record at the moment the
/// user saves it costs nothing, because Karde already has that record in plain
/// form and needs nothing from the Keystore.
///
/// The file is self-contained. It carries the sealed private half of the key
/// pair, so restoring on a new phone needs the file and the passphrase and
/// nothing else — no account, no server, and nothing left behind on the old
/// phone.
class AutoBackupFile {
  AutoBackupFile({
    required this.sealedPrivateKey,
    required this.createdAt,
    required this.updatedAt,
    required Map<String, Map<String, dynamic>> records,
  }) : _records = records;

  /// What this file is, written in the clear so a person finding it can tell.
  static const String formatName = 'karde.autobackup';
  static const int formatVersion = 1;

  /// The private half of the pair, wrapped in a passphrase envelope.
  final String sealedPrivateKey;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Sealed records, keyed so a save can replace exactly one of them.
  ///
  /// A map rather than a list because every write is an upsert of one known
  /// record, and a list would mean scanning to find it and risk two copies of
  /// the same item if a key were ever written twice.
  final Map<String, Map<String, dynamic>> _records;

  int get count => _records.length;
  Iterable<String> get ids => _records.keys;

  /// Every sealed record, in the form [BackupIdentityService.openAll] wants.
  List<String> get sealedRecords =>
      _records.values.map((record) => jsonEncode(record)).toList();

  /// The same records, each still paired with its id.
  ///
  /// A restore needs the id: "card:12" and "id:3" are the only thing that says
  /// whether an opened record is a card or a document. Pairing them here rather
  /// than relying on [ids] and [sealedRecords] coming back in the same order,
  /// which is true today and is not the kind of thing a restore should depend on.
  List<MapEntry<String, String>> get sealedEntries => _records.entries
      .map((entry) => MapEntry(entry.key, jsonEncode(entry.value)))
      .toList();

  /// Whether [id] names a card. Anything else in the file is a document.
  static bool isCardId(String id) => id.startsWith('card:');

  /// Replaces one record, or adds it. [sealed] is what the platform returned.
  void put(String id, String sealed) {
    _records[id] = jsonDecode(sealed) as Map<String, dynamic>;
  }

  /// Forgets one record. Returns whether there was one to forget.
  bool remove(String id) => _records.remove(id) != null;

  static AutoBackupFile empty(String sealedPrivateKey) {
    final now = DateTime.now().toUtc();
    return AutoBackupFile(
      sealedPrivateKey: sealedPrivateKey,
      createdAt: now,
      updatedAt: now,
      records: {},
    );
  }

  /// Reads a file written by [encode].
  ///
  /// Refuses anything it does not recognise rather than guessing. A backup is
  /// the one thing that must never be half-understood: quietly accepting a file
  /// whose format has moved on, and then writing it back in this one's shape,
  /// would destroy whatever the newer format was carrying.
  factory AutoBackupFile.decode(String contents) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(contents) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupFileUnreadable('not a Karde automatic backup');
    }

    if (json['format'] != formatName) {
      throw const BackupFileUnreadable('not a Karde automatic backup');
    }
    final version = json['version'];
    if (version is! int || version > formatVersion) {
      throw BackupFileUnreadable(
        'this backup was written by a newer version of Karde ($version)',
      );
    }

    final sealedPrivateKey = json['sealedPrivateKey'];
    if (sealedPrivateKey is! String || sealedPrivateKey.isEmpty) {
      throw const BackupFileUnreadable('the backup has no key to open it with');
    }

    final rawRecords = json['records'];
    final records = <String, Map<String, dynamic>>{};
    if (rawRecords is Map) {
      rawRecords.forEach((key, value) {
        if (key is String && value is Map) {
          records[key] = Map<String, dynamic>.from(value);
        }
      });
    }

    return AutoBackupFile(
      sealedPrivateKey: sealedPrivateKey,
      createdAt: _readTime(json['createdAt']),
      updatedAt: _readTime(json['updatedAt']),
      records: records,
    );
  }

  /// Writes the file, stamped with the moment of writing.
  String encode() {
    return const JsonEncoder.withIndent('  ').convert({
      'format': formatName,
      'version': formatVersion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'sealedPrivateKey': sealedPrivateKey,
      'records': _records,
    });
  }

  static DateTime _readTime(Object? value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toUtc();
    }
    return DateTime.now().toUtc();
  }
}
