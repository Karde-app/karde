class VirtualCard {
  final int? id;
  final String nickname;
  final String cardBrand;
  final String lastFourDigits;
  final String encryptedCardNumber;
  final String encryptedExpiry;
  final String encryptedCvv;
  final String encryptedCardholderName;
  final String encryptedNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  VirtualCard({
    this.id,
    required this.nickname,
    required this.cardBrand,
    required this.lastFourDigits,
    required this.encryptedCardNumber,
    required this.encryptedExpiry,
    required this.encryptedCvv,
    required this.encryptedCardholderName,
    required this.encryptedNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'cardBrand': cardBrand,
      'lastFourDigits': lastFourDigits,
      'encryptedCardNumber': encryptedCardNumber,
      'encryptedExpiry': encryptedExpiry,
      'encryptedCvv': encryptedCvv,
      'encryptedCardholderName': encryptedCardholderName,
      'encryptedNotes': encryptedNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory VirtualCard.fromMap(Map<String, dynamic> map) {
    return VirtualCard(
      id: map['id'] as int?,
      nickname: map['nickname'] as String,
      cardBrand: map['cardBrand'] as String,
      lastFourDigits: map['lastFourDigits'] as String,
      encryptedCardNumber: map['encryptedCardNumber'] as String,
      encryptedExpiry: map['encryptedExpiry'] as String,
      encryptedCvv: map['encryptedCvv'] as String,
      encryptedCardholderName: map['encryptedCardholderName'] as String,
      encryptedNotes: map['encryptedNotes'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  VirtualCard copyWith({
    int? id,
    String? nickname,
    String? cardBrand,
    String? lastFourDigits,
    String? encryptedCardNumber,
    String? encryptedExpiry,
    String? encryptedCvv,
    String? encryptedCardholderName,
    String? encryptedNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VirtualCard(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      cardBrand: cardBrand ?? this.cardBrand,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      encryptedCardNumber: encryptedCardNumber ?? this.encryptedCardNumber,
      encryptedExpiry: encryptedExpiry ?? this.encryptedExpiry,
      encryptedCvv: encryptedCvv ?? this.encryptedCvv,
      encryptedCardholderName: encryptedCardholderName ?? this.encryptedCardholderName,
      encryptedNotes: encryptedNotes ?? this.encryptedNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
