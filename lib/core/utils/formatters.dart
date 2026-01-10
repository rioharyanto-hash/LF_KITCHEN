import 'package:intl/intl.dart';

/// Centralized formatters untuk konsistensi di seluruh aplikasi
class AppFormatters {
  AppFormatters._();

  /// Currency formatter untuk Rupiah
  static final currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format tanggal lengkap: Senin, 01 Jan 2026
  static final dateFullDay = DateFormat('EEEE, dd MMM yyyy', 'id_ID');

  /// Format tanggal pendek: 01/01/26
  static final dateShort = DateFormat('dd/MM/yy', 'id_ID');

  /// Format tanggal medium: 01 Jan 2026
  static final dateMedium = DateFormat('dd MMM yyyy', 'id_ID');

  /// Format tanggal ISO: 2026-01-01
  static final dateIso = DateFormat('yyyy-MM-dd');

  /// Format waktu: 14:30
  static final time = DateFormat('HH:mm', 'id_ID');

  /// Format tanggal dan waktu: 01 Jan 2026, 14:30
  static final dateTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  /// Helper untuk format currency dari double
  static String formatCurrency(double amount) => currency.format(amount);

  /// Helper untuk format tanggal
  static String formatDate(DateTime date, {DateFormat? format}) {
    return (format ?? dateMedium).format(date);
  }
}
