import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../security/system_interaction_guard.dart';
import '../security/window_security_service.dart';
import '../storage/settings_repository.dart';

/// Full-screen viewer for a decrypted document or card photo.
///
/// A photo of a passport is the single most sensitive thing this app can put on
/// screen, so it is treated like a revealed card rather than like an image: the
/// window is marked secure for as long as it is up, it closes itself on the same
/// auto-hide timer the user configured in Settings, and it closes immediately if
/// the app leaves the foreground.
///
/// The bytes are handed in already decrypted. This widget deliberately cannot
/// reach the vault, so opening the viewer can never cost an authentication
/// prompt the caller did not intend.
class SecurePhotoView extends ConsumerStatefulWidget {
  final Uint8List bytes;
  final String title;

  const SecurePhotoView({super.key, required this.bytes, required this.title});

  static Future<void> open(
    BuildContext context, {
    required Uint8List bytes,
    required String title,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SecurePhotoView(bytes: bytes, title: title),
      ),
    );
  }

  @override
  ConsumerState<SecurePhotoView> createState() => _SecurePhotoViewState();
}

class _SecurePhotoViewState extends ConsumerState<SecurePhotoView>
    with WidgetsBindingObserver {
  final _windowSecurity = WindowSecurityService();
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _windowSecurity.enableSecureMode();
    _hideTimer = Timer(
      Duration(seconds: ref.read(autoHideDurationProvider)),
      _closeIfOpen,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _windowSecurity.disableSecureMode();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.inactive &&
        state != AppLifecycleState.paused) {
      return;
    }
    // Karde raising its own system UI drives the activity inactive too, and that
    // event can arrive after the work it belongs to has already finished. Closing
    // on it would look to the user like the viewer refusing to stay open. Same
    // guard, same reason, as in `decryptable_card`.
    if (SystemInteractionGuard.isActive) return;
    _closeIfOpen();
  }

  void _closeIfOpen() {
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 18),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Image.memory(
            widget.bytes,
            fit: BoxFit.contain,
            // A stored photo that will not decode is a damaged file, not a crash.
            errorBuilder: (context, error, stack) => const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'This photo could not be displayed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontFamily: 'Inter'),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            'Closes automatically. Screenshots are blocked.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
