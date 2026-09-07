import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../core/widgets/karde_feedback.dart';
import '../../backup/presentation/backup_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/security/encryption_service.dart';
import '../../../core/widgets/vault_photo_field.dart';
import '../../../core/utils/expiry.dart';
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
        KardeFeedback.error(context, AppLocalizations.of(context)!.addCardDecryptFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingExisting = false);
      }
    }
  }

  /// FIX 4-2: never show a raw exception to the user. Explain what they can act
  /// on; keep the underlying detail internal.
  String _saveErrorMessage(AppLocalizations loc, Object error) {
    if (error is VaultUnavailable) return loc.addCardNeedsScreenLock;
    if (error is VaultKeyInvalidated) return loc.vaultKeyChangedItemsLost;
    return loc.addCardSaveFailed;
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
      final secrets = CardSecrets(
        cardNumber: rawCardNumber,
        expiry: _expiryController.text,
        cvv: _cvvController.text,
        cardholderName: _cardholderNameController.text,
        notes: _notesController.text,
        image: _photo.imageBase64,
      ).toJson();

      final encryptedData = await _encryptionService.encrypt(secrets);

      final lastFourDigits = rawCardNumber.length >= 4
          ? rawCardNumber.substring(rawCardNumber.length - 4)
          : rawCardNumber;

      final card = VirtualCard(
        id: widget.existingCard?.id,
        nickname: _nicknameController.text,
        cardBrand: _cardBrandController.text,
        encryptedData: encryptedData,
        hasPhoto: _photo.hasPhoto,
        // Always recorded, whatever the reminder setting says. An expiry date is
        // printed on the front of the card; it is not a secret, and treating it
        // as one bought a great deal of ceremony and nothing else. The setting
        // decides whether Karde *says* anything about it, not whether it is
        // allowed to know.
        expiresOn: Expiry.fromCardExpiry(_expiryController.text),
        lastFourDigits: lastFourDigits,
        createdAt: widget.existingCard?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        // Preserve pin state across an edit; rebuilding the object without
        // these silently unpinned any card the user had pinned.
        isPinnedToTop: widget.existingCard?.isPinnedToTop ?? false,
        isPinnedToHomescreen: widget.existingCard?.isPinnedToHomescreen ?? false,
      );

      // The payload goes with it, so the automatic backup can record this card
      // without reading it back out of the vault — which would cost another
      // authentication prompt, on every single save.
      final payload = jsonDecode(secrets) as Map<String, dynamic>;

      // FIX 6: Use notifier methods instead of invalidate
      if (widget.existingCard != null) {
        await ref.read(cardsProvider.notifier).updateCard(card, secrets: payload);
      } else {
        await ref.read(cardsProvider.notifier).addCard(card, secrets: payload);
      }

      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        final saved = widget.existingCard != null
            ? loc.cardUpdatedSecurely
            : loc.cardAddedSecurely;
        final message = backupAwareMessage(context, ref, saved);
        Navigator.pop(context, true);
        KardeFeedback.success(context, message);
      }
    } on VaultAuthCancelled {
      // FIX 4-2: a dismissed auth prompt is a deliberate user action, not a
      // failure. Return to the form quietly.
      if (mounted) setState(() => _isSaving = false);
    } catch (e) {
      if (mounted) {
        KardeFeedback.error(context, _saveErrorMessage(AppLocalizations.of(context)!, e));
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showNetworkPicker() {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
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
                child: Text(loc.selectCardNetwork, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              ...networks.map((val) {
                final isSelected = val == currentSelection;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  title: Text(
                    val == 'Other' ? loc.otherOption : val,
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
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.addNewCard), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_clock_outlined, size: 56, color: theme.colorScheme.error),
              const SizedBox(height: 20),
              Text(
                loc.setScreenLockFirst,
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
                loc.screenLockExplainer,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 28),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.goBack),
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

    final loc = AppLocalizations.of(context)!;

    if (_isLoadingExisting) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.loadingDetails)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingCard != null ? loc.editCard : loc.addNewCard),
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
              Text(loc.identification, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: _buildInputDecoration(
                  loc.requiredFieldMarker(loc.issuerFieldLabel),
                  hint: loc.issuerHint,
                  suffixIcon: _buildTooltipIcon(loc.issuerTooltip),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) => Validators.validateRequired(context, value),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _showNetworkPicker,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(text: _isCustomBrand ? loc.otherOption : _cardBrandController.text),
                    decoration: _buildInputDecoration(
                      loc.requiredFieldMarker(loc.cardNetworkLabel),
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
                    loc.requiredFieldMarker(loc.customNetworkFieldLabel),
                    hint: loc.customNetworkHint,
                  ),
                  textCapitalization: TextCapitalization.words,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => Validators.validateRequired(context, value),
                ),
              ],
              
              const SizedBox(height: 32),
              // Secure Details Section
              Text(loc.secureDetails, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                decoration: _buildInputDecoration(
                  loc.requiredFieldMarker(loc.cardNumberFieldLabel),
                  hint: loc.cardNumberHint,
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
                        loc.requiredFieldMarker(loc.expiryDate),
                        hint: loc.expiryHint,
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
                        loc.requiredFieldMarker(loc.cvvLabel),
                        hint: loc.cvvHint,
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
                        loc.cardExpiredStillSave,
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
                  loc.requiredFieldMarker(loc.cardholderNameFieldLabel),
                  hint: loc.cardholderNameHint,
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
              Text(loc.extraInfo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: _buildInputDecoration(
                  loc.privateNotesFieldLabel,
                  hint: loc.privateNotesHint,
                  suffixIcon: _buildTooltipIcon(loc.privateNotesTooltip),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 28),
              VaultPhotoField(
                controller: _photo,
                label: loc.cardPhotoLabel,
                hint: loc.cardPhotoHint,
                viewerTitle: loc.cardPhotoViewerTitle,
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
            label: Text(_isSaving ? loc.saving : loc.saveItem),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}
