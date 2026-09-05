import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/karde_feedback.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/security/authentication_service.dart';
import '../../../../core/security/encryption_service.dart';
import '../../../../core/security/system_interaction_guard.dart';
import '../../../../core/security/window_security_service.dart';
import '../../../../core/storage/settings_repository.dart';
import '../../data/card_repository.dart';
import '../../domain/virtual_card.dart';
import '../card_details_screen.dart';
import 'realistic_card.dart';

class DecryptableCard extends ConsumerStatefulWidget {
  final VirtualCard card;
  final bool disableNavigation;

  /// Handed the secrets this widget has just decrypted.
  ///
  /// The eye already pays for a full decrypt — notes and photo included, since
  /// Phase 7a moved them into the same payload — so the detail screen can fill
  /// its own sections from that one authentication instead of asking again.
  final void Function(CardSecrets secrets)? onRevealed;

  /// Fired when the card re-masks, so the screen re-locks in step with it.
  final VoidCallback? onHidden;

  const DecryptableCard({
    super.key,
    required this.card,
    this.disableNavigation = false,
    this.onRevealed,
    this.onHidden,
  });

  @override
  ConsumerState<DecryptableCard> createState() => _DecryptableCardState();
}

class _DecryptableCardState extends ConsumerState<DecryptableCard> with WidgetsBindingObserver {
  final _encryptionService = EncryptionService();
  final _windowSecurity = WindowSecurityService();
  final _authService = AuthenticationService();
  
  bool _isDecrypted = false;
  String? _cardNumber;
  String? _expiry;
  String? _cvv;
  String? _cardholderName;
  
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // FIX 2-1: the cardholder name is NO LONGER decrypted here. The vault key
    // now requires authentication for every use, so eagerly decrypting on build
    // would fire one OS prompt per card just to render the vault list — and it
    // put real PII on screen before the user had authenticated at all. The name
    // is revealed only via _revealDetails().
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    if (_isDecrypted) {
      _windowSecurity.disableSecureMode();
    }
    // FIX 2-4: drop decrypted secrets rather than leaving them for the GC.
    _cardNumber = null;
    _expiry = null;
    _cvv = null;
    _cardholderName = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Masking when the app leaves the foreground is the point of this hook:
      // a revealed card must not survive into the task switcher.
      //
      // But Karde raising its own BiometricPrompt drives the activity inactive
      // too, and the native success callback fires while that prompt is still
      // dismissing — so the decrypted values arrive BEFORE the pending inactive
      // event reaches Dart. Without this guard that stale event lands after the
      // reveal and masks the card again within a second of the user
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
    if (!_isDecrypted) return;
    widget.onHidden?.call();
    setState(() {
      _isDecrypted = false;
      _cardNumber = null;
      _expiry = null;
      _cvv = null;
      // The cardholder name is decrypted PII too. Leaving it set meant that
      // after auto-hide the number re-masked but the real name stayed on screen.
      _cardholderName = null;
    });
    _windowSecurity.disableSecureMode();
    _hideTimer?.cancel();
  }

  Future<void> _revealDetails() async {
    final settings = ref.read(settingsRepositoryProvider);
    final authenticated = await _authService.authenticate(context, settings, cryptoWillPrompt: true);
    if (!authenticated) return;

    try {
      // The list does not carry payloads, so fetch this one first. A read by
      // primary key is nothing next to the prompt about to be raised.
      final payload = await ref.read(cardRepositoryProvider).payloadFor(widget.card);
      if (payload.isEmpty) throw const VaultCryptoFailure('no payload');

      // FIX 2-1: a single authenticated decrypt yields every field — and, now
      // that the photo travels in the same payload, the picture along with them.
      final secrets = CardSecrets.fromJson(
        await _encryptionService.decrypt(payload),
      );

      if (mounted) {
        setState(() {
          _cardNumber = secrets.cardNumber;
          _expiry = secrets.expiry;
          _cvv = secrets.cvv;
          _cardholderName = secrets.cardholderName;
          _isDecrypted = true;
        });
        _windowSecurity.enableSecureMode();
        _startHideTimer();
        widget.onRevealed?.call(secrets);
      }
    } on VaultAuthCancelled {
      // FIX 4-2: user dismissed the prompt. Stay masked, say nothing.
    } catch (e) {
      if (mounted) {
        KardeFeedback.error(context, _revealErrorMessage(AppLocalizations.of(context)!, e));
      }
    }
  }

  /// FIX 4-2: previously surfaced the raw exception text to the user.
  String _revealErrorMessage(AppLocalizations loc, Object error) {
    if (error is VaultUnavailable) return loc.unlockNeedsScreenLock;
    if (error is VaultKeyInvalidated) return loc.itemNoLongerDecryptable;
    return loc.couldNotUnlockCard;
  }

  void _copyToClipboard() {
    if (_cardNumber == null) return;
    Clipboard.setData(ClipboardData(text: _cardNumber!));
    KardeFeedback.success(context, AppLocalizations.of(context)!.cardNumberCopied);
    
    // Clear clipboard after 60 seconds
    Timer(const Duration(seconds: 60), () async {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null && clipboardData.text == _cardNumber) {
        Clipboard.setData(const ClipboardData(text: ''));
      }
    });
    
    _startHideTimer(); // Reset timer on interaction
  }

  void _navigateToDetails() {
    if (widget.disableNavigation) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardDetailsScreen(card: widget.card),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToDetails,
      child: RealisticCard(
        card: widget.card,
        isDecrypted: _isDecrypted,
        decryptedCardNumber: _cardNumber,
        decryptedExpiry: _expiry,
        decryptedCvv: _cvv,
        decryptedCardholderName: _cardholderName,
        onTapReveal: _revealDetails,
        onTapHide: _hideDetails,
        onCopy: _copyToClipboard,
      ),
    );
  }
}
