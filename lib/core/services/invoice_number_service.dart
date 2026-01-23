import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengelola nomor kwitansi auto-increment per jenis
class InvoiceNumberService {
  static const _keyPrefix = 'invoice_seq_';

  /// Jenis kwitansi
  static const kasir = 'KASIR';
  static const po = 'PO';
  static const snackBox = 'SB';
  static const paketan = 'PK';

  /// Get next invoice number for type and current month
  static Future<String> getNextNumber(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final monthKey = '${now.year}_${now.month}';
    final key = '$_keyPrefix${type}_$monthKey';

    // Get current sequence for this type and month
    int sequence = prefs.getInt(key) ?? 0;
    sequence++;

    // Save new sequence
    await prefs.setInt(key, sequence);

    // Format: 0001/PO/I/2026 or 0001/I/2026 (for kasir)
    final seqStr = sequence.toString().padLeft(4, '0');
    final monthRoman = _romanMonth(now.month);

    if (type == kasir) {
      return '$seqStr/$monthRoman/${now.year}';
    } else {
      return '$seqStr/$type/$monthRoman/${now.year}';
    }
  }

  /// Preview next number without incrementing
  static Future<String> previewNextNumber(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final monthKey = '${now.year}_${now.month}';
    final key = '$_keyPrefix${type}_$monthKey';

    int sequence = prefs.getInt(key) ?? 0;
    sequence++;

    final seqStr = sequence.toString().padLeft(4, '0');
    final monthRoman = _romanMonth(now.month);

    if (type == kasir) {
      return '$seqStr/$monthRoman/${now.year}';
    } else {
      return '$seqStr/$type/$monthRoman/${now.year}';
    }
  }

  /// Get current sequence for a type (without incrementing)
  static Future<int> getCurrentSequence(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final monthKey = '${now.year}_${now.month}';
    final key = '$_keyPrefix${type}_$monthKey';
    return prefs.getInt(key) ?? 0;
  }

  /// Reset sequence for a type (for testing/admin)
  static Future<void> resetSequence(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final monthKey = '${now.year}_${now.month}';
    final key = '$_keyPrefix${type}_$monthKey';
    await prefs.setInt(key, 0);
  }

  static String _romanMonth(int month) {
    const romans = [
      'I',
      'II',
      'III',
      'IV',
      'V',
      'VI',
      'VII',
      'VIII',
      'IX',
      'X',
      'XI',
      'XII',
    ];
    return romans[month - 1];
  }
}
