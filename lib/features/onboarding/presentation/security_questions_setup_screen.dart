import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../../l10n/app_localizations.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../theme/theme.dart';
import '../../home/presentation/main_scaffold.dart';

class SecurityQuestionsSetupScreen extends ConsumerStatefulWidget {
  const SecurityQuestionsSetupScreen({super.key});

  @override
  ConsumerState<SecurityQuestionsSetupScreen> createState() => _SecurityQuestionsSetupScreenState();
}

class _SecurityQuestionsSetupScreenState extends ConsumerState<SecurityQuestionsSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedQ1;
  String? _selectedQ2;
  
  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();

  final List<String> _questions = [
    "What was the name of your first pet?",
    "What is your mother's maiden name?",
    "What was the name of your elementary school?",
    "In what city were you born?",
    "What was the make of your first car?",
    "What is your favorite book?",
  ];

  @override
  void dispose() {
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    super.dispose();
  }

  String _hashAnswer(String answer) {
    // Normalize string (lowercase, trim whitespace) before hashing
    final normalized = answer.trim().toLowerCase();
    final bytes = utf8.encode(normalized);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _onFinishSetup() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedQ1 == null || _selectedQ2 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select two questions')),
        );
        return;
      }

      if (_selectedQ1 == _selectedQ2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select two different questions')),
        );
        return;
      }

      final hashedA1 = _hashAnswer(_answer1Controller.text);
      final hashedA2 = _hashAnswer(_answer2Controller.text);

      final settings = ref.read(settingsRepositoryProvider);
      await settings.setSecurityQuestions(_selectedQ1!, hashedA1, _selectedQ2!, hashedA2);
      await settings.setIsFirstLaunch(false);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScaffold()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: KardeColors.graphite,
      appBar: AppBar(
        backgroundColor: KardeColors.graphite,
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
            padding: const EdgeInsets.all(24.0),
            children: [
              Text(
                loc.setupQuestionsTitle,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.setupQuestionsSubtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              
              _buildDropdown(loc.question1, _selectedQ1, (val) {
                setState(() => _selectedQ1 = val);
              }),
              const SizedBox(height: 16),
              _buildTextField(loc.answer, _answer1Controller, loc),
              
              const SizedBox(height: 32),
              
              _buildDropdown(loc.question2, _selectedQ2, (val) {
                setState(() => _selectedQ2 = val);
              }),
              const SizedBox(height: 16),
              _buildTextField(loc.answer, _answer2Controller, loc),
              
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: _onFinishSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KardeColors.champagneGold,
                  foregroundColor: KardeColors.graphite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  loc.finishSetup,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, ValueChanged<String?> onChanged) {
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
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          dropdownColor: KardeColors.obsidian,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 14,
          ),
          items: _questions.map((q) {
            return DropdownMenuItem(
              value: q,
              child: Text(q, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, AppLocalizations loc) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
      decoration: InputDecoration(
        labelText: label,
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
    );
  }
}
