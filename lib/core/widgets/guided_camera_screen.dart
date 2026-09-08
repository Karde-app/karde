import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../security/system_interaction_guard.dart';
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

  /// The guide as fractions of the preview box, sized so that it *looks* like a
  /// card.
  ///
  /// Fractions rather than pixels because the crop happens on the full
  /// resolution photograph, which is far larger than anything on screen.
  ///
  /// The two fractions are measured against different edges, so they are not
  /// interchangeable. The preview box is `1 / previewAspect` wide for every 1
  /// tall, so a guide `width` across and `height` down has an on-screen shape of
  /// `width / (height * previewAspect)`. Setting that equal to the card's shape
  /// gives the line below.
  ///
  /// Multiplying by `previewAspect` where this divides — which is what it did —
  /// inflates the height by the square of the preview's aspect ratio. On a 16:9
  /// preview it asked for 0.96 and got the clamp: a tall rectangle almost the
  /// full height of the screen, which is what was on the phone.
  static Rect guideFor(double previewAspect) {
    const width = guideWidthFraction;
    final height =
        (width / (previewAspect * cardAspectRatio)).clamp(0.05, 0.9);
    return Rect.fromLTWH((1 - width) / 2, (1 - height) / 2, width, height);
  }

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

  /// The captured photo, whole, waiting for the user to frame and accept it.
  Uint8List? _pending;

  /// Where the camera plugin left the full-resolution original. The final crop
  /// is taken from that rather than from [_pending], so the kept part stays as
  /// sharp as the sensor made it.
  String? _shotPath;

  /// Width over height of [_pending], needed to lay the photo out at its own
  /// shape so the crop rectangle's fractions mean what they say.
  double _photoAspect = 3 / 4;

  /// The crop, as fractions of the photo.
  Rect _crop = const Rect.fromLTWH(0.07, 0.3, 0.86, 0.4);

  /// Which corner is being dragged, if any. Null while the whole rectangle is
  /// being moved instead.
  CropCorner? _dragging;

  /// A rectangle to start from: card-shaped, centred, most of the width. It is
  /// only a starting point — the whole purpose of this screen is that the user
  /// can move it.
  static Rect _defaultCrop(double photoAspect) {
    const width = GuidedCameraScreen.guideWidthFraction;
    // Same reasoning as the preview guide: the two fractions are measured
    // against different edges, so the height is divided by the photo's shape.
    final height =
        (width * photoAspect / GuidedCameraScreen.cardAspectRatio)
            .clamp(0.05, 0.95);
    return Rect.fromLTWH((1 - width) / 2, (1 - height) / 2, width, height);
  }

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
    //
    // `paused`, not `inactive`. `inactive` also fires for a dialog on top of the
    // app — including Android's own camera permission dialog, which this screen
    // raises itself. Tearing the controller down there disposed it in the middle
    // of the very `initialize()` call that was asking for the permission, and the
    // screen came back saying Karde had no camera access seconds after the user
    // had granted it.
    if (state == AppLifecycleState.paused) {
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _start();
    }
  }

  Future<void> _start() async {
    // Cleared on every attempt. Latching it meant one failed start — a permission
    // dialog interrupting the first one, say — left the "no camera access" screen
    // up for good, even after a later attempt had succeeded.
    if (_unavailable && mounted) setState(() => _unavailable = false);
    // Starting the camera is what raises Android's permission dialog, and that
    // dialog takes the foreground — which the auto-lock timer cannot tell apart
    // from the user walking away. Without this, granting the permission dropped
    // the user on the PIN screen with a half-filled card behind it.
    await SystemInteractionGuard.run(_startCamera);
  }

  Future<void> _startCamera() async {
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

  double get _previewAspect => _controller?.value.aspectRatio ?? (4 / 3);

  Rect get _guide => GuidedCameraScreen.guideFor(_previewAspect);

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _busy) return;

    setState(() => _busy = true);
    try {
      final shot = await controller.takePicture();
      // Shown whole, and cropped only once the user has placed the rectangle on
      // the photograph itself. The guide on the preview cannot be trusted to
      // name a part of the still: on the S23 Ultra the two have different fields
      // of view, and nothing visible from here can measure the difference.
      final bytes = await _images.prepareCapture(shot.path);
      final size = await decodeImageFromList(bytes);
      if (!mounted) return;
      setState(() {
        _shotPath = shot.path;
        _pending = bytes;
        _photoAspect = size.width / size.height;
        _crop = _defaultCrop(_photoAspect);
      });
      size.dispose();
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

  /// Smallest the crop may be shrunk to, as a fraction of each edge. Small
  /// enough to pull one field off a document, large enough that the rectangle
  /// cannot be collapsed to nothing and lost.
  static const double _minCrop = 0.12;

  /// How close to a corner a finger has to land to be dragging that corner
  /// rather than moving the whole rectangle. In fractions of the photo's
  /// shorter behaviour on screen this is roughly a fingertip.
  static const double _grab = 0.12;

  void _onPanStart(Offset local, Size box) {
    final point = Offset(local.dx / box.width, local.dy / box.height);
    _dragging = CropCorner.nearest(_crop, point, _grab);
  }

  void _onPanUpdate(Offset delta, Size box) {
    final move = Offset(delta.dx / box.width, delta.dy / box.height);
    setState(() {
      _crop = _dragging == null
          ? _shift(_crop, move)
          : _dragging!.resize(_crop, move, _minCrop);
    });
  }

  /// Moves the whole rectangle, kept inside the photo. Clamped rather than
  /// stopped, so dragging past an edge slides along it instead of sticking.
  static Rect _shift(Rect crop, Offset by) {
    final left = (crop.left + by.dx).clamp(0.0, 1 - crop.width);
    final top = (crop.top + by.dy).clamp(0.0, 1 - crop.height);
    return Rect.fromLTWH(left, top, crop.width, crop.height);
  }

  Future<void> _useCrop() async {
    final path = _shotPath;
    if (path == null || _busy) return;

    setState(() => _busy = true);
    try {
      final bytes = await _images.cropCapture(
        path: path,
        left: _crop.left,
        top: _crop.top,
        width: _crop.width,
        height: _crop.height,
      );
      if (mounted) Navigator.pop(context, bytes);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.cameraCaptureFailed)),
        );
      }
    }
  }

  Future<void> _retake() async {
    final path = _shotPath;
    setState(() {
      _pending = null;
      _shotPath = null;
    });
    if (path != null) await _images.discardCapture(path);
  }

  Widget _buildConfirm(AppLocalizations loc) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: AspectRatio(
                // The photo is laid out at its own shape, which is what makes
                // the rectangle's fractions exact: what is inside it on screen
                // is the same fraction of the file.
                aspectRatio: _photoAspect,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final box = constraints.biggest;
                    return GestureDetector(
                      onPanStart: (d) => _onPanStart(d.localPosition, box),
                      onPanUpdate: (d) => _onPanUpdate(d.delta, box),
                      onPanEnd: (_) => _dragging = null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(_pending!, fit: BoxFit.fill),
                            CustomPaint(painter: _CropPainter(_crop)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            loc.cameraCropHint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _retake,
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
                  onPressed: _busy ? null : _useCrop,
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

/// Which corner of the crop rectangle a drag has hold of.
///
/// Public only so the clamping can be tested: a corner dragged past its
/// opposite must stop at the minimum size rather than invert the rectangle.
enum CropCorner {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight;

  /// The corner within [reach] of [point], or null if the finger landed in the
  /// middle — which means the whole rectangle is being moved.
  static CropCorner? nearest(Rect crop, Offset point, double reach) {
    CropCorner? best;
    var closest = reach;
    for (final corner in CropCorner.values) {
      final distance = (corner._at(crop) - point).distance;
      if (distance < closest) {
        closest = distance;
        best = corner;
      }
    }
    return best;
  }

  Offset _at(Rect crop) => switch (this) {
        CropCorner.topLeft => crop.topLeft,
        CropCorner.topRight => crop.topRight,
        CropCorner.bottomLeft => crop.bottomLeft,
        CropCorner.bottomRight => crop.bottomRight,
      };

  /// Moves this corner by [by], holding the opposite corner still and refusing
  /// to let the rectangle turn inside out or shrink below [min].
  Rect resize(Rect crop, Offset by, double min) {
    var left = crop.left;
    var top = crop.top;
    var right = crop.right;
    var bottom = crop.bottom;

    switch (this) {
      case CropCorner.topLeft:
        left = (crop.left + by.dx).clamp(0.0, right - min);
        top = (crop.top + by.dy).clamp(0.0, bottom - min);
      case CropCorner.topRight:
        right = (crop.right + by.dx).clamp(left + min, 1.0);
        top = (crop.top + by.dy).clamp(0.0, bottom - min);
      case CropCorner.bottomLeft:
        left = (crop.left + by.dx).clamp(0.0, right - min);
        bottom = (crop.bottom + by.dy).clamp(top + min, 1.0);
      case CropCorner.bottomRight:
        right = (crop.right + by.dx).clamp(left + min, 1.0);
        bottom = (crop.bottom + by.dy).clamp(top + min, 1.0);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}

/// Dims what the crop will throw away and marks the corners that can be pulled.
class _CropPainter extends CustomPainter {
  const _CropPainter(this.crop);

  final Rect crop;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      crop.left * size.width,
      crop.top * size.height,
      crop.right * size.width,
      crop.bottom * size.height,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRect(rect),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.62),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..color = KardeColors.champagneGold.withValues(alpha: 0.9)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Solid discs, not brackets. On the preview the brackets were a guide to
    // aim at; here they are something to put a finger on, and they have to look
    // like it.
    final handle = Paint()..color = KardeColors.champagneGold;
    final ring = Paint()
      ..color = KardeColors.obsidian
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final at in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawCircle(at, 11, handle);
      canvas.drawCircle(at, 11, ring);
    }
  }

  @override
  bool shouldRepaint(_CropPainter oldDelegate) => oldDelegate.crop != crop;
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
