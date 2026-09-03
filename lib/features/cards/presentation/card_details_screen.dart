import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/security/authentication_service.dart';
import '../../../../core/security/window_security_service.dart';
import '../../../../core/storage/settings_repository.dart';
import '../../../core/security/encryption_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final decryptedNotes = await _encryptionService.decrypt(widget.card.encryptedNotes);
      if (mounted) {
        setState(() {
          _notes = decryptedNotes;
          _isLoadingNotes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notes = "Error decrypting notes.";
          _isLoadingNotes = false;
        });
      }
    }
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this card?'),
        content: const Text('This action cannot be undone and the card data will be permanently deleted from the encrypted vault.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted && widget.card.id != null) {
      // Require Biometric Auth to actually delete
      final authService = AuthenticationService();
      final settings = ref.read(settingsRepositoryProvider);
      final authenticated = await authService.authenticate(context, settings);
      
      if (authenticated && mounted) {
        await ref.read(cardRepositoryProvider).deleteCard(widget.card.id!);
        ref.invalidate(cardsProvider);
        Navigator.pop(context); // Go back to Home
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Details'),
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
            _buildSecurityBadge(),
            const SizedBox(height: 24),
            
            // Notes Section
            _buildSectionTitle('Private Notes'),
            const SizedBox(height: 8),
            _buildNotesBox(),
            const SizedBox(height: 24),
            
            // Metadata Section
            _buildSectionTitle('Card Metadata'),
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
                  label: const Text('Edit Card'),
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
                  label: const Text('Delete'),
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

  Widget _buildSecurityBadge() {
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
                  'End-to-End Local Protection',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Encrypted using Android Keystore & AES-256-GCM. Details require biometric authentication to reveal.',
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

  Widget _buildNotesBox() {
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
                  hasNotes ? _notes! : "No private notes saved. Tap 'Edit Card' to add a note.",
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: hasNotes ? Colors.black87 : Colors.grey,
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
