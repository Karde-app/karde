import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../security/vault_image_service.dart';
import 'karde_feedback.dart';
import 'secure_photo_view.dart';

/// The photo attached to the item being edited on an add/edit form.
///
/// Holds plaintext bytes only. Unlike the first version of this class it does no
/// encryption of its own: the photo is written as part of the record's single
/// encrypted payload, so the form encrypts everything in one operation and the
/// controller's job is reduced to "what picture, if any, should go in".
///
/// That is the whole reason the photo is not a separate encrypted file any more.
/// The vault key is per-use, so one authentication opens exactly one ciphertext —
/// two ciphertexts meant two prompts to save a card and two to reveal it.
class VaultPhotoController extends ChangeNotifier {
  Uint8List? _bytes;

  /// The photo currently attached, decoded. Null when there is none.
  Uint8List? get bytes => _bytes;

  bool get hasPhoto => _bytes != null;

  /// The photo in the form the encrypted payload carries it, or null.
  String? get imageBase64 => _bytes == null ? null : base64Encode(_bytes!);

  /// Takes on a photo that came out of the record's own decryption.
  ///
  /// Distinct from [select] only in intent — this is the existing photo being
  /// restored into the form, not a new choice by the user — but they behave
  /// identically, because by the time either happens the bytes are just bytes.
  void adopt(Uint8List bytes) => select(bytes);

  void select(Uint8List bytes) {
    _bytes = bytes;
    notifyListeners();
  }

  void clear() {
    _bytes = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // A document photo is as sensitive as anything else on the form. Drop the
    // reference rather than leaving it for whenever the GC gets to it.
    _bytes = null;
    super.dispose();
  }
}

/// Add, view, replace or remove the photo attached to a card or ID document.
///
/// There is no locked state here. The photo is part of the record's payload, so
/// by the time an edit form can display this field the record has already been
/// decrypted and the picture is in hand — showing it costs nothing further.
class VaultPhotoField extends StatefulWidget {
  final VaultPhotoController controller;

  /// Shown above the field, e.g. "Document photo".
  final String label;

  /// Explains what this photo is for on this particular form.
  final String hint;

  /// Title for the full-screen viewer.
  final String viewerTitle;

  /// Disables every action, e.g. while the form is saving.
  final bool enabled;

  const VaultPhotoField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.viewerTitle,
    this.enabled = true,
  });

  @override
  State<VaultPhotoField> createState() => _VaultPhotoFieldState();
}

class _VaultPhotoFieldState extends State<VaultPhotoField> {
  final _images = VaultImageService();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  bool get _interactive => widget.enabled && !_busy;

  Future<void> _choose(Future<Uint8List?> Function() source) async {
    setState(() => _busy = true);
    try {
      final bytes = await source();
      if (bytes != null) widget.controller.select(bytes);
    } on VaultImageUnreadable catch (e) {
      if (mounted) KardeFeedback.error(context, e.message);
    } catch (_) {
      if (mounted) {
        KardeFeedback.error(context, 'That photo could not be added. Try another.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _view() async {
    final bytes = widget.controller.bytes;
    if (bytes == null) return;
    await SecurePhotoView.open(
      context,
      bytes: bytes,
      title: widget.viewerTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 10),
        _buildBody(theme, controller),
        const SizedBox(height: 10),
        Text(
          widget.hint,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme, VaultPhotoController controller) {
    if (controller.hasPhoto) {
      return _buildFrame(
        theme,
        child: InkWell(
          onTap: _interactive ? _view : null,
          borderRadius: BorderRadius.circular(11),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // BoxFit.contain, not cover. A cropped thumbnail of a document
                // looks like the app cropped the document — the user reasonably
                // assumed the corners had been cut off before saving. The whole
                // frame is shown against a dark mat instead.
                Container(
                  height: 190,
                  width: double.infinity,
                  color: Colors.black.withValues(alpha: 0.85),
                  child: Image.memory(
                    controller.bytes!,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) => Center(
                      child: Text(
                        'This photo could not be displayed.',
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                      ),
                    ),
                  ),
                ),
                // Nothing previously suggested the thumbnail was tappable, so
                // the larger view went undiscovered.
                Positioned(
                  bottom: 10,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_out_map,
                              size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Tap to view full size',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          _action(Icons.photo_library_outlined, 'Replace', _showSourceSheet),
          _action(Icons.close, 'Remove', controller.clear),
        ],
      );
    }

    return _buildFrame(
      theme,
      child: InkWell(
        onTap: _interactive ? _showSourceSheet : null,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 110,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 10),
              Text(
                'Add a photo',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrame(
    ThemeData theme, {
    required Widget child,
    List<Widget> actions = const [],
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              child,
              if (_busy)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: _interactive ? onTap : null,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
    );
  }

  void _showSourceSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _choose(_images.captureWithCamera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _choose(_images.pickFromGallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
