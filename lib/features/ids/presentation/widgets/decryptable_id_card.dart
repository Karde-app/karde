import 'dart:async';
import 'dart:convert';
import '../../../../l10n/app_localizations.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/widgets/karde_feedback.dart';
import '../../../../core/widgets/secure_photo_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/security/authentication_service.dart';
import '../../../../core/security/encryption_service.dart';
import '../../../../core/security/system_interaction_guard.dart';
import '../../../../core/security/window_security_service.dart';
import '../../../../core/storage/settings_repository.dart';
import '../../data/id_repository.dart';
import '../../../../core/utils/expiry_capture.dart';
import '../../domain/virtual_id.dart';
import '../id_details_screen.dart';
import 'realistic_id_card.dart';

class DecryptableIdCard extends ConsumerStatefulWidget {
  final VirtualId idDoc;
  final bool disableNavigation;

  /// Handed the fields this widget has just decrypted.
  ///
  /// The eye already pays for a full decrypt, so the detail screen can fill its
  /// "Additional Details" section from that same authentication rather than
  /// raising a second prompt of its own.
  final void Function(Map<String, String> fields)? onRevealed;

  /// Fired when the document re-masks, so the screen re-locks in step with it.
  final VoidCallback? onHidden;

  const DecryptableIdCard({
    super.key,
    required this.idDoc,
    this.disableNavigation = false,
    this.onRevealed,
    this.onHidden,
  });

  @override
  ConsumerState<DecryptableIdCard> createState() => _DecryptableIdCardState();
}

class _DecryptableIdCardState extends ConsumerState<DecryptableIdCard> with WidgetsBindingObserver {
  final _encryptionService = EncryptionService();
  final _windowSecurity = WindowSecurityService();
  final _authService = AuthenticationService();

  bool _isDecrypted = false;
  Map<String, String>? _decryptedData;

  /// The document photo, decoded from the same payload as the fields.
  ///
  /// It arrives with the reveal rather than on a second tap, because it lives in
  /// the same ciphertext — one authentication opens the whole document, picture
  /// included.
  Uint8List? _photo;

  Timer? _hideTimer;

  /// True while anything sensitive is on screen.
  bool get _showingSecrets => _isDecrypted || _photo != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    if (_showingSecrets) {
      _windowSecurity.disableSecureMode();
    }
    // FIX 2-4: drop decrypted ID fields rather than leaving them for the GC.
    _decryptedData = null;
    _photo = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Masking when the app leaves the foreground is the point of this hook:
      // a revealed ID document must not survive into the task switcher.
      //
      // But Karde raising its own BiometricPrompt drives the activity inactive
      // too, and the native success callback fires while that prompt is still
      // dismissing — so the decrypted values arrive BEFORE the pending inactive
      // event reaches Dart. Without this guard that stale event lands after the
      // reveal and masks the ID document again within a second of the user
      // authenticating, which reads as the reveal simply not working.
      // main_scaffold needed the same guard, for the same reason.
      if (SystemInteractionGuard.isActive) return;
      _hideDetails();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    final durationSeconds = ref.read(autoHideDurationProvider);
    _hideTimer = Timer(Duration(seconds: durationSeconds), () {
      if (mounted) {
        _hideDetails();
      }
    });
  }

  void _hideDetails() {
    if (!_showingSecrets) return;
    widget.onHidden?.call();
    setState(() {
      _isDecrypted = false;
      _decryptedData = null;
      _photo = null;
    });
    _windowSecurity.disableSecureMode();
    _hideTimer?.cancel();
  }

  /// Enlarges the already-revealed photo. Costs nothing: the plaintext is here.
  Future<void> _onTapPhoto() async {
    if (_photo == null) return;
    await SecurePhotoView.open(
      context,
      bytes: _photo!,
      title: widget.idDoc.nickname,
    );
    // Looking at it counts as using it, so the auto-hide clock restarts.
    if (mounted) _startHideTimer();
  }

  Future<void> _revealDetails() async {
    final settings = ref.read(settingsRepositoryProvider);
    final authenticated = await _authService.authenticate(context, settings, cryptoWillPrompt: true);
    if (!authenticated) return;

    try {
      // The list does not carry payloads, so fetch this one first. A read by
      // primary key is nothing next to the prompt about to be raised.
      final payload = await ref.read(idRepositoryProvider).payloadFor(widget.idDoc);
      if (payload.isEmpty) throw const VaultCryptoFailure('no payload');

      final decryptedJsonString = await _encryptionService.decrypt(payload);
      final Map<String, dynamic> rawMap = jsonDecode(decryptedJsonString);

      final data = IdPayload.fieldsOf(rawMap);
      final image = IdPayload.imageOf(rawMap);

      if (mounted) {
        setState(() {
          _decryptedData = data;
          _photo = image == null ? null : base64Decode(image);
          _isDecrypted = true;
        });
        _windowSecurity.enableSecureMode();
        _startHideTimer();
        widget.onRevealed?.call(data);

        // See ExpiryCapture. The payload is open, so learning when this document
        // runs out costs nothing on top of the prompt just answered.
        ExpiryCapture.rememberDocument(
          ref,
          documentId: widget.idDoc.id,
          knownExpiry: widget.idDoc.expiresOn,
          rawExpiry: data[ExpiryCapture.documentExpiryField],
        );
      }
    } on VaultAuthCancelled {
      // FIX 4-2: user dismissed the prompt. Stay masked, say nothing.
    } catch (e) {
      // FIX 4-2: was 'Decryption failed: $e', which put a raw PlatformException
      // in front of the user.
      if (mounted) {
        KardeFeedback.error(context, _revealErrorMessage(AppLocalizations.of(context)!, e));
      }
    }
  }

  /// FIX 4-2: actionable message instead of the raw exception.
  String _revealErrorMessage(AppLocalizations loc, Object error) {
    if (error is VaultUnavailable) return loc.unlockNeedsScreenLock;
    if (error is VaultKeyInvalidated) return loc.itemNoLongerDecryptable;
    return loc.couldNotUnlockDocument;
  }

  void _navigateToDetails() {
    if (widget.disableNavigation) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IdDetailsScreen(idDoc: widget.idDoc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToDetails,
      child: RealisticIdCard(
        idDoc: widget.idDoc,
        isDecrypted: _isDecrypted,
        decryptedData: _decryptedData,
        onTapReveal: _revealDetails,
        onTapHide: _hideDetails,
        photo: _photo,
        onTapPhoto: _onTapPhoto,
      ),
    );
  }
}
