enum QrType { upi, cryptoWallet, productBarcode, unknown }

class QrClassifier {
  QrClassifier._();

  static QrType classify(String rawValue) {
    final trimmed = rawValue.trim();

    if (trimmed.startsWith('upi://')) return QrType.upi;
    if (trimmed.startsWith('0x') && trimmed.length == 42) return QrType.cryptoWallet;
    if (trimmed.startsWith('ethereum:')) return QrType.cryptoWallet;
    if (RegExp(r'^[0-9]{8,14}$').hasMatch(trimmed)) return QrType.productBarcode;

    return QrType.unknown;
  }

  static Map<String, String> parseUpi(String upiString) {
    final uri = Uri.parse(upiString);
    return {
      'pa': uri.queryParameters['pa'] ?? '',
      'pn': uri.queryParameters['pn'] ?? '',
      'am': uri.queryParameters['am'] ?? '',
      'cu': uri.queryParameters['cu'] ?? 'INR',
      'tn': uri.queryParameters['tn'] ?? '',
    };
  }

  static String? parseWalletAddress(String raw) {
    if (raw.startsWith('ethereum:')) {
      final address = raw.replaceFirst('ethereum:', '').split('?').first;
      return address;
    }
    if (raw.startsWith('0x') && raw.length == 42) {
      return raw;
    }
    return null;
  }
}
