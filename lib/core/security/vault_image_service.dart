import 'package:flutter/services.dart';

import 'system_interaction_guard.dart';

/// Why a picked file could not be turned into an image.
///
/// A code, not a sentence: this class sits below the widget tree and has no
/// locale, so the wording belongs to whichever field reports the failure.
enum VaultImageProblem {
  /// Nothing on the device can hand over a picture — no gallery app, or no
  /// usable camera.
  noSource,

  /// A file came back but could not be decoded.
  unreadable,

  /// The platform channel is not there at all.
  unsupported,
}

/// The picked file could not be turned into an image.
class VaultImageUnreadable implements Exception {
  final VaultImageProblem problem;
  const VaultImageUnreadable(this.problem);

  @override
  String toString() => 'VaultImageUnreadable($problem)';
}

/// Gets a photo into the app, from the gallery or the camera.
///
/// Storage is deliberately not this class's business. A photo is written as part
/// of its record's single encrypted payload — the same ciphertext as the card
/// number or the document fields — because the vault key requires authentication
/// for every use and one authentication can only ever open one ciphertext. A
/// photo kept in its own encrypted file was a second ciphertext, and therefore a
/// second fingerprint prompt to save a card and another to reveal it.
///
/// So this only sources the bytes. Encrypting them is the caller's single
/// existing save operation.
class VaultImageService {
  static const MethodChannel _pickerChannel =
      MethodChannel('com.ibank.security/images');

  /// Asks the user to choose an image. Returns null if they backed out.
  ///
  /// The bytes come back already downscaled and re-compressed, and stripped of
  /// every EXIF tag the original carried — including the GPS coordinates a phone
  /// writes into a photo, which on a picture of an ID document would record where
  /// its owner lives.
  Future<Uint8List?> pickFromGallery() => _source('pickImage');

  /// Opens the camera. Returns null if the user backed out.
  Future<Uint8List?> captureWithCamera() => _source('captureImage');

  Future<Uint8List?> _source(String method) {
    // The gallery and the camera are system windows on top of Karde, and the user
    // may spend minutes in either. Without this the auto-lock timer would run the
    // whole time and drop them back at the lock screen holding a photo.
    return SystemInteractionGuard.run(() async {
      try {
        return await _pickerChannel.invokeMethod<Uint8List>(method);
      } on PlatformException catch (e) {
        if (e.code == 'IMAGE_CANCELLED') return null;
        throw VaultImageUnreadable(
          e.code == 'NO_IMAGE_SOURCE' || e.code == 'CAMERA_UNAVAILABLE'
              ? VaultImageProblem.noSource
              : VaultImageProblem.unreadable,
        );
      } on MissingPluginException {
        throw const VaultImageUnreadable(VaultImageProblem.unsupported);
      }
    });
  }
}
