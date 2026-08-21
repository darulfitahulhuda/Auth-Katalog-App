import 'package:intl/intl.dart';

/// Formats [value] as Indonesian Rupiah: `1250000` → `Rp1.250.000`.
String formatRupiah(num value) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  return formatter.format(value);
}