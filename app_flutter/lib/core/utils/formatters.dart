import 'package:intl/intl.dart';

/// Formatacoes em pt-BR, equivalentes ao number_format e date do PHP.
class Fmt {
  const Fmt._();

  static final _moeda =
      NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 2);
  static final _numero = NumberFormat('#,##0.00', 'pt_BR');
  static final _dataBr = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _mesExtenso = DateFormat("MMMM 'de' yyyy", 'pt_BR');

  /// R$ 1.234,56 -- igual a 'R$ ' . number_format($v, 2, ',', '.')
  static String moeda(num valor) => _moeda.format(valor);

  /// 1.234,56 (sem o simbolo)
  static String numero(num valor) => _numero.format(valor);

  /// Valor com sinal, como na tabela de transacoes da web (+ ou -).
  static String moedaComSinal(num valor, bool isReceita) =>
      '${isReceita ? '+' : '-'} ${moeda(valor)}';

  /// 19/11/2026
  static String data(DateTime d) => _dataBr.format(d);

  /// 11/2026
  ///
  /// Montado na mao, sem passar pelo intl: as mensagens de erro dos
  /// repositorios usam este formato, e eles precisam funcionar mesmo
  /// antes de `initializeDateFormatting` ter sido chamado.
  static String mesAno(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// novembro de 2026
  static String mesExtenso(DateTime d) {
    final s = _mesExtenso.format(d);
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Percentual inteiro, como number_format($pct, 0).
  static String pct(num valor) => '${valor.round()}%';

  /// Chave YYYY-MM usada nas consultas (equivale a DATE_FORMAT(data,'%Y-%m')).
  static String chaveMes(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  /// Data no formato do SQLite (YYYY-MM-DD), como o DATE do MySQL.
  static String chaveData(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Le uma string YYYY-MM-DD vinda do banco.
  static DateTime parseData(String iso) => DateTime.parse(iso);

  /// Converte texto digitado pelo usuario em numero, aceitando
  /// tanto "1234.56" quanto "1.234,56" (formato brasileiro).
  static double? parseValor(String texto) {
    var t = texto.trim();
    if (t.isEmpty) return null;
    t = t.replaceAll(RegExp(r'[^\d.,-]'), '');
    if (t.contains(',')) {
      // Virgula e o separador decimal: remove os pontos de milhar.
      t = t.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(t);
  }

  /// Ultimo dia do mes informado -- equivale ao date('t') do PHP.
  static int ultimoDiaDoMes(DateTime d) => DateTime(d.year, d.month + 1, 0).day;
}
