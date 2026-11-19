import 'package:financeiro_app/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('Fmt.parseValor', () {
    test('le o formato brasileiro com virgula decimal', () {
      expect(Fmt.parseValor('1.250,90'), 1250.90);
      expect(Fmt.parseValor('0,50'), 0.50);
      expect(Fmt.parseValor('1.000.000,00'), 1000000.00);
    });

    test('le o formato com ponto decimal', () {
      expect(Fmt.parseValor('1250.90'), 1250.90);
      expect(Fmt.parseValor('42'), 42.0);
    });

    test('ignora o simbolo da moeda e espacos', () {
      expect(Fmt.parseValor(r' R$ 1.250,90 '), 1250.90);
    });

    test('devolve null para entrada vazia ou invalida', () {
      expect(Fmt.parseValor(''), isNull);
      expect(Fmt.parseValor('   '), isNull);
      expect(Fmt.parseValor('abc'), isNull);
    });
  });

  group('Fmt.chaveMes e chaveData', () {
    test('monta a chave YYYY-MM com zero a esquerda', () {
      expect(Fmt.chaveMes(DateTime(2026, 1, 5)), '2026-01');
      expect(Fmt.chaveMes(DateTime(2026, 11, 30)), '2026-11');
    });

    test('monta a data YYYY-MM-DD, compativel com o DATE do SQLite', () {
      expect(Fmt.chaveData(DateTime(2026, 2, 9)), '2026-02-09');
      expect(Fmt.chaveData(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('a chave de data ordena corretamente como texto', () {
      // O banco compara datas como string, entao a ordem alfabetica
      // precisa coincidir com a ordem cronologica.
      final datas = [
        Fmt.chaveData(DateTime(2026, 11, 2)),
        Fmt.chaveData(DateTime(2026, 2, 11)),
        Fmt.chaveData(DateTime(2025, 12, 31)),
      ]..sort();
      expect(datas, ['2025-12-31', '2026-02-11', '2026-11-02']);
    });
  });

  group('Fmt.ultimoDiaDoMes', () {
    test('meses de 31, 30 e 28 dias', () {
      expect(Fmt.ultimoDiaDoMes(DateTime(2026, 1, 1)), 31);
      expect(Fmt.ultimoDiaDoMes(DateTime(2026, 4, 1)), 30);
      expect(Fmt.ultimoDiaDoMes(DateTime(2026, 2, 1)), 28);
    });

    test('fevereiro em ano bissexto tem 29 dias', () {
      expect(Fmt.ultimoDiaDoMes(DateTime(2028, 2, 1)), 29);
    });
  });

  group('Fmt.moeda', () {
    test('formata em reais com duas casas', () {
      // O intl usa espaco nao separavel entre o simbolo e o numero.
      expect(Fmt.moeda(1250.9).replaceAll(' ', ' '), r'R$ 1.250,90');
      expect(Fmt.moeda(0).replaceAll(' ', ' '), r'R$ 0,00');
    });

    test('aplica o sinal conforme o tipo', () {
      expect(Fmt.moedaComSinal(100, true), startsWith('+'));
      expect(Fmt.moedaComSinal(100, false), startsWith('-'));
    });
  });

  group('Fmt.pct', () {
    test('arredonda para inteiro', () {
      expect(Fmt.pct(79.4), '79%');
      expect(Fmt.pct(79.6), '80%');
      expect(Fmt.pct(100), '100%');
    });
  });
}
