import 'dart:convert';

/// The plaintext secrets of a card, held only transiently in memory.
///
/// FIX 2-1: these travel as ONE JSON payload through a single encrypt/decrypt
/// call. The vault key requires user authentication for every use, so each
/// cryptographic operation costs one OS prompt — encrypting five fields
/// separately would mean five prompts to save a single card.
///
/// The photo travels here too, for exactly the same reason. It was briefly held
/// as a separate encrypted file, which meant a second ciphertext and therefore a
/// second prompt: revealing a photographed card asked the user to authenticate
/// twice. An authorised cipher is de-authorised after a single `doFinal`, so one
/// prompt can only ever open one ciphertext — putting the photo in this payload
/// is the only way the eye button can reveal everything at once.
class CardSecrets {
  final String cardNumber;
  final String expiry;
  final String cvv;
  final String cardholderName;
  final String notes;

  /// The card photo as base64 JPEG, or null if there is none.
  final String? image;

  const CardSecrets({
    required this.cardNumber,
    required this.expiry,
    required this.cvv,
    required this.cardholderName,
    this.notes = '',
    this.image,
  });

  bool get hasImage => image != null && image!.isNotEmpty;

  String toJson() => jsonEncode({
        'cardNumber': cardNumber,
        'expiry': expiry,
        'cvv': cvv,
        'cardholderName': cardholderName,
        'notes': notes,
        if (hasImage) 'image': image,
      });

  factory CardSecrets.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    final image = map['image'];
    return CardSecrets(
      cardNumber: (map['cardNumber'] as String?) ?? '',
      expiry: (map['expiry'] as String?) ?? '',
      cvv: (map['cvv'] as String?) ?? '',
      cardholderName: (map['cardholderName'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      image: (image is String && image.isNotEmpty) ? image : null,
    );
  }
}

class VirtualCard {
  final int? id;
  final String nickname;
  final String cardBrand;
  final String lastFourDigits;

  /// All card secrets, encrypted as a single AES-256-GCM payload.
  final String encryptedData;

  /// Whether a photo is attached, kept outside the encrypted payload.
  ///
  /// The picture itself is sealed inside [encryptedData]; this is only the fact
  /// that one exists, so the vault list can badge the card without decrypting
  /// it. See the v6 migration for why that trade is acceptable.
  final bool hasPhoto;

  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinnedToTop;
  final bool isPinnedToHomescreen;

  VirtualCard({
    this.id,
    required this.nickname,
    required this.cardBrand,
    required this.lastFourDigits,
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
      'cardBrand': cardBrand,
      'lastFourDigits': lastFourDigits,
      'encryptedData': encryptedData,
      'hasPhoto': hasPhoto ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinnedToTop': isPinnedToTop ? 1 : 0,
      'isPinnedToHomescreen': isPinnedToHomescreen ? 1 : 0,
    };
  }

  factory VirtualCard.fromMap(Map<String, dynamic> map) {
    return VirtualCard(
      id: map['id'] as int?,
      nickname: map['nickname'] as String,
      cardBrand: map['cardBrand'] as String,
      lastFourDigits: map['lastFourDigits'] as String,
      // Empty when the row came from a list query, which deliberately does not
      // select the payload. See DatabaseHelper.queryCardSummaries.
      encryptedData: (map['encryptedData'] as String?) ?? '',
      hasPhoto: (map['hasPhoto'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isPinnedToTop: (map['isPinnedToTop'] as int?) == 1,
      isPinnedToHomescreen: (map['isPinnedToHomescreen'] as int?) == 1,
    );
  }

  VirtualCard copyWith({
    int? id,
    String? nickname,
    String? cardBrand,
    String? lastFourDigits,
    String? encryptedData,
    bool? hasPhoto,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinnedToTop,
    bool? isPinnedToHomescreen,
  }) {
    return VirtualCard(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      cardBrand: cardBrand ?? this.cardBrand,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      encryptedData: encryptedData ?? this.encryptedData,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinnedToTop: isPinnedToTop ?? this.isPinnedToTop,
      isPinnedToHomescreen: isPinnedToHomescreen ?? this.isPinnedToHomescreen,
    );
  }
}
