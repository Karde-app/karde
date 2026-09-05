import 'package:flutter/material.dart';
import '../widgets/karde_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../l10n/app_localizations.dart';
import '../storage/settings_repository.dart';
import '../../theme/theme.dart';
import '../../features/onboarding/presentation/pin_setup_screen.dart';

class SecurityQuestionsVerificationScreen extends ConsumerStatefulWidget {
  const SecurityQuestionsVerificationScreen({super.key});

  @override
  ConsumerState<SecurityQuestionsVerificationScreen> createState() => _SecurityQuestionsVerificationScreenState();
}

class _SecurityQuestionsVerificationScreenState extends ConsumerState<SecurityQuestionsVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();

  Map<String, String?> _questions = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final settings = ref.read(settingsRepositoryProvider);
    _questions = await settings.getSecurityQuestions();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    // FIX 2-4: security answers are recovery credentials; clear them rather than
    // leaving them in heap memory for the GC to collect whenever it feels like it.
    _answer1Controller.clear();
    _answer2Controller.clear();
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    super.dispose();
  }

  void _onVerify() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = null;
      });

      // FIX 2-3: verify against the stored PBKDF2 hashes.
      //
      // This also repairs a latent bug: this screen used to compare a SHA-256
      // digest of the typed answer against the stored value, but the stored
      // value was raw plaintext. Those could never be equal, so security
      // question recovery could not succeed for anyone.
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final answersMatch = await settingsRepo.verifySecurityAnswers(
        _answer1Controller.text,
        _answer2Controller.text,
      );

      if (answersMatch) {
        // Success
        final settings = ref.read(settingsRepositoryProvider);
        await settings.setFailedAttempts(0);
        await settings.setIsPermanentlyLocked(false);
        await settings.setLockoutUntil(null);

        if (mounted) {
          // FIX 5-2: consistent success feedback.
          KardeFeedback.success(
            context,
            AppLocalizations.of(context)!.resetPinSuccess,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const PinSetupScreen(isResettingPin: true),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.wrongAnswers;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: KardeColors.graphite,
        body: Center(child: CircularProgressIndicator(color: KardeColors.champagneGold)),
      );
    }

    final loc = AppLocalizations.of(context)!;
    final q1 = _questions['q1'] ?? '';
    final q2 = _questions['q2'] ?? '';

    return Scaffold(
      backgroundColor: KardeColors.graphite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            children: [
              const SizedBox(height: 20),
              Text(
                loc.verifyQuestionsTitle,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.verifyQuestionsSubtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              _buildQuestionBlock(loc.question1, q1, _answer1Controller, loc),
              const SizedBox(height: 32),
              _buildQuestionBlock(loc.question2, q2, _answer2Controller, loc),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KardeColors.champagneGold,
                    foregroundColor: KardeColors.graphite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                     loc.verifyBtn,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionBlock(String label, String question, TextEditingController controller, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Colors.white54,
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          question,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
          decoration: InputDecoration(
            labelText: loc.answer,
            labelStyle: const TextStyle(color: Colors.white54, fontFamily: 'Inter'),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return loc.answerRequired;
            }
            return null;
          },
        ),
      ],
    );
  }
}
