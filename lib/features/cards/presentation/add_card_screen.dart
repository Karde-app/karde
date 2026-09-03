import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/security/encryption_service.dart';
import '../data/card_repository.dart';
import '../domain/virtual_card.dart';
import '../../../theme/theme.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  final VirtualCard? existingCard;

  const AddCardScreen({super.key, this.existingCard});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _CardFormatter {
  static String formatCardNumber(String text) {
    text = text.replaceAll(' ', '');
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  static bool isValidLuhn(String cardNumber) {
    if (cardNumber.isEmpty) return false;
    int sum = 0;
    bool isSecond = false;
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      final char = cardNumber[i];
      if (char.codeUnitAt(0) < 48 || char.codeUnitAt(0) > 57) return false; // Not a digit
      int d = int.parse(char);
      if (isSecond) {
        d = d * 2;
      }
      sum += d ~/ 10;
      sum += d % 10;
      isSecond = !isSecond;
    }
    return (sum % 10 == 0);
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    // If backspacing, just let it happen naturally
    if (oldValue.text.length > newValue.text.length) {
      return newValue;
    }

    // Allow digits and slashes
    var cleanText = text.replaceAll(RegExp(r'[^0-9/]'), '');
    
    // If the user manually types "1/" (or any single digit followed by slash), make it "01/"
    if (cleanText.length == 2 && cleanText.endsWith('/')) {
      cleanText = '0${cleanText[0]}/';
    }

    // Remove all slashes for processing
    cleanText = cleanText.replaceAll('/', '');

    String formatted = '';
    for (int i = 0; i < cleanText.length; i++) {
      if (i == 2) {
        formatted += '/';
      }
      formatted += cleanText[i];
    }

    // If exactly 2 digits are entered, append the slash immediately
    if (cleanText.length == 2 && !formatted.endsWith('/')) {
      formatted += '/';
    }

    // Limit to 5 characters (MM/YY)
    if (formatted.length > 5) {
      formatted = formatted.substring(0, 5);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _encryptionService = EncryptionService();

  late final TextEditingController _nicknameController;
  late final TextEditingController _cardBrandController;
  late final TextEditingController _cardNumberController;
  late final TextEditingController _expiryController;
  late final TextEditingController _cvvController;
  late final TextEditingController _cardholderNameController;
  late final TextEditingController _notesController;

  bool _isSaving = false;
  bool _isLoadingExisting = false;
  bool _obscureCvv = true;
  bool _isCustomBrand = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.existingCard?.nickname ?? '');
    
    final initialBrand = widget.existingCard?.cardBrand ?? 'VISA';
    if (!['VISA', 'Mastercard', 'AMEX', 'Discover'].contains(initialBrand)) {
      _isCustomBrand = true;
      _cardBrandController = TextEditingController(text: initialBrand);
    } else {
      _cardBrandController = TextEditingController(text: initialBrand);
    }
    
    _cardNumberController = TextEditingController();
    _expiryController = TextEditingController();
    _cvvController = TextEditingController();
    _cardholderNameController = TextEditingController();
    _notesController = TextEditingController();

    if (widget.existingCard != null) {
      _loadExistingCardDetails();
    }
  }

  Future<void> _loadExistingCardDetails() async {
    setState(() => _isLoadingExisting = true);
    try {
      final card = widget.existingCard!;
      final cardNumber = await _encryptionService.decrypt(card.encryptedCardNumber);
      final expiry = await _encryptionService.decrypt(card.encryptedExpiry);
      final cvv = await _encryptionService.decrypt(card.encryptedCvv);
      final cardholder = await _encryptionService.decrypt(card.encryptedCardholderName);
      final notes = await _encryptionService.decrypt(card.encryptedNotes);

      if (mounted) {
        _cardNumberController.text = _CardFormatter.formatCardNumber(cardNumber);
        _expiryController.text = expiry;
        _cvvController.text = cvv;
        _cardholderNameController.text = cardholder;
        _notesController.text = notes;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to decrypt existing card data.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingExisting = false);
      }
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _cardBrandController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final rawCardNumber = _cardNumberController.text.replaceAll(' ', '');
      
      final encryptedCardNumber = await _encryptionService.encrypt(rawCardNumber);
      final encryptedExpiry = await _encryptionService.encrypt(_expiryController.text);
      final encryptedCvv = await _encryptionService.encrypt(_cvvController.text);
      final encryptedCardholderName = await _encryptionService.encrypt(_cardholderNameController.text);
      final encryptedNotes = await _encryptionService.encrypt(_notesController.text);
      
      final lastFourDigits = rawCardNumber.length >= 4 
          ? rawCardNumber.substring(rawCardNumber.length - 4)
          : rawCardNumber;

      final card = VirtualCard(
        id: widget.existingCard?.id,
        nickname: _nicknameController.text,
        cardBrand: _cardBrandController.text,
        encryptedCardNumber: encryptedCardNumber,
        encryptedExpiry: encryptedExpiry,
        encryptedCvv: encryptedCvv,
        encryptedCardholderName: encryptedCardholderName,
        encryptedNotes: encryptedNotes,
        lastFourDigits: lastFourDigits,
        createdAt: widget.existingCard?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(cardRepositoryProvider);
      
      if (widget.existingCard != null) {
        await repo.updateCard(card);
      } else {
        await repo.insertCard(card);
      }
      
      ref.invalidate(cardsProvider);
      
      if (mounted) {
        Navigator.pop(context, true); // Pop with success true
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving card: $e')),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, {String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label.toUpperCase(),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: hint,
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingExisting) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingCard != null ? 'Edit Card' : 'Add New Card'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Identification Section
              const Text('IDENTIFICATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: _buildInputDecoration('Issuer', hint: 'e.g. Bank Name or Provider'),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  if (value.trim().length > 30) return 'Nickname too long';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _isCustomBrand ? 'Other' : _cardBrandController.text,
                decoration: _buildInputDecoration('Card Network'),
                dropdownColor: KardeColors.graphite,
                icon: const Icon(Icons.keyboard_arrow_down, color: KardeColors.champagneGold),
                style: const TextStyle(color: KardeColors.warmIvory, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                items: ['VISA', 'Mastercard', 'AMEX', 'Discover', 'Other']
                    .map((b) => DropdownMenuItem(
                          value: b,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(b),
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    if (val == 'Other') {
                      _isCustomBrand = true;
                      if (['VISA', 'Mastercard', 'AMEX', 'Discover'].contains(_cardBrandController.text)) {
                        _cardBrandController.text = ''; // Clear only if it was a default option
                      }
                    } else {
                      _isCustomBrand = false;
                      _cardBrandController.text = val ?? 'VISA';
                    }
                  });
                },
              ),
              if (_isCustomBrand) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cardBrandController,
                  decoration: _buildInputDecoration('Custom Network', hint: 'e.g. UnionPay, JCB'),
                  textCapitalization: TextCapitalization.words,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
              ],
              
              const SizedBox(height: 32),
              // Secure Details Section
              const Text('SECURE DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                decoration: _buildInputDecoration('Card Number', hint: '0000 0000 0000 0000'),
                keyboardType: TextInputType.number,
                maxLength: 19,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (val) {
                  final formatted = _CardFormatter.formatCardNumber(val);
                  if (formatted != val) {
                    _cardNumberController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.contains(RegExp(r'[^0-9\s]'))) return 'Letters and symbols are not allowed';
                  final clean = value.replaceAll(' ', '');
                  if (clean.length < 13) return 'Card number is too short';
                  if (!_CardFormatter.isValidLuhn(clean)) return 'Invalid card number (Luhn check failed)';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: _buildInputDecoration('Expiry Date', hint: 'MM/YY'),
                      keyboardType: TextInputType.text, // Allowing slash
                      inputFormatters: [ExpiryDateFormatter()],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || value.length != 5) {
                           // If user hasn't finished typing, don't scream at them unless they entered invalid month prefix
                           if (value != null && value.length >= 2 && !value.contains('/')) {
                             final m = int.tryParse(value.substring(0, 2));
                             if (m != null && (m < 1 || m > 12)) return 'Invalid month';
                           }
                           if (value != null && value.contains('/')) {
                             final parts = value.split('/');
                             final m = int.tryParse(parts[0]);
                             if (m != null && (m < 1 || m > 12)) return 'Invalid month';
                           }
                           return 'Required';
                        }
                        
                        final parts = value.split('/');
                        if (parts.length != 2) return 'Invalid';
                        
                        final month = int.tryParse(parts[0]);
                        if (month == null || month < 1 || month > 12) return 'Invalid month';
                        
                        final year = int.tryParse(parts[1]);
                        final currentYear = DateTime.now().year % 100;
                        if (year == null || year < currentYear) return 'Card expired';
                        
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: _buildInputDecoration(
                        'CVV',
                        hint: '123',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCvv ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureCvv = !_obscureCvv;
                            });
                          },
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: _obscureCvv,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (value.contains(RegExp(r'[^0-9]'))) return 'Numbers only';
                        
                        final brand = _cardBrandController.text;
                        final requiredLength = (brand == 'AMEX') ? 4 : 3;
                        if (value.length != requiredLength) return '$requiredLength digits required for $brand';
                        
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardholderNameController,
                decoration: _buildInputDecoration('Cardholder Name', hint: 'Name on card'),
                textCapitalization: TextCapitalization.words,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  if (value.contains(RegExp(r'[0-9]'))) return 'Numbers are not allowed';
                  if (value.contains(RegExp(r"[^a-zA-Z\s\.\-']"))) return 'Invalid characters included';
                  if (value.trim().length < 2) return 'Name is too short';
                  if (value.trim().length > 50) return 'Name is too long';
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              // Private Notes Section
              const Text('EXTRA INFO (OPTIONAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: _buildInputDecoration('Private Notes', hint: 'Bank phone numbers, PIN hints...'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveCard,
            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            label: Text(_isSaving ? 'Saving...' : 'Save Item'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}
