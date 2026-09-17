import 'dart:async';
import 'dart:io';
import '../../l10n/app_localizations.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(
      Duration(seconds: ref.read(autoHideDurationProvider)),
      _closeIfOpen,
    );
  }

  /// Hands a copy of the photo to an app the user picks.
  ///
  /// Testers needed this: a hotel or an employer asks for a passport photo and
  /// the only copy is in Karde, which blocks screenshots. Share is the right
  /// shape for that and "Save to gallery" is not — the gallery syncs to cloud
  /// photo services on most phones, which would quietly put an unencrypted
  /// passport in exactly the place Karde exists to keep it out of. The share
  /// sheet still offers "save to files" for anyone who genuinely wants that, but
  /// as their explicit choice of destination rather than a button here.
  ///
  /// The share sheet is another app's window, so the call runs inside
  /// [SystemInteractionGuard] — otherwise the vault would lock behind it and
  /// this viewer would close under the user. The auto-hide timer is paused for
  /// the same reason and restarted afterwards.
  ///
  /// share_plus keeps its own copy of the file in a cache folder and only
  /// clears it on the *next* share. A passport photo must not sit there, so
  /// the folder is wiped the moment the sheet closes, whatever the outcome.
  Future<void> _share() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.sharePhotoConfirmTitle),
        content: Text(loc.sharePhotoConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.sharePhotoConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _hideTimer?.cancel();
    try {
      await SystemInteractionGuard.run(() async {
        await Share.shareXFiles([
          XFile.fromData(
            widget.bytes,
            mimeType: 'image/jpeg',
            name: 'document.jpg',
          ),
        ]);
      });
    } finally {
      await _wipeShareCache();
      if (mounted) _startHideTimer();
    }
  }

  static Future<void> _wipeShareCache() async {
    try {
      final cache = await getTemporaryDirectory();
      final dir = Directory('${cache.path}${Platform.pathSeparator}share_plus');
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {
      // Nothing useful to say: the folder is either gone or was never written.
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: AppLocalizations.of(context)!.sharePhoto,
            onPressed: _share,
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Image.memory(
            widget.bytes,
            fit: BoxFit.contain,
            // A stored photo that will not decode is a damaged file, not a crash.
            errorBuilder: (context, error, stack) => Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                AppLocalizations.of(context)!.photoCouldNotBeDisplayed,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontFamily: 'Inter'),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            AppLocalizations.of(context)!.photoClosesAutomatically,
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
