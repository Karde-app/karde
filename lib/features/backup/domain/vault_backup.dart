import 'dart:convert';

import '../../../core/app_info.dart';

/// What is wrong with a backup file.
///
/// A code rather than a sentence: the domain layer has no locale, so the
/// wording lives in the ARB files and is chosen by whichever screen reports
/// the failure.
enum BackupContentProblem {
  damaged,
  notAKardeBackup,
  newerVersion,
  photoDamaged,
  recordUnreadable,
  missingValue,
  unreadableValue,
}

/// The backup file is structurally valid but its contents are not usable.
class BackupContentInvalid implements Exception {
  final BackupContentProblem problem;

  /// The JSON key at fault, for the two problems that name one.
  final String? key;

  const BackupContentInvalid(this.problem, {this.key});

  @override
  String toString() => 'BackupContentInvalid($problem${key == null ? '' : ': $key'})';
}

/// One card, with its secrets in the clear.
///
/// This type exists only inside a backup operation. On the device a card's
/// secrets are never held in a model — they are decrypted, used, and dropped.
/// Here they have to be materialised for exactly as long as it takes to seal the
/// bundle under the user's passphrase.
class BackupCard {
  final String nickname;
  final String cardBrand;
  final String lastFourDigits;
  final Map<String, dynamic> secrets;

  /// The card's photo as base64 JPEG, or null if it has none.
  ///
  /// Carried in the clear inside the bundle, exactly like the card number beside
  /// it: the whole bundle is sealed under the user's passphrase, and a backup
  /// that silently dropped photos would be a trap — the user would only discover
  /// the loss on the day they restored it, having deleted the original.
  final String? image;

  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinnedToTop;
  final bool isPinnedToHomescreen;

  const BackupCard({
    required this.nickname,
    required this.cardBrand,
    required this.lastFourDigits,
    required this.secrets,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    required this.isPinnedToTop,
    required this.isPinnedToHomescreen,
  });

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'cardBrand': cardBrand,
        'lastFourDigits': lastFourDigits,
        'secrets': secrets,
        if (image != null) 'image': image,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isPinnedToTop': isPinnedToTop,
        'isPinnedToHomescreen': isPinnedToHomescreen,
      };

  factory BackupCard.fromJson(Map<String, dynamic> json) => BackupCard(
        nickname: requireBackupString(json, 'nickname'),
        cardBrand: requireBackupString(json, 'cardBrand'),
        lastFourDigits: requireBackupString(json, 'lastFourDigits'),
        secrets: requireBackupMap(json, 'secrets'),
        image: optionalBackupImage(json),
        createdAt: requireBackupDate(json, 'createdAt'),
        updatedAt: requireBackupDate(json, 'updatedAt'),
        isPinnedToTop: json['isPinnedToTop'] == true,
        isPinnedToHomescreen: json['isPinnedToHomescreen'] == true,
      );

  /// Whether restoring this card will cost a second prompt for its photo.
  bool get hasImage => image != null;

  /// Identity used to recognise a card that is already in the vault.
  ///
  /// `createdAt` is the only field that is both stable across a restore and
  /// stored unencrypted on the device, so a duplicate can be recognised without
  /// spending an authentication prompt per card just to find out whether the
  /// card needs importing at all.
  String get identity => '$nickname|${createdAt.toIso8601String()}';
}

/// One ID document, with its fields in the clear. See [BackupCard].
class BackupId {
  final String nickname;
  final String idType;
  final Map<String, dynamic> fields;

  /// The document photo as base64 JPEG, or null if it has none. See [BackupCard].
  final String? image;

  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinnedToTop;
  final bool isPinnedToHomescreen;

  const BackupId({
    required this.nickname,
    required this.idType,
    required this.fields,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    required this.isPinnedToTop,
    required this.isPinnedToHomescreen,
  });

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'idType': idType,
        'fields': fields,
        if (image != null) 'image': image,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isPinnedToTop': isPinnedToTop,
        'isPinnedToHomescreen': isPinnedToHomescreen,
      };

  factory BackupId.fromJson(Map<String, dynamic> json) => BackupId(
        nickname: requireBackupString(json, 'nickname'),
        idType: requireBackupString(json, 'idType'),
        fields: requireBackupMap(json, 'fields'),
        image: optionalBackupImage(json),
        createdAt: requireBackupDate(json, 'createdAt'),
        updatedAt: requireBackupDate(json, 'updatedAt'),
        isPinnedToTop: json['isPinnedToTop'] == true,
        isPinnedToHomescreen: json['isPinnedToHomescreen'] == true,
      );

  /// Whether restoring this document will cost a second prompt for its photo.
  bool get hasImage => image != null;

  String get identity => '$nickname|${createdAt.toIso8601String()}';
}

/// The plaintext contents of a backup, as they exist between decryption from the
/// vault key and encryption under the user's passphrase.
///
/// Row ids are deliberately not carried. They are local autoincrement values with
/// no meaning on another device, and preserving them would collide with whatever
/// the destination vault already holds.
///
/// The device's own lock configuration — Karde PIN, security answers, recovery
/// preference — is also not carried. Those secure *this installation* rather than
/// the data, and restoring them onto a second device would clone one device's
/// lock onto another instead of letting the new device be set up on its own
/// terms. It also keeps the PIN out of a file that leaves the device.
class VaultBackup {
  static const String format = 'karde.vault';

  /// Bundle format version.
  ///
  /// 1 — cards and ID documents, text only.
  /// 2 — adds an optional base64 "image" to each record.
  ///
  /// Version 1 files still restore: the field is optional, so a v1 record simply
  /// has no photo. The bump exists for the other direction, so that an older
  /// build meeting a v2 file refuses it with an explanation instead of silently
  /// importing everything except the photos and leaving the user believing the
  /// restore was complete.
  static const int version = 2;

  final DateTime createdAt;
  final String appVersion;
  final List<BackupCard> cards;
  final List<BackupId> ids;

  const VaultBackup({
    required this.createdAt,
    required this.appVersion,
    required this.cards,
    required this.ids,
  });

  VaultBackup.now({required this.cards, required this.ids})
      : createdAt = DateTime.now(),
        appVersion = AppInfo.version;

  int get itemCount => cards.length + ids.length;

  /// Authentication prompts a restore of everything here would cost.
  ///
  /// Exactly one per record. The vault key requires authentication for every
  /// use, but a photo is not a separate use: it travels inside its record's own
  /// encrypted payload, so it comes back on the same authentication as the
  /// fields beside it.
  int get promptCount => itemCount;

  String encode() => jsonEncode({
        'format': format,
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        'appVersion': appVersion,
        'cards': cards.map((c) => c.toJson()).toList(),
        'ids': ids.map((i) => i.toJson()).toList(),
      });

  /// Parses a decrypted bundle.
  ///
  /// Throws [BackupContentInvalid] rather than letting a `FormatException` or a
  /// cast error escape, so a truncated or hand-edited file produces a sentence
  /// the user can act on instead of a crash.
  factory VaultBackup.decode(String source) {
    final Object? raw;
    try {
      raw = jsonDecode(source);
    } on FormatException {
      throw const BackupContentInvalid(BackupContentProblem.damaged);
    }

    if (raw is! Map<String, dynamic>) {
      throw const BackupContentInvalid(BackupContentProblem.damaged);
    }

    if (raw['format'] != format) {
      throw const BackupContentInvalid(BackupContentProblem.notAKardeBackup);
    }

    final fileVersion = raw['version'];
    if (fileVersion is! int || fileVersion > version) {
      throw const BackupContentInvalid(BackupContentProblem.newerVersion);
    }

    try {
      return VaultBackup(
        createdAt: requireBackupDate(raw, 'createdAt'),
        appVersion: (raw['appVersion'] as String?) ?? 'unknown',
        cards: _entryList(raw['cards']).map(BackupCard.fromJson).toList(),
        ids: _entryList(raw['ids']).map(BackupId.fromJson).toList(),
      );
    } on BackupContentInvalid {
      rethrow;
    } catch (_) {
      throw const BackupContentInvalid(BackupContentProblem.damaged);
    }
  }

  static List<Map<String, dynamic>> _entryList(Object? value) {
    if (value == null) return const [];
    if (value is! List) {
      throw const BackupContentInvalid(BackupContentProblem.damaged);
    }
    return value.cast<Map<String, dynamic>>();
  }
}

/// Reads a record's optional base64 photo.
///
/// Absent is fine — a v1 backup has none, and a v2 record need not. Present but
/// not a non-empty string is not fine: it means the file was edited or damaged,
/// and importing it as "no photo" would quietly lose data the user believes they
/// backed up.
String? optionalBackupImage(Map<String, dynamic> json) {
  final value = json['image'];
  if (value == null) return null;
  if (value is! String || value.isEmpty) {
    throw const BackupContentInvalid(BackupContentProblem.photoDamaged);
  }
  return value;
}

String requireBackupString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw BackupContentInvalid(BackupContentProblem.missingValue, key: key);
  }
  return value;
}

Map<String, dynamic> requireBackupMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) {
    throw BackupContentInvalid(BackupContentProblem.missingValue, key: key);
  }
  return Map<String, dynamic>.from(value);
}

DateTime requireBackupDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw BackupContentInvalid(BackupContentProblem.missingValue, key: key);
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw BackupContentInvalid(BackupContentProblem.unreadableValue, key: key);
  }
  return parsed;
}
