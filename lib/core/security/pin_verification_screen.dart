import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../storage/settings_repository.dart';
import 'forgot_pin_screen.dart';

class PinVerificationScreen extends ConsumerStatefulWidget {
  const PinVerificationScreen({super.key});

  @override
  ConsumerState<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends ConsumerState<PinVerificationScreen> {
  String _pin = '';
  String? _errorMessage;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  Timer? _lockoutTimer;
  bool _isPermanentlyLocked = false;

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
      _isPermanentlyLocked = settings.getIsPermanentlyLocked();
    });
    
    if (_isPermanentlyLocked && mounted) {
      // Must wait for context to get AppLocalizations
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.maxAttemptsReached;
        });
      });
    }

    _checkLockoutTimer();
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
          setState(() {
            final secondsLeft = _lockoutUntil!.difference(now).inSeconds;
            _errorMessage = 'Too many failed attempts. Try again in ${secondsLeft}s.';
          });
        } else {
          timer.cancel();
          setState(() {
            _lockoutUntil = null;
            _failedAttempts = 0;
            _errorMessage = null;
          });
          final settings = ref.read(settingsRepositoryProvider);
          settings.setFailedAttempts(0);
          settings.setLockoutUntil(null);
        }
      });
    }
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_lockoutUntil != null || _isPermanentlyLocked) return;
    setState(() {
      _errorMessage = null;
      if (_pin.length < 4) _pin += digit;
      if (_pin.length == 4) {
        _validatePin();
      }
    });
  }

  void _onDeletePressed() {
    if (_lockoutUntil != null || _isPermanentlyLocked) return;
    setState(() {
      _errorMessage = null;
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _validatePin() async {
    if (_lockoutUntil != null || _isPermanentlyLocked) return;

    final settings = ref.read(settingsRepositoryProvider);
    final storedPin = await settings.getHashedPin();
    
    if (storedPin == _pin) {
      await settings.setFailedAttempts(0);
      await settings.setLockoutUntil(null);
      if (mounted) Navigator.pop(context, true);
    } else {
      _failedAttempts++;
      await settings.setFailedAttempts(_failedAttempts);
      
      setState(() {
        if (_failedAttempts >= 5) {
          _isPermanentlyLocked = true;
          settings.setIsPermanentlyLocked(true);
          _errorMessage = AppLocalizations.of(context)!.maxAttemptsReached;
        } else if (_failedAttempts == 3) {
          _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
          settings.setLockoutUntil(_lockoutUntil);
          _errorMessage = 'Too many failed attempts. Locked out for 30 seconds.';
          _checkLockoutTimer();
        } else {
          final attemptsLeft = 5 - _failedAttempts;
          _errorMessage = 'Invalid PIN. $attemptsLeft attempts left.';
        }
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: KardeColors.graphite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
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
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.unlockToReveal,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Colors.white70,
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
                    color: isFilled ? KardeColors.champagneGold : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? KardeColors.champagneGold : Colors.white38,
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
    final isDisabled = _lockoutUntil != null || _isPermanentlyLocked;
    return InkWell(
      onTap: isDisabled ? null : () => _onDigitPressed(digit),
      borderRadius: BorderRadius.circular(36),
      child: Opacity(
        opacity: isDisabled ? 0.3 : 1.0,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
          ),
          alignment: Alignment.center,
          child: Text(
            digit,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    final isDisabled = _lockoutUntil != null || _isPermanentlyLocked;
    return InkWell(
      onTap: isDisabled ? null : _onDeletePressed,
      borderRadius: BorderRadius.circular(36),
      child: Opacity(
        opacity: isDisabled ? 0.3 : 1.0,
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          child: const Icon(
            Icons.backspace_outlined,
            color: Colors.white70,
            size: 28,
          ),
        ),
      ),
    );
  }
}
