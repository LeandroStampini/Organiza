import 'package:flutter_test/flutter_test.dart';
import 'package:projeto/screens/models.dart';

void main() {
  test('formatMoney usa o padrão brasileiro', () {
    expect(formatMoney(0), 'R\$ 0,00');
    expect(formatMoney(12.5), 'R\$ 12,50');
    expect(formatMoney(1234.56), 'R\$ 1.234,56');
    expect(formatMoney(1000000), 'R\$ 1.000.000,00');
  });

  test('parsePrice aceita vírgula, ponto e milhar', () {
    expect(parsePrice('12,50'), 12.5);
    expect(parsePrice('12.50'), 12.5);
    expect(parsePrice('R\$ 1.234,56'), 1234.56);
    expect(parsePrice(''), 0);
    expect(parsePrice('abc'), 0);
    expect(priceToText(5.5), '5,50');
    expect(priceToText(0), '');
  });

  test('nextCode é sequencial e ignora códigos de barras', () {
    expect(nextCode([]), '0001');
    expect(nextCode(['0001', '0007', 'ABC']), '0008');
    expect(nextCode(['7891234567890', '0002']), '0003');
  });
}
