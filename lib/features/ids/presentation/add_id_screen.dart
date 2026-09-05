import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/widgets/karde_feedback.dart';
import '../../../core/widgets/vault_photo_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/security/encryption_service.dart';
import '../../../theme/theme.dart';
import '../domain/virtual_id.dart';
import '../data/id_repository.dart';

enum IdFieldType {
  documentNumber,
  fullName,
  dateOfBirth,
  sexGender,
  issuingAuthority,
  issueDate,
  expiryDate,
  placeOfBirth,
  personalId,
  bloodGroup,
  notes,
}

class IdFieldConfig {
  final IdFieldType type;
  final bool required;

  const IdFieldConfig({required this.type, this.required = false});
}

final Map<String, List<IdFieldConfig>> idTypeConfig = {
  "Passport": [
    const IdFieldConfig(type: IdFieldType.documentNumber, required: true),
    const IdFieldConfig(type: IdFieldType.fullName, required: true),
    const IdFieldConfig(type: IdFieldType.dateOfBirth, required: true),
    const IdFieldConfig(type: IdFieldType.sexGender),
    const IdFieldConfig(type: IdFieldType.issuingAuthority, required: true),
    const IdFieldConfig(type: IdFieldType.issueDate, required: true),
    const IdFieldConfig(type: IdFieldType.expiryDate, required: true),
    const IdFieldConfig(type: IdFieldType.placeOfBirth),
  ],
  "Driver's License": [
    const IdFieldConfig(type: IdFieldType.documentNumber, required: true),
    const IdFieldConfig(type: IdFieldType.fullName, required: true),
    const IdFieldConfig(type: IdFieldType.dateOfBirth, required: true),
    const IdFieldConfig(type: IdFieldType.sexGender),
    const IdFieldConfig(type: IdFieldType.issueDate, required: true),
    const IdFieldConfig(type: IdFieldType.expiryDate, required: true),
    const IdFieldConfig(type: IdFieldType.bloodGroup),
    const IdFieldConfig(type: IdFieldType.notes), // For Address/Class
  ],
  "National ID": [
    const IdFieldConfig(type: IdFieldType.documentNumber, required: true),
    const IdFieldConfig(type: IdFieldType.personalId), // SSN/National No
    const IdFieldConfig(type: IdFieldType.fullName, required: true),
    const IdFieldConfig(type: IdFieldType.dateOfBirth, required: true),
    const IdFieldConfig(type: IdFieldType.sexGender),
    const IdFieldConfig(type: IdFieldType.issuingAuthority, required: true),
    const IdFieldConfig(type: IdFieldType.issueDate, required: true),
    const IdFieldConfig(type: IdFieldType.expiryDate, required: true),
  ],
  "Resident Permit": [
    const IdFieldConfig(type: IdFieldType.documentNumber, required: true),
    const IdFieldConfig(type: IdFieldType.fullName, required: true),
    const IdFieldConfig(type: IdFieldType.dateOfBirth, required: true),
    const IdFieldConfig(type: IdFieldType.sexGender),
    const IdFieldConfig(type: IdFieldType.issuingAuthority, required: true),
    const IdFieldConfig(type: IdFieldType.issueDate, required: true),
    const IdFieldConfig(type: IdFieldType.expiryDate, required: true),
    const IdFieldConfig(type: IdFieldType.bloodGroup),
    const IdFieldConfig(type: IdFieldType.notes), // For Address
  ],
  "Other": [
    const IdFieldConfig(type: IdFieldType.documentNumber, required: true),
    const IdFieldConfig(type: IdFieldType.fullName, required: true),
    const IdFieldConfig(type: IdFieldType.dateOfBirth),
    const IdFieldConfig(type: IdFieldType.sexGender),
    const IdFieldConfig(type: IdFieldType.issuingAuthority),
    const IdFieldConfig(type: IdFieldType.issueDate, required: true),
    const IdFieldConfig(type: IdFieldType.expiryDate, required: true),
    const IdFieldConfig(type: IdFieldType.placeOfBirth),
    const IdFieldConfig(type: IdFieldType.personalId),
    const IdFieldConfig(type: IdFieldType.bloodGroup),
    const IdFieldConfig(type: IdFieldType.notes),
  ],
};

/// The translated name for one of [idTypeConfig]'s keys.
///
/// The keys themselves stay in English because they are *stored* on the
/// record and later matched by `RealisticIdCard` to pick a card template, so
/// translating them would silently change which template a document gets and
/// break every ID already saved. A type the user typed themselves is not in
/// the map and is shown exactly as they wrote it.
String idTypeLabel(String type, AppLocalizations loc) {
  switch (type) {
    case 'Passport':
      return loc.idTypePassport;
    case "Driver's License":
      return loc.idTypeDriversLicense;
    case 'National ID':
      return loc.idTypeNationalId;
    case 'Resident Permit':
      return loc.idTypeResidentPermit;
    case 'Other':
      return loc.otherOption;
    default:
      return type;
  }
}

/// Parses one of the ID form's `dd/MM/yyyy` fields. Null when blank or invalid.
///
/// Top-level and public so the date rules can be tested without building a
/// widget. The rollover case below is exactly the kind of thing that is easy to
/// get wrong and almost impossible to catch by hand.
DateTime? parseIdDate(String? text) {
  if (text == null || text.trim().isEmpty) return null;
  final parts = text.trim().split('/');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  final parsed = DateTime(year, month, day);
  // Rejects the likes of 31/02/2030, which DateTime would otherwise roll
  // silently forward into March rather than refuse.
  if (parsed.day != day || parsed.month != month || parsed.year != year) {
    return null;
  }
  return parsed;
}

String formatIdDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';

/// The rule between an issue date and an expiry date, as a pure function.
///
/// A document that has already expired is a reasonable thing to keep in a
/// vault, so a past expiry is allowed. What is not allowed is an expiry that
/// precedes its own issue, which the form used to accept without complaint.
///
/// Returns whether the rule is broken rather than the sentence to show. The
/// rule has no locale; the wording is chosen by the form.
bool expiryPrecedesIssue({DateTime? issue, DateTime? expiry}) {
  if (issue == null || expiry == null) return false;
  return !expiry.isAfter(issue);
}

class AddIdScreen extends ConsumerStatefulWidget {
  final VirtualId? existingId;
  const AddIdScreen({super.key, this.existingId});

  @override
  ConsumerState<AddIdScreen> createState() => _AddIdScreenState();
}

class _AddIdScreenState extends ConsumerState<AddIdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _customTypeController = TextEditingController();

  final Map<IdFieldType, TextEditingController> _controllers = {};
  String _selectedIdType = "National ID";
  bool _isCustomType = false;
  bool _isLoading = false;

  /// FIX 4-3: set when existing ID data could not be decrypted. Saving is blocked
  /// while true, so a failed load cannot silently overwrite real data with blanks.
  bool _loadFailed = false;

  /// Null until checked. False means this device has no secure lock screen, so
  /// the Keystore will not hold the vault key and nothing can be saved.
  bool? _vaultAvailable;

  late final VaultPhotoController _photo;

  /// True once the user has actually tried to save.
  ///
  /// Before that, no field shows an error: nobody wants to be told a form is
  /// wrong while they are still filling it in. Afterwards every field validates
  /// live, so an error clears the moment it is fixed.
  ///
  /// Without this the expiry field could stick on "Required" — picking an issue
  /// date ran a whole-form validate, which flagged the still-empty expiry, and
  /// filling the expiry in did not re-run it because setting a controller's text
  /// programmatically does not trigger validation. The message only cleared when
  /// Save was pressed.
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _checkVaultAvailable();
    for (var type in IdFieldType.values) {
      _controllers[type] = TextEditingController();
    }

    _photo = VaultPhotoController();

    if (widget.existingId != null) {
      _selectedIdType = widget.existingId!.idType;
      _nicknameController.text = widget.existingId!.nickname;
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    try {
      final payload = await ref.read(idRepositoryProvider).payloadFor(widget.existingId!);
      final decryptedStr = await EncryptionService().decrypt(payload);
      final data = jsonDecode(decryptedStr) as Map<String, dynamic>;

      for (var entry in IdPayload.fieldsOf(data).entries) {
        try {
          final type = IdFieldType.values.byName(entry.key);
          _controllers[type]?.text = entry.value;
        } catch (_) {}
      }

      // The photo came out of the same decrypt as the fields, so the form can
      // show it immediately. There is nothing left to unlock and no second
      // prompt to spend.
      final image = IdPayload.imageOf(data);
      if (image != null) _photo.adopt(base64Decode(image));
      
      if (!idTypeConfig.containsKey(_selectedIdType)) {
         _isCustomType = true;
         _customTypeController.text = _selectedIdType;
         _selectedIdType = 'Other';
      }
    } on VaultAuthCancelled {
      // FIX 4-3: the user dismissed the auth prompt. Saving must still be
      // blocked, because the form is empty and saving would overwrite their
      // real data with blanks.
      if (mounted) {
        setState(() => _loadFailed = true);
      }
    } catch (e) {
      // FIX 4-3: this catch was empty. If decryption failed the user saw an
      // empty form with no warning and could silently overwrite their encrypted
      // ID with blank values. Now the failure is shown and saving is disabled.
      if (mounted) {
        setState(() => _loadFailed = true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // FIX 2-4: wipe decrypted ID data out of the controllers before tearing them
    // down. Dart's GC is non-deterministic, so disposing alone can leave document
    // numbers and other identifying details sitting in heap memory.
    _nicknameController.clear();
    _customTypeController.clear();
    for (var controller in _controllers.values) {
      controller.clear();
    }

    _nicknameController.dispose();
    _customTypeController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    // Holds a plaintext photo if one was picked and not yet saved; disposing
    // drops it for the same reason the controllers are cleared above.
    _photo.dispose();
    super.dispose();
  }

  void _onTypeChanged(String? newType) {
    if (newType == null || newType == _selectedIdType) return;
    
    // Clear fields that are not in the new type
    final newConfig = idTypeConfig[newType]!;
    final newTypes = newConfig.map((c) => c.type).toSet();
    
    for (var type in IdFieldType.values) {
      if (!newTypes.contains(type)) {
        _controllers[type]!.clear();
      }
    }
    
    setState(() {
      _selectedIdType = newType;
      if (newType == 'Other') {
        _isCustomType = true;
      } else {
        _isCustomType = false;
        _customTypeController.clear();
      }
    });
  }

  /// Reads one of the form's `dd/MM/yyyy` fields, or null if it is blank or
  /// unparseable.
  DateTime? _dateIn(IdFieldType type) => parseIdDate(_controllers[type]?.text);

  Future<void> _selectDate(BuildContext context, IdFieldType type) async {
    final today = DateTime.now();
    final issued = _dateIn(IdFieldType.issueDate);

    // The picker is constrained per field rather than left wide open from 1900
    // to 2100. Without this an expiry could be chosen before its own issue date,
    // or a birthday in the future, and the form would accept it.
    late final DateTime first;
    late final DateTime last;
    switch (type) {
      case IdFieldType.dateOfBirth:
        first = DateTime(1900);
        last = today; // nobody is born tomorrow
      case IdFieldType.issueDate:
        first = DateTime(1900);
        last = today; // a document cannot have been issued in the future
      case IdFieldType.expiryDate:
        // An expired document is a perfectly good thing to keep in a vault, so
        // a past expiry is allowed — but it must still come after the issue.
        first = issued?.add(const Duration(days: 1)) ?? DateTime(1900);
        last = DateTime(2100);
      default:
        first = DateTime(1900);
        last = DateTime(2100);
    }

    final existing = _dateIn(type);
    // initialDate must sit inside the range or showDatePicker asserts.
    final DateTime initial = switch (existing) {
      final DateTime d when !d.isBefore(first) && !d.isAfter(last) => d,
      _ => today.isBefore(first)
          ? first
          : (today.isAfter(last) ? last : today),
    };

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        // Follows the app theme. This used to force ColorScheme.dark, which put
        // white-on-dark chrome in front of a light-theme user.
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: KardeColors.champagneGold,
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // setState alone is enough: once the form has been submitted the fields
      // validate on every rebuild, so a newly chosen date clears its own error
      // and any date it invalidates elsewhere picks one up.
      setState(() => _controllers[type]!.text = formatIdDate(picked));
    }
  }

  /// Cross-field date rules, applied on top of the plain "required" check.
  String? _validateDateField(AppLocalizations loc, IdFieldType type, String? value) {
    final parsed = parseIdDate(value);
    if (parsed == null) return null; // blank, or handled by the required check

    final today = DateTime.now();
    switch (type) {
      case IdFieldType.dateOfBirth:
        if (parsed.isAfter(today)) return loc.idDobNotInFuture;
      case IdFieldType.issueDate:
        if (parsed.isAfter(today)) return loc.idIssueDateNotInFuture;
      case IdFieldType.expiryDate:
        return expiryPrecedesIssue(
                issue: _dateIn(IdFieldType.issueDate), expiry: parsed)
            ? loc.idExpiryAfterIssue
            : null;
      default:
        break;
    }
    return null;
  }

  void _showTypePicker() {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
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
                child: Text(loc.selectDocumentType, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              ...idTypeConfig.keys.map((type) {
                final isSelected = type == _selectedIdType;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  title: Text(
                    idTypeLabel(type, loc),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
                      color: isSelected ? KardeColors.champagneGold : theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: KardeColors.champagneGold) : null,
                  onTap: () {
                    Navigator.pop(context);
                    _onTypeChanged(type);
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

  Future<void> _saveId() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final config = idTypeConfig[_selectedIdType]!;
      final Map<String, String> payload = {};
      
      for (var fieldConfig in config) {
        final text = _controllers[fieldConfig.type]!.text.trim();
        if (text.isNotEmpty) {
          payload[fieldConfig.type.name] = text;
        }
      }
      
      // Fields and photo are encrypted together, as one payload and therefore one
      // authentication prompt. Saving a document with a picture costs exactly what
      // saving one without costs.
      final jsonString = jsonEncode(
        IdPayload.encode(fields: payload, image: _photo.imageBase64),
      );
      final encryptedData = await EncryptionService().encrypt(jsonString);

      final String finalIdType = (_isCustomType && _customTypeController.text.trim().isNotEmpty)
          ? _customTypeController.text.trim()
          : _selectedIdType;

      final newId = VirtualId(
        id: widget.existingId?.id,
        nickname: _nicknameController.text.trim(),
        idType: finalIdType,
        encryptedData: encryptedData,
        hasPhoto: _photo.hasPhoto,
        createdAt: widget.existingId?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        // Preserve pin state across an edit, as the card form does.
        isPinnedToTop: widget.existingId?.isPinnedToTop ?? false,
        isPinnedToHomescreen: widget.existingId?.isPinnedToHomescreen ?? false,
      );

      if (widget.existingId != null) {
        await ref.read(idsProvider.notifier).updateId(newId);
      } else {
        await ref.read(idsProvider.notifier).addId(newId);
      }

      if (mounted) {
        Navigator.pop(context, true);
        // FIX 5-2: consistent success feedback.
        KardeFeedback.success(
          context,
          widget.existingId != null
              ? AppLocalizations.of(context)!.idUpdatedSecurely
              : AppLocalizations.of(context)!.idAddedSecurely,
        );
      }
    } on VaultAuthCancelled {
      // FIX 4-2: dismissed prompt is not a failure.
    } catch (e) {
      // FIX 4-2: was 'Failed to encrypt/save ID: $e' — a raw exception.
      if (mounted) {
        KardeFeedback.error(
          context,
          e is VaultUnavailable
              ? AppLocalizations.of(context)!.addIdNeedsScreenLock
              : AppLocalizations.of(context)!.addIdSaveFailed,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getLabelForType(IdFieldType type, AppLocalizations loc) {
    switch (type) {
      case IdFieldType.documentNumber: return loc.documentNumber;
      case IdFieldType.fullName: return loc.fullName;
      case IdFieldType.dateOfBirth: return loc.dateOfBirth;
      case IdFieldType.sexGender: return loc.sexGender;
      case IdFieldType.issuingAuthority: return loc.issuingAuthority;
      case IdFieldType.issueDate: return loc.issueDate;
      case IdFieldType.expiryDate: return loc.expiryDate;
      case IdFieldType.placeOfBirth: return loc.placeOfBirth;
      case IdFieldType.personalId: return loc.personalId;
      case IdFieldType.bloodGroup: return loc.bloodGroup;
      case IdFieldType.notes: return loc.privateNotesLabel;
    }
  }

  String? _getTooltipForType(IdFieldType type, AppLocalizations loc) {
    switch (type) {
      case IdFieldType.issuingAuthority: return loc.issuingAuthorityTooltip;
      case IdFieldType.personalId: return loc.personalIdTooltip;
      case IdFieldType.notes: return loc.idNotesTooltip;
      default: return null;
    }
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

  /// Mirrors the guard on the card form. See `add_card_screen`: `canUseVault()`
  /// documented itself as being checked before the form is filled in, but was
  /// never called, so a user with no screen lock only found out at save time.
  Future<void> _checkVaultAvailable() async {
    final available = await EncryptionService().canUseVault();
    if (mounted) setState(() => _vaultAvailable = available);
  }

  Widget _buildVaultUnavailable(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.addIdDocument), centerTitle: true),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingId != null ? loc.editDocument : loc.addAnId),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // FIX 4-3: explain why saving is disabled after a failed load,
                  // instead of presenting an innocent-looking empty form.
                  if (_loadFailed) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: KardeColors.ember.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KardeColors.ember.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_outline, color: KardeColors.ember, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              loc.idUnlockFailedWarning,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                height: 1.4,
                                color: KardeColors.ember,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  GestureDetector(
                    onTap: _showTypePicker,
                    child: AbsorbPointer(
                      child: TextFormField(
                        // FIX 3-3: when editing a custom type, show the user's
                        // actual document type rather than the generic "Other".
                        controller: TextEditingController(
                          text: _isCustomType && _customTypeController.text.isNotEmpty
                              ? _customTypeController.text
                              : idTypeLabel(_selectedIdType, loc),
                        ),
                        decoration: InputDecoration(
                          labelText: loc.documentType,
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                        ),
                      ),
                    ),
                  ),
                  if (_isCustomType) ...[
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _customTypeController,
                      decoration: InputDecoration(
                        labelText: loc.requiredFieldMarker(loc.customDocumentType),
                        hintText: loc.customDocumentTypeHint,
                        suffixIcon: _buildTooltipIcon(loc.customDocumentTypeTooltip),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (val) => (val == null || val.isEmpty) ? loc.requiredField : null,
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      labelText: loc.requiredFieldMarker(loc.nicknameLabel),
                      hintText: loc.nicknameHint,
                      suffixIcon: _buildTooltipIcon(loc.nicknameTooltip),
                    ),
                    validator: (val) => (val == null || val.isEmpty) ? loc.requiredField : null,
                  ),
                  const SizedBox(height: 20),
                  
                  ...idTypeConfig[_selectedIdType]!.map((config) {
                    final isDate = config.type == IdFieldType.dateOfBirth || 
                                   config.type == IdFieldType.issueDate || 
                                   config.type == IdFieldType.expiryDate;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TextFormField(
                        controller: _controllers[config.type],
                        readOnly: isDate,
                        onTap: isDate ? () => _selectDate(context, config.type) : null,
                        decoration: InputDecoration(
                          labelText: config.required
                              ? loc.requiredFieldMarker(_getLabelForType(config.type, loc))
                              : _getLabelForType(config.type, loc),
                          suffixIcon: isDate 
                            ? const Icon(Icons.calendar_today, size: 20, color: Colors.grey)
                            : (_getTooltipForType(config.type, loc) != null 
                                ? _buildTooltipIcon(_getTooltipForType(config.type, loc)!) 
                                : null),
                        ),
                        autovalidateMode: _submitted
                            ? AutovalidateMode.always
                            : AutovalidateMode.disabled,
                        validator: (val) {
                          if (config.required && (val == null || val.isEmpty)) {
                            return loc.requiredField;
                          }
                          // Runs for optional dates too: a date that is present
                          // has to be coherent whether or not it was compulsory.
                          if (isDate) return _validateDateField(loc, config.type, val);
                          return null;
                        },
                      ),
                    );
                  }),

                  VaultPhotoField(
                    controller: _photo,
                    label: loc.documentPhotoLabel,
                    hint: loc.documentPhotoHint,
                    viewerTitle: loc.documentPhotoViewerTitle,
                    enabled: !_isLoading && !_loadFailed,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: (_isLoading || _loadFailed) ? null : _saveId,
            icon: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
              : const Icon(Icons.save),
            label: Text(_isLoading ? loc.saving : loc.saveItem),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}
