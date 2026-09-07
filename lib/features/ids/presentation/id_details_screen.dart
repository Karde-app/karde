import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/karde_feedback.dart';
import '../../backup/presentation/backup_feedback.dart';
import '../../../core/widgets/karde_confirm_dialog.dart';
import '../../../core/security/encryption_service.dart';
import '../../../core/security/window_security_service.dart';
import '../../../core/security/authentication_service.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../theme/theme.dart';
import '../domain/virtual_id.dart';
import '../data/id_repository.dart';
import 'add_id_screen.dart'; // For IdFieldType definition
import 'widgets/decryptable_id_card.dart';

class IdDetailsScreen extends ConsumerStatefulWidget {
  final VirtualId idDoc;

  const IdDetailsScreen({super.key, required this.idDoc});

  @override
  ConsumerState<IdDetailsScreen> createState() => _IdDetailsScreenState();
}

class _IdDetailsScreenState extends ConsumerState<IdDetailsScreen> {
  final _encryptionService = EncryptionService();
  
  Map<String, String>? _extraDetails;
  bool _isLoading = false;
  bool _isUnlocked = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // FIX (parity with card_details_screen): the extra details are NOT decrypted
    // on open any more. Every use of the vault key costs an OS auth prompt, so
    // merely opening an ID must not silently trigger one — and it must not put
    // the holder's details on screen before they asked for them. The card side
    // had this removed under audit fix 2-1; the ID side was missed.
    _isLoading = false;
  }

  Future<void> _unlock() async {
    setState(() => _isLoading = true);
    try {
      final payload = await ref.read(idRepositoryProvider).payloadFor(widget.idDoc);
      final decryptedJsonString = await _encryptionService.decrypt(payload);
      final Map<String, dynamic> rawMap = jsonDecode(decryptedJsonString);

      final Map<String, String> data = {};

      // Fields that are already displayed on the RealisticIdCard
      final cardFields = {
        IdFieldType.fullName.name,
        IdFieldType.dateOfBirth.name,
        IdFieldType.issueDate.name,
        IdFieldType.expiryDate.name,
        IdFieldType.documentNumber.name,
      };

      // fieldsOf drops the photo key. Without that, the base64 image would be
      // listed here as a detail row a megabyte long.
      IdPayload.fieldsOf(rawMap).forEach((key, value) {
        if (!cardFields.contains(key) && value.trim().isNotEmpty) {
          data[key] = value;
        }
      });
      
      if (mounted) {
        setState(() {
          _extraDetails = data;
          _isUnlocked = true;
          _isLoading = false;
        });
      }
    } on VaultAuthCancelled {
      // Dismissing the prompt is a deliberate user action, not a failure. Leave
      // the section locked and say nothing, exactly as the card screen does.
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.idOpenFailed;
          _isUnlocked = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editId() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddIdScreen(
          existingId: widget.idDoc,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete() async {
    // FIX 5-1: shared confirmation dialog.
    final confirm = await KardeConfirmDialog.show(
      context,
      title: AppLocalizations.of(context)!.deleteIdTitle,
      message: AppLocalizations.of(context)!.deleteIdMessage,
      confirmLabel: AppLocalizations.of(context)!.deletePermanently,
    );

    if (confirm && mounted && widget.idDoc.id != null) {
      final authService = AuthenticationService();
      final settings = ref.read(settingsRepositoryProvider);
      final authenticated = await authService.authenticate(context, settings);
      
      if (authenticated && mounted) {
        // The photo lives inside the row's payload, so deleting the row deletes
        // it too. Nothing else to clean up.
        await ref.read(idsProvider.notifier).deleteId(widget.idDoc.id!);
        if (!mounted) return;
        final message = backupAwareMessage(
          context,
          ref,
          AppLocalizations.of(context)!.idRemoved,
        );
        Navigator.pop(context);
        KardeFeedback.success(context, message);
      }
    }
  }

  String _getLabelForKey(String key, AppLocalizations loc) {
    try {
      final type = IdFieldType.values.byName(key);
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
    } catch (e) {
      return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.idDetails),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The Card Preview
            // Same single authentication serves both: the eye decrypts the whole
            // payload, so the Additional Details section below opens with it
            // instead of raising a second prompt, and re-locks when it re-masks.
            DecryptableIdCard(
              idDoc: widget.idDoc,
              disableNavigation: true,
              onRevealed: (fields) {
                if (!mounted) return;
                final cardFields = {
                  IdFieldType.fullName.name,
                  IdFieldType.dateOfBirth.name,
                  IdFieldType.issueDate.name,
                  IdFieldType.expiryDate.name,
                  IdFieldType.documentNumber.name,
                };
                final extra = <String, String>{};
                fields.forEach((key, value) {
                  if (!cardFields.contains(key) && value.trim().isNotEmpty) {
                    extra[key] = value;
                  }
                });
                setState(() {
                  _extraDetails = extra;
                  _isUnlocked = true;
                  _isLoading = false;
                  _error = null;
                });
              },
              onHidden: () {
                if (!mounted) return;
                setState(() {
                  _extraDetails = null;
                  _isUnlocked = false;
                });
              },
            ),
            const SizedBox(height: 32),
            
            // Security Status
            _buildSecurityBadge(loc),
            const SizedBox(height: 24),
            
            // Extra Details Section. Locked until asked for — see initState.
            _buildSectionTitle(loc.additionalDetails),
            const SizedBox(height: 8),
            _buildExtraDetails(loc),
            const SizedBox(height: 24),
            
            // Metadata Section
            _buildSectionTitle(loc.detailsSection),
            const SizedBox(height: 8),
            _buildMetadataBox(),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editId,
                  icon: const Icon(Icons.edit, size: 20),
                  label: Text(loc.editDetails),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text(loc.deleteId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityBadge(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, color: Colors.green.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.offlineBadge, // Reusing "Offline & Encrypted"
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.vaultHealthItems(1), // Reusing "1 item protected"
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }
  /// The gate in front of the document's details.
  ///
  /// Mirrors `card_details_screen._buildNotesBox`. Opening an ID used to decrypt
  /// immediately, which cost an authentication prompt just to look at the screen
  /// and put the holder's details on show before they had asked. One prompt still
  /// opens everything, because it is all one ciphertext.
  Widget _buildExtraDetails(AppLocalizations loc) {
    if (_isLoading) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isUnlocked) {
      final theme = Theme.of(context);
      return InkWell(
        onTap: _unlock,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                KardeColors.champagneGold.withValues(alpha: 0.10),
                KardeColors.champagneGold.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: KardeColors.champagneGold.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: KardeColors.champagneGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline,
                    size: 20, color: KardeColors.champagneGold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.documentDetails,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      loc.tapToUnlock,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.fingerprint,
                  size: 22,
                  color: KardeColors.champagneGold.withValues(alpha: 0.8)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: KardeColors.ember)),
      );
    }

    if (_extraDetails == null || _extraDetails!.isEmpty) {
      return Text(
        loc.noExtraDetails,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
    }

    return _buildExtraDetailsBox(loc);
  }


  Widget _buildExtraDetailsBox(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _extraDetails!.entries.map((entry) {
          final isLast = entry.key == _extraDetails!.entries.last.key;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getLabelForKey(entry.key, loc),
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                entry.value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
              ),
              if (!isLast) const Divider(height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetadataBox() {
    final loc = AppLocalizations.of(context)!;
    // Locale-aware rather than a fixed pattern, as on the card screen.
    final dateFormat = DateFormat.yMMMd(loc.localeName).add_jm();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMetaRow(Icons.calendar_today, loc.addedOn, dateFormat.format(widget.idDoc.createdAt)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),
          _buildMetaRow(Icons.update, loc.lastUpdated, dateFormat.format(widget.idDoc.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
