import 'package:flutter/services.dart';

class EncryptionService {
  static const MethodChannel _channel = MethodChannel('com.ibank.security/encryption');

  Future<String> encrypt(String plaintext) async {
    try {
      final String encrypted = await _channel.invokeMethod('encrypt', {'data': plaintext});
      return encrypted;
    } on PlatformException catch (e) {
      throw Exception("Encryption failed: ${e.message}");
    }
  }

  Future<String> decrypt(String encryptedText) async {
    try {
      final String decrypted = await _channel.invokeMethod('decrypt', {'data': encryptedText});
      return decrypted;
    } on PlatformException catch (e) {
      throw Exception("Decryption failed: ${e.message}");
    }
  }
}
