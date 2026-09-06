import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../core/security/secret_hasher.dart';
import '../../../theme/theme.dart';
import '../../home/presentation/main_scaffold.dart';
import 'recovery_setup_screen.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  final bool isResettingPin;
  final bool isChangingPin;
  const PinSetupScreen({super.key, this.isResettingPin = false, this.isChangingPin = false});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;

  /// Whether a Karde PIN already existed when this screen opened.
  ///
  /// Read before anything is saved, because saving is what makes the answer
  /// change. It decides one thing: whether the confirmation says the PIN was
  /// created or changed. Settings reaches this screen for both, and telling
  /// someone their PIN was "successfully changed" moments after they set their
  /// first one describes something that did not happen.
  bool _hadPin = false;

  @override
  void initState() {
    super.initState();
    _loadHadPin();
  }

  Future<void> _loadHadPin() async {
    final hadPin = await ref.read(settingsRepositoryProvider).hasKardePin();
    if (mounted) setState(() => _hadPin = hadPin);
  }

  void _onDigitPressed(String digit) {
    // Same reason as the verification pad: the fourth dot has to be seen
    // before anything acts on it, or the pad reads as unresponsive.
    if (!_isConfirming) {
      if (_pin.length >= 4) return;
      setState(() {
        _errorMessage = null;
        _pin += digit;
      });
      if (_pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 180), () {
          if (mounted) setState(() => _isConfirming = true);
        });
      }
    } else {
      if (_confirmPin.length >= 4) return;
      setState(() {
        _errorMessage = null;
        _confirmPin += digit;
      });
      if (_confirmPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 180), () {
          if (mounted) _validatePin();
        });
      }
    }
  }

  void _onDeletePressed() {
    setState(() {
      _errorMessage = null;
      if (!_isConfirming) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        else _isConfirming = false; // Go back to first step
      }
    });
  }

  Future<void> _validatePin() async {
    if (_pin == _confirmPin) {
      // PINs match — hash and save
      final settings = ref.read(settingsRepositoryProvider);
      // FIX 2-2: salted PBKDF2 instead of a bare unsalted SHA-256 digest.
      await settings.setHashedPin(SecretHasher.hash(_pin));

      if (!mounted) return;
      if (widget.isChangingPin) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? KardeColors.graphite 
                    : KardeColors.lightSurface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: KardeColors.champagneGold.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: KardeColors.champagneGold.withOpacity(0.1),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KardeColors.signalTeal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: KardeColors.signalTeal, size: 48),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _hadPin
                        ? AppLocalizations.of(context)!.pinChangedSuccess
                        : AppLocalizations.of(context)!.pinCreatedSuccess,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hadPin
                        ? AppLocalizations.of(context)!.vaultUpdatedWithNewPin
                        : AppLocalizations.of(context)!.vaultReadyWithNewPin,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // close dialog
                        Navigator.pop(context); // close PinSetupScreen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KardeColors.champagneGold,
                        foregroundColor: KardeColors.obsidian,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.done,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (widget.isResettingPin) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScaffold()),
          (route) => false,
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RecoverySetupScreen()),
        );
      }
    } else {
      // Mismatch
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.pinMismatch;
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currentPin = _isConfirming ? _confirmPin : _pin;
    final title = _isConfirming ? loc.confirmPin : ((widget.isResettingPin || widget.isChangingPin) ? loc.createKardePin : loc.createPin);
    final subtitle = _isConfirming ? loc.reEnterPin : loc.enterPin;

    return Scaffold(
      backgroundColor: KardeColors.graphite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
            const SizedBox(height: 60),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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
                final isFilled = index < currentPin.length;
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
            const SizedBox(height: 40),
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
              const SizedBox(width: 72, height: 72), // Empty space
              _buildDialButton('0'),
              _buildDeleteButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDialButton(String digit) {
    return InkWell(
      onTap: () => _onDigitPressed(digit),
      borderRadius: BorderRadius.circular(36),
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
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: _onDeletePressed,
      borderRadius: BorderRadius.circular(36),
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
    );
  }
}
