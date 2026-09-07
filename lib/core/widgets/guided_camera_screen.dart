import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../security/vault_image_service.dart';

/// Karde's own camera, with a rectangle showing where to put the card.
///
/// The phone's camera app takes a fine photograph of a room. It offers nothing
/// at all for the job actually being done here, which is photographing a
/// rectangular object flat and square, and the results showed it: cards at an
/// angle, half out of frame, or a passport the size of a postage stamp in the
/// middle of a desk.
///
/// **The permission is asked for here and nowhere else.** Karde declares CAMERA,
/// but never touches it until somebody taps "Take a photo", which is the one
/// moment the request explains itself. Refusing costs nothing: the phone's own
/// camera app still works and needs no permission from Karde at all, so this
/// screen offers that instead of a dead end.
///
/// **The photo is shown before it is kept.** An earlier version of the photo
/// feature cropped a preview and the result read as Karde having damaged the
/// document. A guide that silently trims a passport is the same mistake with
/// better intentions, so what the crop produced is put on screen with Retake
/// beside it, and nothing is saved until the user says so.
class GuidedCameraScreen extends StatefulWidget {
  const GuidedCameraScreen({super.key});

  /// Returns the finished JPEG, or null if the user backed out.
  static Future<Uint8List?> open(BuildContext context) {
    return Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => const GuidedCameraScreen()),
    );
  }

  /// How much of the frame's width the guide spans.
  ///
  /// Not the whole width: a margin gives somebody room to line the card up
  /// without its edges falling outside the picture entirely, and leaves a little
  /// of the surroundings in the crop so the result looks like a photograph of a
  /// card rather than a card that has been cut out.
  static const double guideWidthFraction = 0.86;

  /// A payment card is 85.6 × 53.98 mm. Passports and ID cards photograph
  /// happily inside the same shape, so one guide serves both rather than asking
  /// the user which kind of rectangle they are holding.
  static const double cardAspectRatio = 85.6 / 53.98;

  @override
  State<GuidedCameraScreen> createState() => _GuidedCameraScreenState();
}

class _GuidedCameraScreenState extends State<GuidedCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;

  /// Set when the camera cannot be used at all — permission refused, or no
  /// camera on the device. Distinguished from "still starting up", because one
  /// needs a way out offered and the other needs a moment's patience.
  bool _unavailable = false;

  bool _busy = false;

  /// The captured photo, cropped and ready, waiting to be accepted or rejected.
  Uint8List? _pending;

  final _images = VaultImageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android hands the camera to whatever comes to the foreground, so holding
    // it open in the background is both rude and, on some phones, a crash on the
    // way back. A vault has a second reason: a live camera belonging to a
    // backgrounded app is exactly the thing people are right to be uneasy about.
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _start();
    }
  }

  Future<void> _start() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Initialising is what raises Android's permission dialog. Nothing before
      // this line touches the camera, which is the whole point of asking here.
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      // Refused, or no camera. Either way this screen cannot do its job, and
      // saying so with a way out beats a black rectangle.
      if (mounted) setState(() => _unavailable = true);
    }
  }

  /// The guide rectangle, as fractions of the picture.
  ///
  /// Fractions rather than pixels because the crop happens on the full
  /// resolution photograph, which is far larger than anything on screen. The
  /// preview is laid out at the camera's own aspect ratio precisely so that this
  /// arithmetic holds: what the guide covers on screen is the same fraction of
  /// the sensor.
  Rect get _guide {
    const width = GuidedCameraScreen.guideWidthFraction;
    // The preview box is the camera's aspect ratio laid on its side, so a guide
    // that is `width` across is `width * previewAspect / cardAspect` tall as a
    // fraction of the box's height.
    final previewAspect = _controller?.value.aspectRatio ?? (4 / 3);
    final height =
        (width * previewAspect / GuidedCameraScreen.cardAspectRatio).clamp(0.1, 0.9);
    return Rect.fromLTWH((1 - width) / 2, (1 - height) / 2, width, height);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _busy) return;

    setState(() => _busy = true);
    try {
      final shot = await controller.takePicture();
      final guide = _guide;
      final bytes = await _images.cropCapture(
        path: shot.path,
        left: guide.left,
        top: guide.top,
        width: guide.width,
        height: guide.height,
      );
      if (mounted) setState(() => _pending = bytes);
    } catch (_) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.cameraCaptureFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Falls back to the phone's own camera app, which Karde needs no permission
  /// to use. Offered rather than described, because a person who has just
  /// refused a permission wants the photograph, not an explanation.
  Future<void> _useSystemCamera() async {
    try {
      final bytes = await _images.captureWithCamera();
      if (mounted) Navigator.pop(context, bytes);
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(loc.cameraTitle),
      ),
      body: SafeArea(
        child: _pending != null
            ? _buildConfirm(loc)
            : _unavailable
                ? _buildUnavailable(loc)
                : _buildCamera(loc),
      ),
    );
  }

  Widget _buildUnavailable(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_outlined,
              color: Colors.white54, size: 46),
          const SizedBox(height: 20),
          Text(
            loc.cameraUnavailable,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _useSystemCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: KardeColors.champagneGold,
                foregroundColor: KardeColors.obsidian,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(loc.cameraUsePhoneCamera),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCamera(AppLocalizations loc) {
    final controller = _controller;
    if (controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: KardeColors.champagneGold),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              // The preview is shown whole, at the camera's own shape, rather
              // than filled to the screen. Anything cropped for display would
              // make the guide describe a region of the picture that is not
              // where the user sees it.
              aspectRatio: 1 / controller.value.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controller),
                  CustomPaint(painter: _GuidePainter(_guide)),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            loc.cameraGuideHint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 8),
          child: GestureDetector(
            onTap: _busy ? null : _capture,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: _busy ? 0.4 : 1),
                border: Border.all(color: KardeColors.champagneGold, width: 4),
              ),
              child: _busy
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: KardeColors.obsidian),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirm(AppLocalizations loc) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(_pending!, fit: BoxFit.contain),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _pending = null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(loc.cameraRetake),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _pending),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KardeColors.champagneGold,
                    foregroundColor: KardeColors.obsidian,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(loc.cameraUsePhoto),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dims everything outside the guide and draws its corners.
///
/// Corners rather than a full outline: a complete rectangle competes with the
/// edges of the card being lined up inside it, and the two are easy to confuse
/// at a glance.
class _GuidePainter extends CustomPainter {
  const _GuidePainter(this.guide);

  final Rect guide;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      guide.left * size.width,
      guide.top * size.height,
      guide.width * size.width,
      guide.height * size.height,
    );
    final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(rounded),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    final corner = Paint()
      ..color = KardeColors.champagneGold
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final arm = rect.width * 0.09;
    void bracket(Offset at, double dx, double dy) {
      canvas.drawLine(at, at.translate(arm * dx, 0), corner);
      canvas.drawLine(at, at.translate(0, arm * dy), corner);
    }

    bracket(rect.topLeft, 1, 1);
    bracket(rect.topRight, -1, 1);
    bracket(rect.bottomLeft, 1, -1);
    bracket(rect.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(_GuidePainter oldDelegate) => oldDelegate.guide != guide;
}
