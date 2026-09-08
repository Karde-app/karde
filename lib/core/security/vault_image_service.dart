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

  /// Opens the phone's own camera app. Returns null if the user backed out.
  ///
  /// Still here, and still needed. It is what Karde falls back to when somebody
  /// refuses the camera permission that [GuidedCameraScreen] asks for — an
  /// `ACTION_IMAGE_CAPTURE` needs no permission from Karde at all, so refusing
  /// costs the guide rectangle and nothing else.
  Future<Uint8List?> captureWithCamera() => _source('captureImage');

  /// Turns the file Karde's own camera just wrote into the picture to show the
  /// user: upright, downscaled and stripped of EXIF, including the GPS
  /// coordinates a phone writes into a photo, which on an ID document would
  /// record where its owner lives.
  ///
  /// The file stays on disk until [cropCapture] or [discardCapture] deals with
  /// it, so the final crop can be taken from the full-resolution original.
  Future<Uint8List> prepareCapture(String path) async {
    try {
      final bytes = await _pickerChannel
          .invokeMethod<Uint8List>('prepareCapture', {'path': path});
      if (bytes == null) {
        throw const VaultImageUnreadable(VaultImageProblem.unreadable);
      }
      return bytes;
    } on PlatformException {
      throw const VaultImageUnreadable(VaultImageProblem.unreadable);
    }
  }

  /// Deletes a capture the user rejected. A full-resolution photograph of
  /// somebody's passport must not be left sitting in the cache.
  Future<void> discardCapture(String path) async {
    try {
      await _pickerChannel.invokeMethod<void>('discardCapture', {'path': path});
    } on PlatformException {
      // Nothing useful to say: the file is either gone or was never there.
    }
  }

  /// Keeps the part of the photo the user drew a rectangle around.
  ///
  /// The rectangle is given as fractions of the **finished, upright photograph**
  /// — the one [prepareCapture] returned and the user then framed by hand — not
  /// of the camera preview. Comes back downscaled, re-compressed and stripped of
  /// EXIF like everything else here.
  Future<Uint8List> cropCapture({
    required String path,
    required double left,
    required double top,
    required double width,
    required double height,
  }) async {
    try {
      final bytes = await _pickerChannel.invokeMethod<Uint8List>('cropCapture', {
        'path': path,
        'left': left,
        'top': top,
        'width': width,
        'height': height,
      });
      if (bytes == null) {
        throw const VaultImageUnreadable(VaultImageProblem.unreadable);
      }
      return bytes;
    } on PlatformException {
      throw const VaultImageUnreadable(VaultImageProblem.unreadable);
    }
  }

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
