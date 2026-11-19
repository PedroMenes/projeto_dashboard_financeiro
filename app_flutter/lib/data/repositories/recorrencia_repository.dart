import 'package:sqflite/sqflite.dart';

import '../../core/utils/formatters.dart';
import '../database/app_database.dart';
import '../models/models.dart';
import 'regra_negocio.dart';

/// CRUD de transacoes recorrentes + lancamento mensal.
/// Equivale a pasta `recorrencias/` da versao web.
class RecorrenciaRepository {
  const RecorrenciaRepository();

  Future<Database> get _db => AppDatabase.instance.db;

  Future<List<Recorrencia>> listar(int usuarioId) async {
    final db = await _db;
    final linhas = await db.rawQuery('''
      SELECT r.id, r.usuario_id, r.descricao, r.valor, r.tipo,
             r.categoria_id, r.dia_vencimento, r.ativa, r.ultimo_lancamento,
             c.nome AS categoria
      FROM recorrencias r
      LEFT JOIN categorias c ON c.id = r.categoria_id
      WHERE r.usuario_id = ?
      ORDER BY r.ativa DESC, r.dia_vencimento ASC, r.id DESC
    ''', [usuarioId]);
    return linhas.map(Recorrencia.fromMap).toList();
  }

  Future<Recorrencia?> buscar({
    required int id,
    required int usuarioId,
  }) async {
    final db = await _db;
    final linhas = await db.rawQuery('''
      SELECT r.id, r.usuario_id, r.descricao, r.valor, r.tipo,
             r.categoria_id, r.dia_vencimento, r.ativa, r.ultimo_lancamento,
             c.nome AS categoria
      FROM recorrencias r
      LEFT JOIN categorias c ON c.id = r.categoria_id
      WHERE r.id = ? AND r.usuario_id = ?
      LIMIT 1
    ''', [id, usuarioId]);
    return linhas.isEmpty ? null : Recorrencia.fromMap(linhas.first);
  }

  /// Quantas recorrencias ativas ainda nao foram lancadas no mes informado.
  /// Mesma contagem que aparece no alerta do dashboard.
  Future<int> contarPendentes({
    required int usuarioId,
    required DateTime mes,
  }) async {
    final db = await _db;
    final r = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM recorrencias
      WHERE usuario_id = ? AND ativa = 1
        AND (ultimo_lancamento IS NULL
             OR substr(ultimo_lancamento, 1, 7) != ?)
    ''', [usuarioId, Fmt.chaveMes(mes)]);
    return (r.first['total']! as num).toInt();
  }

  /// Validacoes do `recorrencias/create.php`.
  void _validar({
    required String descricao,
    required double? valor,
    required int diaVencimento,
  }) {
    final v = Validador()
      ..checar(descricao.trim().isEmpty, 'A descricao e obrigatoria.')
      ..checar(valor == null || valor <= 0,
          'Informe um valor valido maior que zero.')
      ..checar(diaVencimento < 1 || diaVencimento > 31,
          'O dia de vencimento deve ser entre 1 e 31.');
    v.lancarSeInvalido();
  }

  Future<int> criar({
    required int usuarioId,
    required String descricao,
    required double? valor,
    required TipoMovimento tipo,
    required int diaVencimento,
    int? categoriaId,
    bool ativa = true,
  }) async {
    _validar(
      descricao: descricao,
      valor: valor,
      diaVencimento: diaVencimento,
    );

    final db = await _db;
    return db.insert('recorrencias', {
      'usuario_id': usuarioId,
      'descricao': descricao.trim(),
      'valor': valor,
      'tipo': tipo.valor,
      'categoria_id': categoriaId,
      'dia_vencimento': diaVencimento,
      'ativa': ativa ? 1 : 0,
    });
  }

  Future<void> atualizar({
    required int id,
    required int usuarioId,
    required String descricao,
    required double? valor,
    required TipoMovimento tipo,
    required int diaVencimento,
    int? categoriaId,
    required bool ativa,
  }) async {
    _validar(
      descricao: descricao,
      valor: valor,
      diaVencimento: diaVencimento,
    );

    final db = await _db;
    final linhas = await db.update(
      'recorrencias',
      {
        'descricao': descricao.trim(),
        'valor': valor,
        'tipo': tipo.valor,
        'categoria_id': categoriaId,
        'dia_vencimento': diaVencimento,
        'ativa': ativa ? 1 : 0,
      },
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [id, usuarioId],
    );
    if (linhas == 0) {
      throw RegraNegocioException.unica('Recorrencia nao encontrada.');
    }
  }

  /// Liga ou desliga a recorrencia sem apagar o cadastro.
  Future<void> alternarAtiva({
    required int id,
    required int usuarioId,
    required bool ativa,
  }) async {
    final db = await _db;
    await db.update(
      'recorrencias',
      {'ativa': ativa ? 1 : 0},
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [id, usuarioId],
    );
  }

  /// Gera a transacao do mes a partir da recorrencia.
  ///
  /// Porta do `recorrencias/lancar.php`: a data usa o dia de vencimento,
  /// mas limitado ao ultimo dia do mes (um vencimento dia 31 cai em 28 ou
  /// 29 em fevereiro). As duas gravacoes ficam na mesma transacao do
  /// banco, para nao existir lancamento sem baixa.
  Future<void> lancarNoMes({
    required int id,
    required int usuarioId,
    DateTime? mesReferencia,
  }) async {
    final rec = await buscar(id: id, usuarioId: usuarioId);
    if (rec == null) {
      throw RegraNegocioException.unica('Recorrencia nao encontrada.');
    }
    if (!rec.ativa) {
      throw RegraNegocioException.unica(
        'Esta recorrencia esta inativa. Reative-a antes de lancar.',
      );
    }

    final mes = mesReferencia ?? DateTime.now();
    if (!rec.pendenteEm(mes)) {
      throw RegraNegocioException.unica(
        'Esta recorrencia ja foi lancada em ${Fmt.mesAno(mes)}.',
      );
    }

    final dia = rec.diaVencimento.clamp(1, Fmt.ultimoDiaDoMes(mes));
    final dataLancamento = DateTime(mes.year, mes.month, dia);

    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert('transacoes', {
        'usuario_id': usuarioId,
        'descricao': rec.descricao,
        'valor': rec.valor,
        'tipo': rec.tipo.valor,
        'categoria_id': rec.categoriaId,
        'data': Fmt.chaveData(dataLancamento),
      });
      await txn.update(
        'recorrencias',
        {'ultimo_lancamento': Fmt.chaveData(dataLancamento)},
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [id, usuarioId],
      );
    });
  }

  /// Lanca de uma vez todas as recorrencias pendentes do mes.
  /// Retorna quantas foram lancadas.
  Future<int> lancarTodasPendentes({
    required int usuarioId,
    DateTime? mesReferencia,
  }) async {
    final mes = mesReferencia ?? DateTime.now();
    final todas = await listar(usuarioId);
    final pendentes = todas.where((r) => r.pendenteEm(mes)).toList();

    for (final rec in pendentes) {
      await lancarNoMes(
        id: rec.id,
        usuarioId: usuarioId,
        mesReferencia: mes,
      );
    }
    return pendentes.length;
  }

  Future<void> excluir({required int id, required int usuarioId}) async {
    final db = await _db;
    await db.delete(
      'recorrencias',
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [id, usuarioId],
    );
  }
}
