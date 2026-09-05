import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/security/authentication_service.dart';
import '../../../../core/security/window_security_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/karde_confirm_dialog.dart';
import '../../../../core/storage/settings_repository.dart';
import '../../../core/security/encryption_service.dart';
import '../../../core/widgets/secure_photo_view.dart';
import '../../../theme/theme.dart';
import '../data/card_repository.dart';
import '../domain/virtual_card.dart';
import 'add_card_screen.dart';
import 'widgets/decryptable_card.dart';

class CardDetailsScreen extends ConsumerStatefulWidget {
  final VirtualCard card;

  const CardDetailsScreen({super.key, required this.card});

  @override
  ConsumerState<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends ConsumerState<CardDetailsScreen> {
  final _encryptionService = EncryptionService();

  String? _notes;
  bool _isLoadingNotes = true;

  /// The card photo, decoded from the same payload as the notes.
  ///
  /// Null both when the card has no photo and before anything has been unlocked;
  /// [_isUnlocked] tells the two apart, so an unlocked card with no photo does
  /// not keep offering to unlock one.
  Uint8List? _photo;
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    // FIX 2-1: notes are NOT decrypted on open any more. Every use of the vault
    // key costs an OS auth prompt, so opening a card must not silently trigger
    // one. _loadNotes() now runs only when the user asks to see them.
    _isLoadingNotes = false;
  }

  /// Unlocks everything this screen can show: the private notes and the photo.
  ///
  /// One prompt covers both, because both come out of the same ciphertext. That
  /// is the whole reason the photo was moved into the record payload — as a
  /// separate encrypted file it needed its own authentication, so a photographed
  /// card asked the user to authenticate twice to show one screen.
  Future<void> _unlock() async {
    setState(() => _isLoadingNotes = true);
    try {
      final payload = await ref.read(cardRepositoryProvider).payloadFor(widget.card);
      final secrets = CardSecrets.fromJson(
        await _encryptionService.decrypt(payload),
      );
      if (mounted) {
        setState(() {
          _notes = secrets.notes;
          _photo = secrets.hasImage ? base64Decode(secrets.image!) : null;
          _isUnlocked = true;
          _isLoadingNotes = false;
        });
      }
    } on VaultAuthCancelled {
      if (mounted) setState(() => _isLoadingNotes = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _notes = "Error decrypting notes.";
          _isUnlocked = true;
          _isLoadingNotes = false;
        });
      }
    }
  }

  Future<void> _openPhoto() async {
    final bytes = _photo;
    if (bytes == null) return;
    await SecurePhotoView.open(
      context,
      bytes: bytes,
      title: widget.card.nickname,
    );
  }

  Future<void> _editCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCardScreen(
          existingCard: widget.card,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context); // Pop back to home screen after edit to see changes
    }
  }

  Future<void> _confirmDelete() async {
    // FIX 5-1: shared confirmation dialog.
    final confirm = await KardeConfirmDialog.show(
      context,
      title: 'Delete this card?',
      message: 'This cannot be undone. The card data will be permanently '
          'deleted from the encrypted vault.',
      confirmLabel: 'Delete Permanently',
    );

    if (confirm && mounted && widget.card.id != null) {
      // Require Biometric Auth to actually delete
      final authService = AuthenticationService();
      final settings = ref.read(settingsRepositoryProvider);
      final authenticated = await authService.authenticate(context, settings);
      
      if (authenticated && mounted) {
        // The photo lives inside the row's payload, so deleting the row deletes
        // it too. Nothing else to clean up.
        await ref.read(cardRepositoryProvider).deleteCard(widget.card.id!);
        ref.invalidate(cardsProvider);
        if (mounted) Navigator.pop(context); // Go back to Home
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.cardDetailsTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The Card itself (Starts masked, can be revealed)
            DecryptableCard(card: widget.card, disableNavigation: true),
            const SizedBox(height: 32),
            
            // Security Status
            _buildSecurityBadge(loc),
            const SizedBox(height: 24),
            
            // Notes and photo share one lock, because they share one ciphertext.
            // The heading says so, rather than saying "private notes" and then
            // surprising the user with a picture.
            _buildSectionTitle(
              widget.card.hasPhoto
                  ? '${loc.privateNotesLabel} & PHOTO'
                  : loc.privateNotesLabel,
            ),
            const SizedBox(height: 8),
            _buildNotesBox(loc),
            const SizedBox(height: 24),

            // Only once unlocked is it known whether there is a photo at all, so
            // this section simply does not exist until then. A card without one
            // is never given an empty row to wonder about.
            if (_photo != null) ...[
              _buildSectionTitle('CARD PHOTO'),
              const SizedBox(height: 8),
              _buildPhotoBox(),
              const SizedBox(height: 24),
            ],
            
            // Metadata Section
            _buildSectionTitle(loc.cardDetails), // Using cardDetails as fallback for "Card Metadata"
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
                  onPressed: _editCard,
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
                  label: Text(loc.deleteCard),
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
                  loc.offlineBadge, // Reusing Offline & Encrypted for title
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.vaultHealthItems(1), // Reusing string as workaround, or we can add new ones
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

  Widget _buildNotesBox(AppLocalizations loc) {
    if (_isLoadingNotes) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // FIX 2-1: nothing is decrypted until the user explicitly asks, so that
    // opening a card never silently costs an authentication prompt.
    if (!_isUnlocked) {
      final theme = Theme.of(context);
      final hasPhoto = widget.card.hasPhoto;

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
                      hasPhoto ? 'Notes and photo' : 'Private notes',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tap to unlock',
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

    final hasNotes = _notes != null && _notes!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(hasNotes ? Icons.sticky_note_2_outlined : Icons.note_add_outlined, size: 20, color: Colors.blueGrey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasNotes ? _notes! : loc.privateNotesHint, // reusing hint as empty state text
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    // FIX 3-4: was hardcoded Colors.black87, invisible in dark mode.
                    color: hasNotes
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: hasNotes ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The already-decrypted card photo. Tapping it enlarges it, which costs
  /// nothing — it came out of the same decrypt as the notes.
  Widget _buildPhotoBox() {
    final theme = Theme.of(context);

    return InkWell(
      onTap: _openPhoto,
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _photo!,
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => Container(
            height: 180,
            alignment: Alignment.center,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
            child: Text(
              'This photo could not be displayed.',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataBox() {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMetaRow(Icons.calendar_today, 'Added On', dateFormat.format(widget.card.createdAt)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),
          _buildMetaRow(Icons.update, 'Last Updated', dateFormat.format(widget.card.updatedAt)),
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
