import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Salted, key-stretched hashing for the Karde PIN and security answers.
///
/// FIX 2-2 / 2-3: both were previously stored either as a bare unsalted SHA-256
/// hash (the PIN) or as raw plaintext (the answers). A 4-digit PIN has only
/// 10,000 possible values, so an unsalted single-round hash falls in
/// microseconds if secure storage is ever exfiltrated via backup or forensics.
///
/// This uses PBKDF2-HMAC-SHA256 with a per-secret random salt. The salt defeats
/// precomputed/rainbow tables and makes each stored secret independent; the
/// iteration count makes each guess cost real work.
///
/// Note on residual risk: key stretching raises the cost per guess but cannot
/// make a 4-digit PIN strong on its own. The real defences remain the failed-
/// attempt lockout and the OS keystore protecting the storage itself. Stretching
/// buys meaningful time if that storage is ever compromised.
class SecretHasher {
  SecretHasher._();

  static const String _algorithm = 'pbkdf2-sha256';
  static const int _iterations = 120000;
  static const int _saltLength = 16;
  static const int _keyLength = 32;

  /// Encoded as `pbkdf2-sha256:<iterations>:<salt b64>:<derived key b64>`.
  /// ':' is safe as a separator because base64 never produces it.
  static String hash(String secret) {
    final salt = _randomSalt();
    final derived = _pbkdf2(utf8.encode(secret), salt, _iterations, _keyLength);
    return '$_algorithm:$_iterations:${base64Encode(salt)}:${base64Encode(derived)}';
  }

  /// Verifies [secret] against a value produced by [hash].
  ///
  /// Returns false for malformed input rather than throwing, so a corrupted or
  /// truncated stored value fails closed instead of crashing the lock screen.
  static bool verify(String secret, String? stored) {
    if (stored == null || stored.isEmpty) return false;

    final parts = stored.split(':');
    if (parts.length != 4 || parts[0] != _algorithm) return false;

    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;

    final Uint8List salt;
    final Uint8List expected;
    try {
      salt = base64Decode(parts[2]);
      expected = base64Decode(parts[3]);
    } on FormatException {
      return false;
    }
    if (expected.isEmpty) return false;

    final derived = _pbkdf2(utf8.encode(secret), salt, iterations, expected.length);
    return _constantTimeEquals(derived, expected);
  }

  /// Normalises a security answer before hashing so that casing and stray
  /// whitespace do not lock a user out of their own recovery flow.
  static String normaliseAnswer(String answer) => answer.trim().toLowerCase();

  static Uint8List _randomSalt() {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => rng.nextInt(256)),
    );
  }

  static Uint8List _pbkdf2(
    List<int> password,
    Uint8List salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, password);
    final output = <int>[];
    var block = 1;
    while (output.length < keyLength) {
      output.addAll(_deriveBlock(hmac, salt, iterations, block));
      block++;
    }
    return Uint8List.fromList(output.sublist(0, keyLength));
  }

  static List<int> _deriveBlock(
    Hmac hmac,
    Uint8List salt,
    int iterations,
    int blockIndex,
  ) {
    final indexBytes = Uint8List(4)
      ..[0] = (blockIndex >> 24) & 0xff
      ..[1] = (blockIndex >> 16) & 0xff
      ..[2] = (blockIndex >> 8) & 0xff
      ..[3] = blockIndex & 0xff;

    var u = hmac.convert(<int>[...salt, ...indexBytes]).bytes;
    final result = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result;
  }

  /// Compares without an early exit, so timing does not leak how many leading
  /// bytes matched.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
