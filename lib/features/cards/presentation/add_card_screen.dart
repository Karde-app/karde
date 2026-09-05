import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../core/widgets/karde_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/security/encryption_service.dart';
import '../../../core/widgets/vault_photo_field.dart';
import '../../../core/utils/validators.dart';
import '../data/card_repository.dart';
import '../domain/virtual_card.dart';
import '../../../theme/theme.dart';
import '../../../l10n/app_localizations.dart';

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
  // FIX 7: isValidLuhn removed — consolidated into Validators class in validators.dart
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

  /// Null until checked. False means this device has no secure lock screen, so
  /// the Keystore will not hold the vault key and nothing can be saved.
  bool? _vaultAvailable;

  late final VaultPhotoController _photo;

  @override
  void initState() {
    super.initState();
    _checkVaultAvailable();
    _photo = VaultPhotoController();
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
      // FIX 2-1: one authenticated decrypt for the whole record, not five. The
      // list carries no payload, so it is fetched by id first.
      final payload = await ref.read(cardRepositoryProvider).payloadFor(card);
      final secrets = CardSecrets.fromJson(
        await _encryptionService.decrypt(payload),
      );

      if (mounted) {
        _cardNumberController.text =
            _CardFormatter.formatCardNumber(secrets.cardNumber);
        _expiryController.text = secrets.expiry;
        _cvvController.text = secrets.cvv;
        _cardholderNameController.text = secrets.cardholderName;
        _notesController.text = secrets.notes;
        // The photo came out of the same decrypt, so the form shows it straight
        // away — nothing left to unlock, no second prompt to spend.
        if (secrets.hasImage) _photo.adopt(base64Decode(secrets.image!));
      }
    } catch (e) {
      if (mounted) {
        KardeFeedback.error(context, 'Failed to decrypt existing card data.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingExisting = false);
      }
    }
  }

  /// FIX 4-2: never show a raw exception to the user. Explain what they can act
  /// on; keep the underlying detail internal.
  String _saveErrorMessage(Object error) {
    if (error is VaultUnavailable) {
      return 'Set a screen lock (PIN, pattern, or biometrics) on your device to '
          'save cards securely.';
    }
    if (error is VaultKeyInvalidated) {
      return 'Your device security settings changed, so the vault key is no '
          'longer valid. Existing items cannot be recovered.';
    }
    return 'Something went wrong saving this card. Please try again.';
  }

  @override
  void dispose() {
    // FIX 2-4: wipe decrypted card data out of the controllers before they are
    // torn down. Dart's GC is non-deterministic, so disposing alone can leave
    // the full PAN and CVV sitting in heap memory.
    _cardNumberController.clear();
    _expiryController.clear();
    _cvvController.clear();
    _cardholderNameController.clear();
    _notesController.clear();

    _nicknameController.dispose();
    _cardBrandController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    _notesController.dispose();
    // Holds a plaintext photo if one was picked and not yet saved.
    _photo.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final rawCardNumber = _cardNumberController.text.replaceAll(' ', '');

      // FIX 2-1: every use of the vault key costs one OS auth prompt, so all
      // secrets are encrypted as a single payload rather than field by field.
      // The photo rides in that same payload, so a photographed card still costs
      // exactly one prompt to save.
      final encryptedData = await _encryptionService.encrypt(
        CardSecrets(
          cardNumber: rawCardNumber,
          expiry: _expiryController.text,
          cvv: _cvvController.text,
          cardholderName: _cardholderNameController.text,
          notes: _notesController.text,
          image: _photo.imageBase64,
        ).toJson(),
      );

      final lastFourDigits = rawCardNumber.length >= 4
          ? rawCardNumber.substring(rawCardNumber.length - 4)
          : rawCardNumber;

      final card = VirtualCard(
        id: widget.existingCard?.id,
        nickname: _nicknameController.text,
        cardBrand: _cardBrandController.text,
        encryptedData: encryptedData,
        hasPhoto: _photo.hasPhoto,
        lastFourDigits: lastFourDigits,
        createdAt: widget.existingCard?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        // Preserve pin state across an edit; rebuilding the object without
        // these silently unpinned any card the user had pinned.
        isPinnedToTop: widget.existingCard?.isPinnedToTop ?? false,
        isPinnedToHomescreen: widget.existingCard?.isPinnedToHomescreen ?? false,
      );

      // FIX 6: Use notifier methods instead of invalidate
      if (widget.existingCard != null) {
        await ref.read(cardsProvider.notifier).updateCard(card);
      } else {
        await ref.read(cardsProvider.notifier).addCard(card);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on VaultAuthCancelled {
      // FIX 4-2: a dismissed auth prompt is a deliberate user action, not a
      // failure. Return to the form quietly.
      if (mounted) setState(() => _isSaving = false);
    } catch (e) {
      if (mounted) {
        KardeFeedback.error(context, _saveErrorMessage(e));
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showNetworkPicker() {
    final theme = Theme.of(context);
    final networks = ['VISA', 'Mastercard', 'AMEX', 'Discover', 'Other'];
    final currentSelection = _isCustomBrand ? 'Other' : _cardBrandController.text;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Select Card Network', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              ...networks.map((val) {
                final isSelected = val == currentSelection;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  title: Text(
                    val, 
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
                      color: isSelected ? const Color(0xFFC9A961) : theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: const Color(0xFFC9A961)) : null,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      if (val == 'Other') {
                        _isCustomBrand = true;
                        if (['VISA', 'Mastercard', 'AMEX', 'Discover'].contains(_cardBrandController.text)) {
                          _cardBrandController.text = ''; // Clear only if it was a default option
                        }
                      } else {
                        _isCustomBrand = false;
                        _cardBrandController.text = val;
                      }
                    });
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTooltipIcon(String message) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 2),
      margin: const EdgeInsets.symmetric(horizontal: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      textStyle: const TextStyle(
        color: Colors.white70, 
        fontSize: 11, 
        height: 1.3, 
        fontWeight: FontWeight.w300,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2128), 
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
    );
  }

  InputDecoration _buildInputDecoration(String label, {String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label.toUpperCase(),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: hint,
      suffixIcon: suffixIcon,
    );
  }

  /// `canUseVault()` already existed and its own doc claimed it was "checked
  /// before the user fills in a form", but nothing ever called it. A user with no
  /// screen lock could type a whole card in and only discover at save time that
  /// the vault key cannot exist on their device.
  Future<void> _checkVaultAvailable() async {
    final available = await EncryptionService().canUseVault();
    if (mounted) setState(() => _vaultAvailable = available);
  }

  Widget _buildVaultUnavailable(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Card"), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_clock_outlined, size: 56, color: theme.colorScheme.error),
              const SizedBox(height: 20),
              Text(
                "Set a screen lock first",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Outfit",
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Karde encrypts every item with a key held in your phone's secure "
                "hardware, and that hardware will not hold a key unless the phone "
                "itself is locked.\n\n"
                "Add a PIN, pattern, password or fingerprint in your phone's "
                "settings, then come back.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 28),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Go back"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_vaultAvailable == false) return _buildVaultUnavailable(context);

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
                decoration: _buildInputDecoration(
                  'Issuer *', 
                  hint: 'e.g. Bank Name or Provider',
                  suffixIcon: _buildTooltipIcon('The name of the bank or institution that issued this card.\n\nExample: Chase Bank'),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) => Validators.validateRequired(context, value),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _showNetworkPicker,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(text: _isCustomBrand ? 'Other' : _cardBrandController.text),
                    decoration: _buildInputDecoration(
                      'Card Network *',
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                  ),
                ),
              ),
              if (_isCustomBrand) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cardBrandController,
                  decoration: _buildInputDecoration(
                    'Custom Network *', 
                    hint: 'e.g. UnionPay, JCB',
                  ),
                  textCapitalization: TextCapitalization.words,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => Validators.validateRequired(context, value),
                ),
              ],
              
              const SizedBox(height: 32),
              // Secure Details Section
              const Text('SECURE DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                decoration: _buildInputDecoration(
                  'Card Number *', 
                  hint: '0000 0000 0000 0000',
                ),
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
                validator: (value) => Validators.validateCardNumber(context, value),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: _buildInputDecoration(
                        'Expiry Date *', 
                        hint: 'MM/YY',
                      ),
                      keyboardType: TextInputType.text, // Allowing slash
                      inputFormatters: [ExpiryDateFormatter()],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) => Validators.validateExpiry(context, value),
                      // Drives the advisory below, which appears and disappears
                      // as the date is typed.
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: _buildInputDecoration(
                        'CVV *',
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
                      validator: (value) => Validators.validateCvv(context, value),
                    ),
                  ),
                ],
              ),

              // An expired card used to be refused outright. People keep expired
              // cards — for records, a disputed charge, a subscription still
              // billing the old number — so this notes it and gets out of the
              // way rather than blocking the save.
              if (Validators.isCardExpired(_expiryController.text)) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This card has expired. You can still save it.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          height: 1.4,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardholderNameController,
                decoration: _buildInputDecoration(
                  'Cardholder Name *', 
                  hint: 'Name on card',
                ),
                textCapitalization: TextCapitalization.words,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  final req = Validators.validateRequired(context, value);
                  if (req != null) return req;
                  if (value!.contains(RegExp(r'[0-9]'))) return AppLocalizations.of(context)!.lettersAndSymbolsNotAllowed;
                  if (value.contains(RegExp(r"[^a-zA-Z\s\.\-']"))) return AppLocalizations.of(context)!.lettersAndSymbolsNotAllowed;
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              // Private Notes Section
              const Text('EXTRA INFO (OPTIONAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: _buildInputDecoration(
                  'Private Notes', 
                  hint: 'Bank phone numbers, PIN hints...',
                  suffixIcon: _buildTooltipIcon('Any additional details, addresses, or context.\n\nExample: Bank Phone: 1-800-123-4567'),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 28),
              VaultPhotoField(
                controller: _photo,
                label: 'CARD PHOTO',
                hint: 'Optional. Kept locked with the rest of the card.',
                viewerTitle: 'Card photo',
                enabled: !_isSaving,
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
