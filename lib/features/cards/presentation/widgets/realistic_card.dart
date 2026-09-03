import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/virtual_card.dart';
import 'card_backgrounds.dart';

class RealisticCard extends StatelessWidget {
  final VirtualCard card;
  final bool isDecrypted;
  final String? decryptedCardNumber;
  final String? decryptedExpiry;
  final String? decryptedCvv;
  final String? decryptedCardholderName;
  final VoidCallback? onTapReveal;
  final VoidCallback? onTapHide;
  final VoidCallback? onCopy;

  const RealisticCard({
    super.key,
    required this.card,
    this.isDecrypted = false,
    this.decryptedCardNumber,
    this.decryptedExpiry,
    this.decryptedCvv,
    this.decryptedCardholderName,
    this.onTapReveal,
    this.onTapHide,
    this.onCopy,
  });

  String _formatCardNumber(String number) {
    return number.replaceAllMapped(RegExp(r'.{1,4}'), (match) => '${match.group(0)} ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final String brand = card.cardBrand.toLowerCase();
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
          gradient: backgroundGradient,
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        // Clip to ensure pattern doesn't bleed outside rounded corners
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (patternPainter != null)
              Positioned.fill(
                child: CustomPaint(painter: patternPainter),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row (Issuer text)
                  if (isVisa || isMastercard)
                    Text(
                      card.nickname, // Issuer
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Credit Card',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          card.nickname, // Issuer
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                  // Chip & Reveal Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 45,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9A961),
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE7D4A0), Color(0xFF9C7C41)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CustomPaint(painter: _ChipPainter()),
                      ),
                      if (onTapReveal != null || onTapHide != null)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: isDecrypted ? onTapHide : onTapReveal,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isDecrypted ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFFC9A961),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  

                  // Card Number Area
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            isDecrypted && decryptedCardNumber != null
                                ? _formatCardNumber(decryptedCardNumber!)
                                : '••••  ••••  ••••  ${card.lastFourDigits}',
                            style: TextStyle(
                              color: const Color(0xFFF4F1EA),
                              fontSize: isDecrypted ? 22 : 20,
                              letterSpacing: isDecrypted ? 2 : 4,
                              fontFamily: 'Roboto Mono',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      if (isDecrypted && onCopy != null) ...[
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: onCopy,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.copy,
                                color: Color(0xFFC9A961),
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                  
                  // Bottom Row: Details and Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CARDHOLDER',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Color(0xFF9AA1B0),
                                      fontSize: 9,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      decryptedCardholderName?.isNotEmpty == true
                                          ? decryptedCardholderName!.toUpperCase()
                                          : 'NAME SURNAME',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: Color(0xFFF4F1EA),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'EXPIRES',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Color(0xFF9AA1B0),
                                      fontSize: 9,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isDecrypted && decryptedExpiry != null ? decryptedExpiry! : '••/••',
                                    style: const TextStyle(
                                      fontFamily: 'Roboto Mono',
                                      color: Color(0xFFF4F1EA),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isDecrypted && decryptedCvv != null) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'CVV',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: Color(0xFF9AA1B0),
                                        fontSize: 9,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      decryptedCvv!,
                                      style: const TextStyle(
                                        fontFamily: 'Roboto Mono',
                                        color: Color(0xFFF4F1EA),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      if (brandIconWidget != null) ...[
                        const SizedBox(width: 12),
                        brandIconWidget,
                      ]
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
