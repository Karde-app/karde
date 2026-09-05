import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../domain/virtual_id.dart';

class RealisticIdCard extends StatelessWidget {
  final VirtualId idDoc;
  final bool isDecrypted;
  final Map<String, String>? decryptedData;
  final VoidCallback? onTapReveal;
  final VoidCallback? onTapHide;

  /// The document photo, decoded alongside the fields when the card is revealed.
  /// Null while the document is masked, or when it has no photo.
  final Uint8List? photo;

  /// Called when a revealed portrait is tapped, to enlarge it. Costs nothing —
  /// the photo came out of the same ciphertext as the fields, so it is already
  /// in hand by the time it can be tapped.
  final VoidCallback? onTapPhoto;

  const RealisticIdCard({
    super.key,
    required this.idDoc,
    this.isDecrypted = false,
    this.decryptedData,
    this.onTapReveal,
    this.onTapHide,
    this.photo,
    this.onTapPhoto,
  });

  /// The portrait slot every template draws.
  ///
  /// Two states: the photo, once the document has been revealed, and the generic
  /// silhouette the rest of the time. There is no third "locked photo" state,
  /// because the photo is not separately locked — it comes out of the same
  /// ciphertext as the fields, so whatever unmasks the text unmasks the picture.
  /// Templates differ only in size and corner radius, so they pass those in
  /// rather than each growing their own copy of this logic.
  Widget _buildPhotoSlot({
    required double iconSize,
    required double radius,
    double? height,
  }) {
    final Widget content;
    if (photo != null) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.memory(
          photo!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stack) =>
              Icon(Icons.broken_image_outlined, size: iconSize, color: Colors.white),
        ),
      );
    } else {
      content = Icon(Icons.person, size: iconSize, color: Colors.white);
    }

    final slot = SizedBox(
      height: height,
      width: double.infinity,
      child: Center(child: content),
    );

    // Only tappable when there is actually a photo on screen to enlarge.
    if (photo == null || onTapPhoto == null) return slot;
    return GestureDetector(onTap: onTapPhoto, child: slot);
  }

  String _getDecryptedValue(String key, String hiddenPlaceholder) {
    if (!isDecrypted) return hiddenPlaceholder;
    final val = decryptedData?[key];
    if (val == null || val.trim().isEmpty) return 'N/A';
    return val;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildTemplate(context),
        // One position for the reveal control, on every template and matching
        // the card. Each of the five templates used to draw its own inside its
        // own header, so the button moved as the user paged between documents —
        // and it never lined up with where it sits on a card.
        if (onTapReveal != null || onTapHide != null)
          Positioned(top: 14, right: 14, child: _buildRevealButton()),
      ],
    );
  }

  Widget _buildTemplate(BuildContext context) {
    final type = idDoc.idType.toLowerCase();
    if (type == 'passport') {
      return _buildPassportTemplate(context);
    } else if (type == 'resident permit') {
      return _buildResidentPermitTemplate(context);
    } else if (type == 'national id') {
      return _buildNationalIdTemplate(context);
    } else if (type == "driver's license" || type == 'driving licence' || type == 'driving license') {
      return _buildDrivingLicenseTemplate(context);
    }
    return _buildGenericTemplate(context);
  }

  /// The reveal / hide control.
  ///
  /// Dark translucent rather than tinted per template: the ID faces are all pale,
  /// so one dark chip stays legible on every one of them without needing to know
  /// which template is underneath.
  Widget _buildRevealButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isDecrypted ? onTapHide : onTapReveal,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDecrypted ? Icons.visibility_off : Icons.visibility,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildPassportTemplate(BuildContext context) {
    final title = 'INTERNATIONAL PASSPORT';
    
    final fullName = _getDecryptedValue('fullName', '••••••••••••').toUpperCase();
    final names = fullName.split(' ');
    final surname = names.isNotEmpty ? names.last : 'N/A';
    final givenNames = names.length > 1 ? names.sublist(0, names.length - 1).join(' ') : fullName;
    
    final dob = _getDecryptedValue('dateOfBirth', '••/••/••••');
    final issueDate = _getDecryptedValue('issueDate', '••/••/••••');
    final expiryDate = _getDecryptedValue('expiryDate', '••/••/••••');
    final documentNumber = _getDecryptedValue('documentNumber', '••••••••••••');
    final sex = _getDecryptedValue('sexGender', '•');
    final placeOfBirth = _getDecryptedValue('placeOfBirth', '••••••').toUpperCase();
    final authority = _getDecryptedValue('issuingAuthority', '••••••').toUpperCase();

    // Generating fake MRZ
    final mrzLine1 = 'P<<$surname<<$givenNames<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'.replaceAll(' ', '<').substring(0, 44);
    final mrzLine2 = '$documentNumber<0XXX000000X${sex}0000000<<<<<<<<<<<<<<00'.substring(0, 44);

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F1F2), Color(0xFFD4E6E8)], // Pale teal passport bg
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10))],
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _WavePatternPainter())),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter', color: Color(0xFF1F487E), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Top subheader row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 60), // Removed PASSPORT/PASSEPORT text
                    _buildLabelText('TYPE\nP', size: 6, align: TextAlign.center),
                    _buildLabelText('CODE OF ISSUING STATE\nXXX', size: 6, align: TextAlign.center),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildLabelText('PASSPORT NO.', size: 6),
                        Text(
                          documentNumber, 
                          style: const TextStyle(fontFamily: 'Roboto Mono', color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 75,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9DEE5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF1F487E).withOpacity(0.3), width: 1),
                        ),
                        child: _buildPhotoSlot(iconSize: 54, radius: 3),
                      ),
                      const SizedBox(width: 12),
                      
                      // Details Grid
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabelText('SURNAME', size: 6),
                            _buildValueText(surname, size: 12, fontHeight: 1.0),
                            
                            _buildLabelText('GIVEN NAMES', size: 6),
                            _buildValueText(givenNames, size: 12, fontHeight: 1.0),
                            
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabelText('NATIONALITY', size: 6),
                                      _buildValueText(authority, size: 10, fontHeight: 1.0),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabelText('DATE OF BIRTH', size: 6),
                                      _buildValueText(dob, size: 10, fontHeight: 1.0),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            Row(
                              children: [
                                Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabelText('SEX', size: 6), _buildValueText(sex, size: 10, fontHeight: 1.0)])),
                                Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabelText('PLACE OF BIRTH', size: 6), _buildValueText(placeOfBirth, size: 10, fontHeight: 1.0)])),
                                Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabelText('AUTHORITY', size: 6), _buildValueText(authority, size: 10, fontHeight: 1.0)])),
                              ],
                            ),
                            
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabelText('DATE OF ISSUE', size: 6),
                                      _buildValueText(issueDate, size: 10, fontHeight: 1.0),
                                      _buildLabelText('DATE OF EXPIRY', size: 6),
                                      _buildValueText(expiryDate, size: 10, fontHeight: 1.0),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    _buildLabelText('HOLDERS SIGNATURE', size: 6),
                                    const Text('Signature', style: TextStyle(fontFamily: 'Autography', fontStyle: FontStyle.italic, color: Color(0xFF1F487E), fontSize: 13, height: 1)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 4),
                // MRZ
                Container(
                  color: Colors.white.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mrzLine1, style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 10, color: Colors.black87, letterSpacing: 1.5, height: 1.0), maxLines: 1),
                        Text(mrzLine2, style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 10, color: Colors.black87, letterSpacing: 1.5, height: 1.0), maxLines: 1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentPermitTemplate(BuildContext context) {
    final title = idDoc.idType.toUpperCase();
    
    final name = _getDecryptedValue('fullName', '••••••••••••').toUpperCase();
    final dob = _getDecryptedValue('dateOfBirth', '••/••/••••');
    final sex = _getDecryptedValue('sexGender', '•');
    final issueDate = _getDecryptedValue('issueDate', '••/••/••••');
    final expiryDate = _getDecryptedValue('expiryDate', '••/••/••••');
    final documentNumber = _getDecryptedValue('documentNumber', '••••••••••••');
    final bloodGroup = _getDecryptedValue('bloodGroup', '••');
    final authority = _getDecryptedValue('issuingAuthority', '••••••').toUpperCase();

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFE2EAF4), Color(0xFFC7D6E8)], // Ice blue gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10))],
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _WavePatternPainter())),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header & Reveal Icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title.isNotEmpty ? title : 'BIOMETRIC RESIDENCE PERMIT',
                        style: const TextStyle(
                          fontFamily: 'Inter', color: Color(0xFF1B3B6F), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar & Fake Chip
                      Column(
                        children: [
                          Container(
                            width: 25, height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5C158),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.black12),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 75, height: 95,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD9DEE5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF1B3B6F).withOpacity(0.3), width: 1),
                            ),
                            child: _buildPhotoSlot(iconSize: 54, radius: 5),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      
                      // Details Grid
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPermitRow('Name', name),
                            const SizedBox(height: 1),
                            _buildPermitRow('Date of Birth', dob),
                            const SizedBox(height: 1),
                            _buildPermitRow('Nationality', authority),
                            const SizedBox(height: 1),
                            _buildPermitRow('Gender', sex),
                            const SizedBox(height: 1),
                            _buildPermitRow('Blood Group', bloodGroup),
                            const SizedBox(height: 1),
                            _buildPermitRow('Issue Date', issueDate),
                            const SizedBox(height: 1),
                            _buildPermitRow('Expiry Date', expiryDate),
                            const SizedBox(height: 1),
                            _buildPermitRow('Document No.', documentNumber),
                          ],
                        ),
                      ),
                      
                      // Right side widgets (Flag, Signature)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.gpp_good_rounded, color: const Color(0xFF1B3B6F).withOpacity(0.8), size: 32),
                          const SizedBox(height: 24),
                          Container(
                            width: 60, height: 25,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Center(
                              child: Text('Signature', style: TextStyle(fontFamily: 'Autography', color: Color(0xFF1B3B6F), fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Bottom Barcode String
                Container(
                  color: Colors.white.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'IR$documentNumber<<<<<<<<<<<<<<<<<<${dob.replaceAll('/', '')}${sex}<<<<<<<',
                      style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 10, color: Colors.black87, letterSpacing: 1.5, height: 1.0),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermitRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF4A5568), fontSize: 8, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(fontFamily: 'Roboto Mono', color: Color(0xFF0A1128), fontSize: 10, fontWeight: FontWeight.w700, height: 1.1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNationalIdTemplate(BuildContext context) {
    final name = _getDecryptedValue('fullName', '••••••••••••').toUpperCase();
    final dob = _getDecryptedValue('dateOfBirth', '••/••/••••');
    final sex = _getDecryptedValue('sexGender', '•');
    final expiryDate = _getDecryptedValue('expiryDate', '••/••/••••');
    final documentNumber = _getDecryptedValue('documentNumber', '••••••••••••');
    final authority = _getDecryptedValue('issuingAuthority', '••••••').toUpperCase();

    final isEthiopian = authority.contains('ETHIOPIA');

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isEthiopian 
            ? const [Color(0xFFE5F1E5), Color(0xFFE8E5CE)] // Light green to pale yellow
            : const [Color(0xFFE5E7EB), Color(0xFFF3F4F6)], // Generic light gray
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10))],
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _WavePatternPainter(color: isEthiopian ? Colors.green : Colors.blueGrey),
            ),
          ),
          
          // A big star in the background right (Ethiopian only)
          if (isEthiopian)
            Positioned(
              right: 20,
              top: 40,
              child: Icon(Icons.star_border, size: 140, color: Colors.green.withOpacity(0.08)),
            ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Fake Flag or Generic Icon
                    if (isEthiopian)
                      Container(
                        width: 32, height: 20,
                        decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
                        child: Column(
                          children: [
                            Expanded(child: Container(color: const Color(0xFF009A44))),
                            Expanded(child: Container(color: const Color(0xFFFCD116), child: const Center(child: Icon(Icons.star, size: 6, color: Color(0xFF0F47AF))))),
                            Expanded(child: Container(color: const Color(0xFFCE1126))),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: 32, height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(Icons.account_balance, size: 16, color: Colors.blueGrey.shade700),
                      ),
                    
                    const SizedBox(width: 12),
                    
                    // Title
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            isEthiopian ? 'የኢትዮጵያ ዲጂታል መታወቂያ ካርድ' : (authority != '••••••' ? authority : 'NATIONAL'),
                            style: const TextStyle(color: Color(0xFF1F2937), fontSize: 10, fontWeight: FontWeight.bold, height: 1.1),
                          ),
                          Text(
                            isEthiopian ? 'Ethiopian Digital ID Card' : 'ID CARD',
                            style: const TextStyle(color: Color(0xFF1F2937), fontSize: 13, fontWeight: FontWeight.bold, height: 1.1),
                          ),
                        ],
                      ),
                    ),
                    
                    // Fake Logo
                    Row(
                      children: [
                        Container(
                          width: 24, height: 24,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1E3A8A)),
                          child: const Icon(Icons.fingerprint, size: 14, color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('National ID', style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                            if (isEthiopian)
                              const Text('ብሔራዊ መታወቂያ', style: TextStyle(fontSize: 5, color: Color(0xFF1F2937))),
                          ],
                        )
                      ],
                    ),
                    
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 85,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9DEE5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black12, width: 1),
                        ),
                        child: _buildPhotoSlot(iconSize: 64, radius: 5),
                      ),
                      const SizedBox(width: 16),
                      
                      // Details Grid
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNationalIdLabel(isEthiopian ? 'ሙሉ ስም / First, Middle, Surname' : 'FULL NAME'),
                            _buildNationalIdValue(name, size: 12),
                            const SizedBox(height: 4),
                            
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildNationalIdLabel(isEthiopian ? 'የትውልድ ቀን / Date of Birth' : 'DATE OF BIRTH'),
                                      _buildNationalIdValue(dob),
                                      const SizedBox(height: 4),
                                      
                                      _buildNationalIdLabel(isEthiopian ? 'መታወቂያው የሚያበቃበት ቀን / Date of Expiry' : 'DATE OF EXPIRY'),
                                      _buildNationalIdValue(expiryDate),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildNationalIdLabel(isEthiopian ? 'ፆታ / SEX' : 'SEX'),
                                      _buildNationalIdValue(sex),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 4),
                            _buildNationalIdLabel(isEthiopian ? 'ዜግነት (በተገለጸው መሠረት) / Country of Citizenship (Self-declared)' : 'ISSUING AUTHORITY'),
                            _buildNationalIdValue(
                              authority.isNotEmpty && authority != '••••••' 
                                ? authority 
                                : (isEthiopian ? 'ET' : '••••••')
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom FCN
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(isEthiopian ? 'FCN' : 'ID NO', style: const TextStyle(color: Color(0xFF927038), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
                      child: Text(
                        documentNumber,
                        style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600, letterSpacing: 1.0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNationalIdLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF6B7280), fontSize: 7, fontWeight: FontWeight.w600, height: 1.1),
    );
  }

  Widget _buildNationalIdValue(String text, {double size = 11}) {
    return Text(
      text,
      style: TextStyle(fontFamily: 'Roboto Mono', color: const Color(0xFF111827), fontSize: size, fontWeight: FontWeight.w700, height: 1.1),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDrivingLicenseTemplate(BuildContext context) {
    final title = idDoc.idType.toUpperCase();
    
    // Extract fields if decrypted
    final name = _getDecryptedValue('fullName', '••••••••••••').toUpperCase();
    final dob = _getDecryptedValue('dateOfBirth', '••/••/••••');
    final issueDate = _getDecryptedValue('issueDate', '••/••/••••');
    final expiryDate = _getDecryptedValue('expiryDate', '••/••/••••');
    final documentNumber = _getDecryptedValue('documentNumber', '••••••••••••');

    // The image has a light/off-white background
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFF4F6F9), Color(0xFFE5E9F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Pattern (simulated with a subtle gradient/curves if needed)
          Positioned.fill(
            child: CustomPaint(painter: _WavePatternPainter()),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header & Reveal Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32), // Balance for the icon
                    Expanded(
                      child: Text(
                        title.isNotEmpty ? title : 'DRIVING LICENCE',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF1B3B6F),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar placeholder
                      Container(
                        width: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9DEE5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF1B3B6F).withOpacity(0.3), width: 1),
                        ),
                        child: _buildPhotoSlot(iconSize: 64, radius: 5),
                      ),
                      const SizedBox(width: 16),
                      // Details Grid
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabelText('NAME:'),
                            Text(
                              name,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF0A1128),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabelText('DATE OF BIRTH:'),
                                      _buildValueText(dob),
                                      const SizedBox(height: 4),
                                      _buildLabelText('DATE OF EXPIRY:'),
                                      _buildValueText(expiryDate),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabelText('DATE OF ISSUE:'),
                                      _buildValueText(issueDate),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Bottom Row (Document Number and Signature)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        '${title.contains('PASSPORT') ? 'Passport No' : title.contains('DRIV') ? 'DL No' : 'Doc No'}: $documentNumber',
                        style: const TextStyle(
                          fontFamily: 'Roboto Mono',
                          color: Color(0xFF0A1128),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 90,
                      height: 35,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF1B3B6F).withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          'Signature',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF1B3B6F),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericTemplate(BuildContext context) {
    final title = idDoc.idType.toUpperCase();
    
    final name = _getDecryptedValue('fullName', '••••••••••••').toUpperCase();
    final documentNumber = _getDecryptedValue('documentNumber', '••••••••••••');
    final issueDate = _getDecryptedValue('issueDate', '••/••/••••');
    final expiryDate = _getDecryptedValue('expiryDate', '••/••/••••');

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF1A252F)], // Premium dark theme
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10))],
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 1.5), // Gold border
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _WavePatternPainter(color: Colors.white))),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title.isNotEmpty ? title : 'DOCUMENT',
                        style: const TextStyle(
                          fontFamily: 'Inter', color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Name
                Text('DOCUMENT HOLDER', style: TextStyle(fontFamily: 'Inter', color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                Text(
                  name,
                  style: const TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const Spacer(),
                
                // Details Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DOCUMENT NUMBER', style: TextStyle(fontFamily: 'Inter', color: Colors.white.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                          Text(
                            documentNumber,
                            style: const TextStyle(fontFamily: 'Roboto Mono', color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VALID FROM', style: TextStyle(fontFamily: 'Inter', color: Colors.white.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                          Text(issueDate, style: const TextStyle(fontFamily: 'Roboto Mono', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EXPIRES', style: TextStyle(fontFamily: 'Inter', color: Colors.white.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                          Text(expiryDate, style: const TextStyle(fontFamily: 'Roboto Mono', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelText(String text, {double size = 9, TextAlign align = TextAlign.start}) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontFamily: 'Inter',
        color: const Color(0xFF4A5568),
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 1.1,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildValueText(String text, {double size = 12, double fontHeight = 1.2}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Roboto Mono',
        color: const Color(0xFF0A1128),
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: fontHeight,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _WavePatternPainter extends CustomPainter {
  final Color color;

  _WavePatternPainter({this.color = const Color(0xFF1B3B6F)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    for (double i = 0; i < size.height; i += 15) {
      path.moveTo(0, i);
      path.quadraticBezierTo(size.width * 0.25, i - 15, size.width * 0.5, i);
      path.quadraticBezierTo(size.width * 0.75, i + 15, size.width, i);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
