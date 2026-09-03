import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/security/authentication_service.dart';
import '../../../../core/security/encryption_service.dart';
import '../../../../core/security/window_security_service.dart';
import '../../../../core/storage/settings_repository.dart';
import '../../domain/virtual_card.dart';
import '../card_details_screen.dart';
import 'realistic_card.dart';

class DecryptableCard extends ConsumerStatefulWidget {
  final VirtualCard card;
  final bool disableNavigation;

  const DecryptableCard({super.key, required this.card, this.disableNavigation = false});

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
    _loadCardholderName();
  }

  Future<void> _loadCardholderName() async {
    try {
      final name = await _encryptionService.decrypt(widget.card.encryptedCardholderName);
      if (mounted) {
        setState(() {
          _cardholderName = name;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    if (_isDecrypted) {
      _windowSecurity.disableSecureMode();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
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
    setState(() {
      _isDecrypted = false;
      _cardNumber = null;
      _expiry = null;
      _cvv = null;
    });
    _windowSecurity.disableSecureMode();
    _hideTimer?.cancel();
  }

  Future<void> _revealDetails() async {
    final settings = ref.read(settingsRepositoryProvider);
    final authenticated = await _authService.authenticate(context, settings);
    if (!authenticated) return;

    try {
      final cardNumber = await _encryptionService.decrypt(widget.card.encryptedCardNumber);
      final expiry = await _encryptionService.decrypt(widget.card.encryptedExpiry);
      final cvv = await _encryptionService.decrypt(widget.card.encryptedCvv);
      final cardholderName = await _encryptionService.decrypt(widget.card.encryptedCardholderName);

      if (mounted) {
        setState(() {
          _cardNumber = cardNumber;
          _expiry = expiry;
          _cvv = cvv;
          _isDecrypted = true;
        });
        _windowSecurity.enableSecureMode();
        _startHideTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Decryption failed: $e')),
        );
      }
    }
  }

  void _copyToClipboard() {
    if (_cardNumber == null) return;
    Clipboard.setData(ClipboardData(text: _cardNumber!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Card number copied to clipboard')),
    );
    
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
