import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class Validators {
  static String? validateRequired(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.requiredField;
    }
    return null;
  }

  static String? validateCardNumber(BuildContext context, String? value) {
    final loc = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return loc.requiredField;
    }
    
    String normalized = value.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^\d+$').hasMatch(normalized)) {
      return loc.numbersOnly;
    }
    
    if (normalized.length < 13 || normalized.length > 19) {
      return loc.invalidCardLength;
    }

    if (!luhnCheck(normalized)) {
      return loc.invalidCardNumber;
    }

    return null;
  }

  static bool luhnCheck(String cardNumber) {
    int sum = 0;
    bool alternate = false;
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cardNumber[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    return (sum % 10 == 0);
  }

  static String? validateExpiry(BuildContext context, String? value) {
    final loc = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return loc.requiredField;
    }
    
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return loc.invalidExpiryFormat;
    }

    final month = int.tryParse(value.split('/')[0]);

    if (month == null || month < 1 || month > 12) {
      return loc.invalidMonth;
    }

    // Deliberately NOT rejected for being in the past. An expired card is a
    // reasonable thing to keep — for records, a disputed charge, or updating a
    // subscription that still has the old number on file — and refusing to store
    // one is the app overruling its owner about their own wallet. The form shows
    // [isCardExpired] as an advisory instead.
    return null;
  }

  /// Whether a well-formed `MM/YY` expiry has already passed.
  ///
  /// Separate from validation on purpose: this drives a warning the user can
  /// read and ignore, not an error that stops them saving.
  static bool isCardExpired(String? value) {
    if (value == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) return false;
    final parts = value.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    if (month == null || year == null || month < 1 || month > 12) return false;

    final now = DateTime.now();
    final currentYear = now.year % 100;
    return year < currentYear || (year == currentYear && month < now.month);
  }

  static String? validateCvv(BuildContext context, String? value) {
    final loc = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return loc.requiredField;
    }
    
    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return loc.invalidCvvLength;
    }
    
    return null;
  }
}
