import 'package:flutter/services.dart';
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
  final s = normalizeDigits(input).replaceAll(RegExp(r'[,\s\u00a0\u202f]'), '').trim();
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

/// Maps Myanmar, Arabic-Indic, Persian and full-width digits to 0-9, so
/// amounts typed on any keyboard are understood.
String normalizeDigits(String input) {
  const zeros = [0x1040, 0x0660, 0x06F0, 0xFF10, 0x0966];
  final out = StringBuffer();
  for (final r in input.runes) {
    var mapped = r;
    for (final z in zeros) {
      if (r >= z && r <= z + 9) mapped = 0x30 + r - z;
    }
    if (r == 0xFF0C || r == 0x066C) mapped = 0x2C; // full-width / Arabic comma
    if (r == 0xFF0E || r == 0x066B) mapped = 0x2E; // full-width / Arabic decimal point
    out.writeCharCode(mapped);
  }
  return out.toString();
}

/// Amount field filter: converts other digit scripts to 0-9, then keeps only
/// digits, commas and (when decimals are used) one decimal point.
class AmountInputFormatter extends TextInputFormatter {
  AmountInputFormatter(this.decimals);
  final int decimals;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final allowed = decimals > 0 ? RegExp(r'[0-9.,]') : RegExp(r'[0-9,]');
    final text = normalizeDigits(
      newValue.text,
    ).split('').where((ch) => allowed.hasMatch(ch)).join();
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
