import 'package:flutter/services.dart';

import '../security/system_interaction_guard.dart';

/// Opens Karde's own page in the Play Store.
///
/// Testers asked how they would know an update was available. Karde has no
/// internet permission and never will, so it cannot check; what it can do is
/// hand the user to the store, which shows "Update" if there is one and does
/// the network work itself. That keeps the promise and still answers the
/// question.
///
/// Opening another app drives Karde's activity into the background, which
/// would normally lock the vault behind it — so the call runs inside
/// [SystemInteractionGuard], the same as every other system window this app
/// raises.
class StoreListingService {
  static const MethodChannel _channel = MethodChannel('com.ibank.security/store');

  /// Returns false when neither the Play Store nor a browser could be opened,
  /// so the caller can say so rather than silently doing nothing.
  Future<bool> open() {
    return SystemInteractionGuard.run(() async {
      try {
        return await _channel.invokeMethod<bool>('openListing') ?? false;
      } on PlatformException {
        return false;
      }
    });
  }
}
