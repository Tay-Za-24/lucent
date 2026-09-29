import 'package:flutter_test/flutter_test.dart';
import 'package:lucent/money.dart';

void main() {
  test('parse amounts into minor units', () {
    expect(parseAmount('1,250', 0), 1250);
    expect(parseAmount('12.5', 2), 1250);
    expect(parseAmount('.99', 2), 99);
    expect(parseAmount('0', 0), isNull);
    expect(parseAmount('1.234', 2), isNull);
    expect(parseAmount('1.5', 0), isNull);
  });

  test('format money', () {
    expect(formatMoney(125000, 'K', 0), 'K 125,000');
    expect(formatMoney(-1250, '\$', 2), '\u2212\$ 12.50');
    expect(formatMoney(500, 'K', 0, plus: true), '+K 500');
  });
}
