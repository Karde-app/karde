import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../storage/settings_repository.dart';
import 'secret_hasher.dart';
import '../../features/onboarding/presentation/pin_setup_screen.dart';
import 'forgot_pin_screen.dart';

class PinVerificationScreen extends ConsumerStatefulWidget {
  final String? customSubtitle;
  const PinVerificationScreen({super.key, this.customSubtitle});

  @override
  ConsumerState<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends ConsumerState<PinVerificationScreen> {
  String _pin = '';
  String? _errorMessage;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  Timer? _lockoutTimer;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLockoutState();
    });
  }

  void _loadLockoutState() {
    final settings = ref.read(settingsRepositoryProvider);
    setState(() {
      _failedAttempts = settings.getFailedAttempts();
      _lockoutUntil = settings.getLockoutUntil();
    });

    _checkLockoutTimer();
  }

  /// How long to wait after [attempts] wrong PINs.
  ///
  /// Karde used to lock itself **permanently** after five, and the only way past
  /// that was to erase the vault. It was reachable by accident: the count was
  /// only cleared when a lockout timer ran down, so closing the app during a
  /// thirty-second wait carried three failures forward, and two more mistyped
  /// PINs destroyed the way in to somebody's own cards. Anyone who had chosen no
  /// recovery method at onboarding had nothing to fall back on.
  ///
  /// It also bought very little. The Karde PIN guards a screen; it does not
  /// guard the items, which each need the phone's own fingerprint or screen lock
  /// to open, every single time. Waiting an hour between guesses already makes a
  /// four-digit PIN impractical to work through by hand, and it cannot lose
  /// anybody their vault.
  static Duration? _waitAfter(int attempts) {
    if (attempts < 3) return null;
    switch (attempts) {
      case 3:
        return const Duration(seconds: 30);
      case 4:
        return const Duration(minutes: 2);
      case 5:
        return const Duration(minutes: 10);
      case 6:
        return const Duration(minutes: 30);
      default:
        return const Duration(hours: 1);
    }
  }

  void _checkLockoutTimer() {
    _lockoutTimer?.cancel();
    if (_lockoutUntil != null) {
      _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        final now = DateTime.now();
        if (_lockoutUntil!.isAfter(now)) {
          setState(() => _errorMessage = _waitMessage(_lockoutUntil!.difference(now)));
        } else {
          timer.cancel();
          setState(() {
            _lockoutUntil = null;
            _errorMessage = null;
          });
          // The count deliberately survives the wait. Clearing it here is what
          // made the escalation above impossible and the permanent lock
          // reachable: every wait reset the tally, so the app could only ever
          // count to three, and the leftover state did the rest. Only a correct
          // PIN clears it now.
          ref.read(settingsRepositoryProvider).setLockoutUntil(null);
        }
      });
    }
  }

  /// "Try again in 20 seconds" or "Try again in 5 minutes".
  ///
  /// Seconds are unreadable past a minute — nobody counts down from 3600 — so
  /// anything longer is rounded up to whole minutes.
  String _waitMessage(Duration left) {
    final loc = AppLocalizations.of(context)!;
    if (left.inSeconds < 60) {
      return loc.pinLockedTryAgainIn(left.inSeconds);
    }
    return loc.pinLockedTryAgainInMinutes((left.inSeconds / 60).ceil());
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_lockoutUntil != null) return;
    if (_pin.length >= 4) return;

    setState(() {
      _errorMessage = null;
      _pin += digit;
    });

    // Let the fourth dot actually appear before the PIN is judged.
    //
    // Validating inside setState filled and cleared that dot in the same
    // breath, so the pad looked unresponsive on the last digit — and the
    // natural reaction, pressing it again, spends one of the five attempts
    // before the permanent lockout.
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) _validatePin();
      });
    }
  }

  void _onDeletePressed() {
    if (_lockoutUntil != null) return;
    setState(() {
      _errorMessage = null;
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _validatePin() async {
    if (_lockoutUntil != null) return;

    final settings = ref.read(settingsRepositoryProvider);
    final storedHash = await settings.getHashedPin();

    // No PIN has ever been created, so there is nothing any input could match.
    // Counting these as failed attempts marched the user toward the permanent
    // lock for a PIN that never existed. Send them to set one instead.
    if (storedHash == null || storedHash.isEmpty) {
      if (!mounted) return;
      setState(() => _pin = '');
      final created = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const PinSetupScreen(isResettingPin: true),
        ),
      );
      if (created == true && mounted) Navigator.pop(context, true);
      return;
    }

    // FIX 2-2: salted PBKDF2 verification, constant-time compared. Any PIN
    // stored by an older build used a bare SHA-256 digest and will not verify,
    // which is intended — those users are sent through PIN re-setup.
    if (SecretHasher.verify(_pin, storedHash)) {
      await settings.setFailedAttempts(0);
      await settings.setLockoutUntil(null);
      if (mounted) Navigator.pop(context, true);
    } else {
      _failedAttempts++;
      await settings.setFailedAttempts(_failedAttempts);

      final wait = _waitAfter(_failedAttempts);
      setState(() {
        if (wait != null) {
          _lockoutUntil = DateTime.now().add(wait);
          settings.setLockoutUntil(_lockoutUntil);
          _errorMessage = _waitMessage(wait);
          _checkLockoutTimer();
        } else {
          // No countdown of remaining attempts any more, because there is no
          // longer a number to count down to. "Wrong PIN" is the whole truth.
          _errorMessage = AppLocalizations.of(context)!.pinInvalid;
        }
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
            const SizedBox(height: 20),
            Text(
              loc.enterKardePin,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.customSubtitle ?? loc.unlockToReveal,
              style: TextStyle(
                fontFamily: 'Inter',
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 24,
                  height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? Theme.of(context).primaryColor : Colors.transparent,
                      border: Border.all(
                        color: isFilled ? Theme.of(context).primaryColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38),
                        width: 2,
                      ),
                    ),
                );
              }),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.redAccent,
                  fontSize: 14,
                ),
              ),
            ],
            const Spacer(),
            _buildDialPad(),
            const SizedBox(height: 16),
            _buildForgotPinBtn(loc),
            const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDialPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['1', '2', '3'].map((d) => _buildDialButton(d)).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['4', '5', '6'].map((d) => _buildDialButton(d)).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['7', '8', '9'].map((d) => _buildDialButton(d)).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72, height: 72),
              _buildDialButton('0'),
              _buildDeleteButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPinBtn(AppLocalizations loc) {
    return TextButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPinScreen()));
      },
      child: Text(
        loc.forgotPin,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: KardeColors.champagneGold,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDialButton(String digit) {
    final isDisabled = _lockoutUntil != null;
    // FIX 6-1: the dial pad was an InkWell wrapping bare Text, so TalkBack read
    // out a floating digit with no indication it was a button or what it did.
    return Semantics(
      label: AppLocalizations.of(context)!.pinDigitSemantic(digit),
      button: true,
      enabled: !isDisabled,
      excludeSemantics: true,
      child: InkWell(
        onTap: isDisabled ? null : () => _onDigitPressed(digit),
        borderRadius: BorderRadius.circular(36),
        child: Opacity(
          opacity: isDisabled ? 0.3 : 1.0,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            ),
            alignment: Alignment.center,
            child: Text(
              digit,
              style: TextStyle(
                fontFamily: 'Inter',
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    final isDisabled = _lockoutUntil != null;
    // FIX 6-1: the delete key had no semantic label at all — screen readers
    // announced nothing.
    return Semantics(
      label: AppLocalizations.of(context)!.deleteLastDigit,
      button: true,
      enabled: !isDisabled,
      excludeSemantics: true,
      child: InkWell(
        onTap: isDisabled ? null : _onDeletePressed,
        borderRadius: BorderRadius.circular(36),
        child: Opacity(
          opacity: isDisabled ? 0.3 : 1.0,
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            child: Icon(
              Icons.backspace_outlined,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
