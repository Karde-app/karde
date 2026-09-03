class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateCardNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Card number is required';
    }
    
    String normalized = value.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^\d+$').hasMatch(normalized)) {
      return 'Card number must contain only digits';
    }
    
    if (normalized.length < 13 || normalized.length > 19) {
      return 'Invalid card length';
    }

    if (!_luhnCheck(normalized)) {
      return 'Invalid card number';
    }

    return null;
  }

  static bool _luhnCheck(String cardNumber) {
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

  static String? validateExpiry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Expiry date is required';
    }
    
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Format must be MM/YY';
    }

    final parts = value.split('/');
    final month = int.tryParse(parts[0]);
    final yearStr = parts[1];
    
    if (month == null || month < 1 || month > 12) {
      return 'Invalid month';
    }

    final now = DateTime.now();
    final currentYear = now.year % 100;
    final year = int.parse(yearStr);

    if (year < currentYear || (year == currentYear && month < now.month)) {
      return 'Card has expired';
    }

    return null;
  }

  static String? validateCvv(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CVV is required';
    }
    
    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return 'CVV must be 3 or 4 digits';
    }
    
    return null;
  }
}
