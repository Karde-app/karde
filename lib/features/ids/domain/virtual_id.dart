/// Encoding of an ID document's encrypted payload.
///
/// The payload is a flat map of [IdFieldType] names to values, and the photo now
/// rides inside it under a reserved key. That is not cosmetic: the vault key is
/// per-use, so one authentication opens exactly one ciphertext. Keeping the photo
/// in a second ciphertext meant revealing a photographed document cost two
/// prompts. Here, one prompt yields the fields and the picture together.
///
/// The key is deliberately not a valid [IdFieldType] name, and everything that
/// walks the payload as "the user's fields" must skip it — otherwise a megabyte
/// of base64 turns up as a detail row on screen.
class IdPayload {
  IdPayload._();

  static const String photoKey = '__photo';

  static Map<String, dynamic> encode({
    required Map<String, String> fields,
    String? image,
  }) =>
      {
        ...fields,
        if (image != null && image.isNotEmpty) photoKey: image,
      };

  /// The user's document fields, with the photo removed.
  static Map<String, String> fieldsOf(Map<String, dynamic> payload) {
    final fields = <String, String>{};
    payload.forEach((key, value) {
      if (key == photoKey) return;
      fields[key] = value.toString();
    });
    return fields;
  }

  /// The base64 photo, or null if the document has none.
  static String? imageOf(Map<String, dynamic> payload) {
    final value = payload[photoKey];
    return (value is String && value.isNotEmpty) ? value : null;
  }
}

class VirtualId {
  final int? id;
  final String nickname;
  final String idType;
  final String encryptedData;

  /// Whether a photo is attached. See [VirtualCard.hasPhoto].
  final bool hasPhoto;

  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinnedToTop;
  final bool isPinnedToHomescreen;

  VirtualId({
    this.id,
    required this.nickname,
    required this.idType,
    required this.encryptedData,
    this.hasPhoto = false,
    required this.createdAt,
    required this.updatedAt,
    this.isPinnedToTop = false,
    this.isPinnedToHomescreen = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'idType': idType,
      'encryptedData': encryptedData,
      'hasPhoto': hasPhoto ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinnedToTop': isPinnedToTop ? 1 : 0,
      'isPinnedToHomescreen': isPinnedToHomescreen ? 1 : 0,
    };
  }

  factory VirtualId.fromMap(Map<String, dynamic> map) {
    return VirtualId(
      id: map['id'] as int?,
      nickname: map['nickname'] as String,
      idType: map['idType'] as String,
      // Empty when the row came from a list query, which deliberately does not
      // select the payload. See DatabaseHelper.queryIdSummaries.
      encryptedData: (map['encryptedData'] as String?) ?? '',
      hasPhoto: (map['hasPhoto'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isPinnedToTop: (map['isPinnedToTop'] as int?) == 1,
      isPinnedToHomescreen: (map['isPinnedToHomescreen'] as int?) == 1,
    );
  }

  VirtualId copyWith({
    int? id,
    String? nickname,
    String? idType,
    String? encryptedData,
    bool? hasPhoto,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinnedToTop,
    bool? isPinnedToHomescreen,
  }) {
    return VirtualId(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      idType: idType ?? this.idType,
      encryptedData: encryptedData ?? this.encryptedData,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinnedToTop: isPinnedToTop ?? this.isPinnedToTop,
      isPinnedToHomescreen: isPinnedToHomescreen ?? this.isPinnedToHomescreen,
    );
  }
}
