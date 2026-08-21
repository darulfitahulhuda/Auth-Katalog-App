import 'package:intl/intl.dart';

/// Static conversion rate (USD → IDR). dummyjson prices are in US dollars;
/// the app displays them in Rupiah. In production this rate should come from
/// a currency API — this constant is the single replace point for that.
const double usdToIdrRate = 17658;

/// Formats a [num] (already IDR) as Indonesian Rupiah:
/// `1250000.toRupiah()` → `Rp1.250.000`.
extension RupiahExtension on num {
  /// Formats this value (already IDR) with thousand separators.
  String toRupiah() {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(this);
  }

  /// Converts a USD amount from the API to IDR, then formats it as Rupiah.
  /// e.g. `9.99.toRupiahFromUsd()` → `Rp159.840`.
  String toRupiahFromUsd() {
    return (this * usdToIdrRate).toRupiah();
  }
}
