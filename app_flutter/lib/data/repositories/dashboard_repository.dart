import 'package:sqflite/sqflite.dart';

import '../../core/utils/formatters.dart';
import '../database/app_database.dart';
import '../models/models.dart';
import 'categoria_repository.dart';
import 'meta_repository.dart';
import 'recorrencia_repository.dart';

/// Consultas agregadas do painel e dos relatorios.
/// Equivale ao `dashboard.php` e ao `relatorios.php`.
class DashboardRepository {
  const DashboardRepository();

  Future<Database> get _db => AppDatabase.instance.db;

  static const _categorias = CategoriaRepository();
  static const _metas = MetaRepository();
  static const _recorrencias = RecorrenciaRepository();

  /// Monta tudo que o painel exibe de uma vez.
  Future<DashboardData> carregar({
    required int usuarioId,
    DateTime? mesReferencia,
  }) async {
    final mes = mesReferencia ?? DateTime.now();
    final chaveMes = Fmt.chaveMes(mes);
    final db = await _db;

    // Totais de entrada e saida do mes.
    final totais = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN tipo = 'receita' THEN valor END), 0) AS receitas,
        COALESCE(SUM(CASE WHEN tipo = 'despesa' THEN valor END), 0) AS despesas
      FROM transacoes
      WHERE usuario_id = ? AND substr(data, 1, 7) = ?
    ''', [usuarioId, chaveMes]);

    // Ultimas 5 transacoes, de qualquer mes.
    final ultimas = await db.rawQuery('''
      SELECT t.id, t.usuario_id, t.descricao, t.valor, t.tipo,
             t.categoria_id, t.data, c.nome AS categoria
      FROM transacoes t
      LEFT JOIN categorias c ON c.id = t.categoria_id
      WHERE t.usuario_id = ?
      ORDER BY t.data DESC, t.id DESC
      LIMIT 5
    ''', [usuarioId]);

    // Despesas agrupadas por categoria, para o grafico de pizza.
    final porCategoria = await db.rawQuery('''
      SELECT COALESCE(c.nome, 'Sem categoria') AS categoria,
             SUM(t.valor) AS total
      FROM transacoes t
      LEFT JOIN categorias c ON c.id = t.categoria_id
      WHERE t.usuario_id = ? AND t.tipo = 'despesa'
        AND substr(t.data, 1, 7) = ?
      GROUP BY c.id, c.nome
      ORDER BY total DESC
      LIMIT 6
    ''', [usuarioId, chaveMes]);

    final pendentes = await _recorrencias.contarPendentes(
      usuarioId: usuarioId,
      mes: mes,
    );
    final metas = await _metas.listar(usuarioId, limite: 3);
    final alertas = await _categorias.alertasDeLimite(
      usuarioId: usuarioId,
      mes: mes,
    );

    return DashboardData(
      totalReceitas: (totais.first['receitas']! as num).toDouble(),
      totalDespesas: (totais.first['despesas']! as num).toDouble(),
      ultimasTransacoes: ultimas.map(Transacao.fromMap).toList(),
      recorrenciasPendentes: pendentes,
      metas: metas,
      alertasLimite: alertas,
      despesasPorCategoria: porCategoria
          .map((m) => TotalPorCategoria(
                categoria: m['categoria']! as String,
                total: (m['total']! as num).toDouble(),
              ))
          .toList(),
    );
  }

  /// Relatorio dos ultimos N meses (3, 6 ou 12), incluindo o mes atual.
  ///
  /// O PHP calculava o recorte com `DATE_SUB(NOW(), INTERVAL n MONTH)`;
  /// aqui a data de corte e o primeiro dia do mes de N-1 meses atras.
  Future<RelatorioData> relatorio({
    required int usuarioId,
    required int periodoMeses,
  }) async {
    final hoje = DateTime.now();
    final inicio = DateTime(hoje.year, hoje.month - (periodoMeses - 1), 1);
    final corte = Fmt.chaveData(inicio);
    final db = await _db;

    // Evolucao mes a mes de entradas e saidas.
    final evolucao = await db.rawQuery('''
      SELECT substr(data, 1, 7) AS mes,
             SUM(CASE WHEN tipo = 'receita' THEN valor ELSE 0 END) AS receitas,
             SUM(CASE WHEN tipo = 'despesa' THEN valor ELSE 0 END) AS despesas
      FROM transacoes
      WHERE usuario_id = ? AND data >= ?
      GROUP BY substr(data, 1, 7)
      ORDER BY mes ASC
    ''', [usuarioId, corte]);

    // Categorias que mais consumiram no periodo.
    final top = await db.rawQuery('''
      SELECT COALESCE(c.nome, 'Sem categoria') AS categoria,
             SUM(t.valor) AS total
      FROM transacoes t
      LEFT JOIN categorias c ON c.id = t.categoria_id
      WHERE t.usuario_id = ? AND t.tipo = 'despesa' AND t.data >= ?
      GROUP BY c.id, c.nome
      ORDER BY total DESC
      LIMIT 6
    ''', [usuarioId, corte]);

    final totais = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN tipo = 'receita' THEN valor END), 0) AS receitas,
        COALESCE(SUM(CASE WHEN tipo = 'despesa' THEN valor END), 0) AS despesas
      FROM transacoes
      WHERE usuario_id = ? AND data >= ?
    ''', [usuarioId, corte]);

    final serie = evolucao
        .map((m) => ResumoMensal(
              mes: m['mes']! as String,
              receitas: (m['receitas']! as num).toDouble(),
              despesas: (m['despesas']! as num).toDouble(),
            ))
        .toList();

    return RelatorioData(
      // Preenche os meses sem movimento com zero, para o grafico de
      // linhas nao "pular" periodos vazios.
      evolucao: _completarMeses(serie, inicio, periodoMeses),
      topCategorias: top
          .map((m) => TotalPorCategoria(
                categoria: m['categoria']! as String,
                total: (m['total']! as num).toDouble(),
              ))
          .toList(),
      totalReceitas: (totais.first['receitas']! as num).toDouble(),
      totalDespesas: (totais.first['despesas']! as num).toDouble(),
    );
  }

  List<ResumoMensal> _completarMeses(
    List<ResumoMensal> encontrados,
    DateTime inicio,
    int quantidade,
  ) {
    final porChave = {for (final r in encontrados) r.mes: r};
    return List.generate(quantidade, (i) {
      final mes = DateTime(inicio.year, inicio.month + i, 1);
      final chave = Fmt.chaveMes(mes);
      return porChave[chave] ??
          ResumoMensal(mes: chave, receitas: 0, despesas: 0);
    });
  }
}
