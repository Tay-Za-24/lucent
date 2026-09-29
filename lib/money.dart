import 'package:intl/intl.dart';

/// True minus sign (U+2212) used for negative amounts.
const minus = '\u2212';

/// Formats minor units as a number string, e.g. 123456 -> "1,234.56".
String formatNumber(int minor, int decimals) {
  final f = NumberFormat(decimals == 0 ? '#,##0' : '#,##0.00', 'en_US');
  final v = decimals == 0 ? minor.abs() : minor.abs() / 100;
  return f.format(v);
}

/// "K 1,234" / "−K 1,234" / "+K 1,234".
String formatMoney(int minor, String symbol, int decimals, {bool plus = false}) {
  final sign = minor < 0 ? minus : (plus ? '+' : '');
  final sym = symbol.isEmpty ? '' : '$symbol ';
  return '$sign$sym${formatNumber(minor, decimals)}';
}

/// Parses user input into minor units. Returns null if invalid or <= 0.
int? parseAmount(String input, int decimals) {
  final s = input.replaceAll(',', '').replaceAll(' ', '').trim();
  if (s.isEmpty) return null;
  final ok = decimals == 0
      ? RegExp(r'^\d+$').hasMatch(s)
      : RegExp(r'^\d*(\.\d{0,2})?$').hasMatch(s);
  if (!ok || s == '.') return null;
  int v;
  if (decimals == 0) {
    v = int.parse(s);
  } else {
    final parts = s.split('.');
    final whole = parts[0].isEmpty ? 0 : int.parse(parts[0]);
    final frac = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
    v = whole * 100 + int.parse(frac);
  }
  return v > 0 ? v : null;
}

/// Minor units -> plain editable text ("1234.50").
String amountToInput(int minor, int decimals) =>
    decimals == 0 ? '$minor' : (minor / 100).toStringAsFixed(2);
