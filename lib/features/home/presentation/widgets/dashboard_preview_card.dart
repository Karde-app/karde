import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/theme.dart';
import '../../../cards/domain/virtual_card.dart';
import '../../../cards/presentation/widgets/card_backgrounds.dart';
import '../../../../core/security/encryption_service.dart';

/// What a covered field shows on a card preview.
///
/// These fields used to print the words "CARDHOLDER" and "NAME SURNAME",
/// which read as real-but-wrong data rather than as something withheld. Both
/// were the first thing in frame on the store screenshots, and the mask cannot
/// be lifted here — the full details only open on the card detail page. Dots
/// match how the card number is already covered, so the card now reads as
/// deliberately hidden rather than broken.
const String _hiddenValue = '••••••••';

class DashboardPreviewCard extends StatefulWidget {
  final VirtualCard card;
  final bool isFront;

  const DashboardPreviewCard({
    super.key,
    required this.card,
    this.isFront = true,
  });

  @override
  State<DashboardPreviewCard> createState() => _DashboardPreviewCardState();
}

class _DashboardPreviewCardState extends State<DashboardPreviewCard> {
  // FIX 2-1: this preview no longer decrypts anything. It previously decrypted
  // the cardholder name on initState (and again on didUpdateWidget), which under
  // per-use key authentication would fire an OS prompt just to paint the home
  // screen. It also displayed real PII on the dashboard before the user had
  // authenticated. The preview now shows only the masked placeholder; the real
  // name appears after an explicit reveal in the vault or details screen.
  String? get _cardholderName => null;

  @override
  Widget build(BuildContext context) {
    final String brand = widget.card.cardBrand.toLowerCase();
    final bool isVisa = brand == 'visa';
    final bool isMastercard = brand == 'mastercard';

    final LinearGradient backgroundGradient;
    if (isVisa) {
      backgroundGradient = const LinearGradient(
        colors: [Color(0xFF1A2552), Color(0xFF0B132B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (isMastercard) {
      backgroundGradient = const LinearGradient(
        colors: [Color(0xFF242D3C), Color(0xFF161C26)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      backgroundGradient = const LinearGradient(
        colors: [Color(0xFF2A2F3B), Color(0xFF0D0F14)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    final CustomPainter? patternPainter;
    if (isVisa) patternPainter = VisaPatternPainter();
    else if (isMastercard) patternPainter = MastercardPatternPainter();
    else patternPainter = null;

    Widget? brandIconWidget;
    if (isVisa) {
      brandIconWidget = Image.asset('assets/icons/visa_icon.png', height: 40);
    } else if (isMastercard) {
      brandIconWidget = Image.asset('assets/icons/mastercard_icon.png', height: 48);
    }

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(0.05)
        ..rotateY(0.03),
      alignment: FractionalOffset.center,
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: widget.isFront ? backgroundGradient : null,
          color: widget.isFront ? null : const Color(0xFF2C3241),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (widget.isFront && patternPainter != null)
              Positioned.fill(
                child: CustomPaint(painter: patternPainter),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chip
                      Container(
                        width: 45,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.isFront ? const Color(0xFFC9A961) : const Color(0xFFC9A961).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                          gradient: widget.isFront
                              ? const LinearGradient(
                                  colors: [Color(0xFFE7D4A0), Color(0xFF9C7C41)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                        ),
                        child: widget.isFront
                            ? CustomPaint(painter: _ChipPainter())
                            : Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(width: 1, height: double.infinity, color: KardeColors.champagneGold.withOpacity(0.5)),
                                    Container(width: 1, height: double.infinity, color: KardeColors.champagneGold.withOpacity(0.5)),
                                  ],
                                ),
                              ),
                      ),
                      // Reveal Icon
                      if (widget.isFront)
                        Icon(
                          Icons.visibility,
                          color: KardeColors.champagneGold.withOpacity(0.8),
                          size: 24,
                        ),
                    ],
                  ),
                  
                  // Top Text (Issuer / Bank Name / Brand)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.isFront && !isVisa && !isMastercard)
                        Text(
                          AppLocalizations.of(context)!.creditCard,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        )
                      else if (widget.isFront && (isVisa || isMastercard))
                        Text(
                          widget.card.nickname, // Issuer
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        )
                      else if (!widget.isFront)
                        Text(
                          widget.card.cardBrand.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: 1.5,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        )
                      else
                        const SizedBox(),
                      
                      if (widget.isFront && !isVisa && !isMastercard)
                        Text(
                          widget.card.nickname, // Bank Name
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '• • • •   • • • •   • • • •   ${widget.card.lastFourDigits}',
                      style: TextStyle(
                        fontFamily: 'Roboto Mono',
                        fontSize: 22,
                        letterSpacing: 2,
                        color: widget.isFront ? Colors.white : Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CARDHOLDER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: widget.isFront ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _cardholderName?.isNotEmpty == true 
                                    ? _cardholderName!.toUpperCase() 
                                    : _hiddenValue,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                  color: widget.isFront ? Colors.white : Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isFront && brandIconWidget != null) ...[
                        brandIconWidget,
                      ] else ...[
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'EXPIRES',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                  color: widget.isFront ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• • / • •',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Roboto Mono',
                                  letterSpacing: 1,
                                  color: widget.isFront ? Colors.white : Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    final double w = size.width;
    final double h = size.height;
    
    path.moveTo(0, h * 0.5);
    path.lineTo(w, h * 0.5);
    path.moveTo(w * 0.3, 0);
    path.lineTo(w * 0.3, h * 0.2);
    path.moveTo(w * 0.3, h * 0.8);
    path.lineTo(w * 0.3, h);
    path.moveTo(w * 0.7, 0);
    path.lineTo(w * 0.7, h * 0.2);
    path.moveTo(w * 0.7, h * 0.8);
    path.lineTo(w * 0.7, h);

    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.3, h * 0.2, w * 0.4, h * 0.6),
      const Radius.circular(4),
    ));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
