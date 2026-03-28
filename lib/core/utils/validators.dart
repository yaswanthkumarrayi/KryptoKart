class Validators {
  Validators._();

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) return 'Enter a valid 10-digit phone number';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 4) return 'Password must be at least 4 characters';
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? validateUpi(String? value) {
    if (value == null || value.isEmpty) return 'UPI ID is required';
    if (!RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z]+$').hasMatch(value)) {
      return 'Enter a valid UPI ID (e.g., example@upi)';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) return 'Amount is required';
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) return 'Enter a valid amount';
    return null;
  }

  static String? validateBarcode(String? value) {
    if (value == null || value.isEmpty) return 'Barcode is required';
    if (!RegExp(r'^[0-9]{8,14}$').hasMatch(value)) return 'Enter a valid barcode';
    return null;
  }
}
