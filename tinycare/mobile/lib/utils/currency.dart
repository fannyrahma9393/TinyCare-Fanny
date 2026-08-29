/// Safe number and currency parsing utilities.
/// Handles API responses that may return num, String, or null.
class CurrencyHelper {
  /// Safely parse any value to double.
  /// Handles: int, double, numeric String ("800000.00"), null.
  static double parseToDouble(dynamic value, {double defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      // Remove any whitespace
      final cleaned = value.trim();
      if (cleaned.isEmpty) return defaultValue;
      return double.tryParse(cleaned) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Safely parse any value to int.
  static int parseToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      final cleaned = value.trim();
      if (cleaned.isEmpty) return defaultValue;
      // Handle decimal strings like "800000.00"
      return double.tryParse(cleaned)?.toInt() ?? defaultValue;
    }
    return defaultValue;
  }

  /// Format currency in Indonesian Rupiah format.
  /// Example: 800000 -> "Rp 800.000"
  static String formatRupiah(dynamic amount) {
    final val = parseToDouble(amount);
    if (val == 0) return 'Rp 0';

    final fixed = val.toStringAsFixed(0);
    final formatted = fixed.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  /// Format currency without Rp prefix.
  static String formatAmount(dynamic amount) {
    final val = parseToDouble(amount);
    if (val == 0) return '0';

    final fixed = val.toStringAsFixed(0);
    return fixed.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  /// Safe subtraction for calculating unique digit differences.
  static double safeSubtract(dynamic a, dynamic b) {
    return parseToDouble(a) - parseToDouble(b);
  }
}
