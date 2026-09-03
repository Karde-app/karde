import 'package:flutter/services.dart';

class WindowSecurityService {
  static const MethodChannel _channel = MethodChannel('com.ibank.security/window');

  Future<void> enableSecureMode() async {
    try {
      await _channel.invokeMethod('secure');
    } on PlatformException catch (e) {
      // Ignore
    }
  }

  Future<void> disableSecureMode() async {
    try {
      await _channel.invokeMethod('unsecure');
    } on PlatformException catch (e) {
      // Ignore
    }
  }
}
