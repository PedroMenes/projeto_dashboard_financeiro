import 'package:sqflite/sqflite.dart';

import '../../core/utils/formatters.dart';
import '../database/app_database.dart';
import '../models/models.dart';
import 'regra_negocio.dart';

/// CRUD de transacoes -- equivale a pasta `transacoes/` da versao web.
class TransacaoRepository {
  const TransacaoRepository();

  Future<Database> get _db => AppDatabase.instance.db;

  /// Listagem com os mesmos filtros do `transacoes/index.php`:
  /// tipo (opcional) e mes de referencia.
  Future<List<Transacao>> listar({
    required int usuarioId,
    TipoMovimento? tipo,
    DateTime? mes,
    String? busca,
  }) async {
    final condicoes = <String>['t.usuario_id = ?'];
    final params = <Object?>[usuarioId];

    if (tipo != null) {
      condicoes.add('t.tipo = ?');
      params.add(tipo.valor);
    }
    if (mes != null) {
      condicoes.add('substr(t.data, 1, 7) = ?');
      params.add(Fmt.chaveMes(mes));
    }
    if (busca != null && busca.trim().isNotEmpty) {
      condicoes.add('LOWER(t.descricao) LIKE ?');
      params.add('%${busca.trim().toLowerCase()}%');
    }

    final db = await _db;
    final linhas = await db.rawQuery('''
      SELECT t.id, t.usuario_id, t.descricao, t.valor, t.tipo,
             t.categoria_id, t.data, c.nome AS categoria
      FROM transacoes t
      LEFT JOIN categorias c ON c.id = t.categoria_id
      WHERE ${condicoes.join(' AND ')}
      ORDER BY t.data DESC, t.id DESC
    ''', params);

    return linhas.map(Transacao.fromMap).toList();
  }

  /// Totais de entrada e saida respeitando os mesmos filtros da listagem.
  Future<({double receitas, double despesas})> totais({
    required int usuarioId,
    TipoMovimento? tipo,
    DateTime? mes,
    String? busca,
  }) async {
    final condicoes = <String>['usuario_id = ?'];
    final params = <Object?>[usuarioId];

    if (tipo != null) {
      condicoes.add('tipo = ?');
      params.add(tipo.valor);
    }
    if (mes != null) {
      condicoes.add('substr(data, 1, 7) = ?');
      params.add(Fmt.chaveMes(mes));
    }
    if (busca != null && busca.trim().isNotEmpty) {
      condicoes.add('LOWER(descricao) LIKE ?');
      params.add('%${busca.trim().toLowerCase()}%');
    }

    final db = await _db;
    final r = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN tipo = 'receita' THEN valor END), 0) AS receitas,
        COALESCE(SUM(CASE WHEN tipo = 'despesa' THEN valor END), 0) AS despesas
      FROM transacoes
      WHERE ${condicoes.join(' AND ')}
    ''', params);

    return (
      receitas: (r.first['receitas']! as num).toDouble(),
      despesas: (r.first['despesas']! as num).toDouble(),
    );
  }

  Future<Transacao?> buscar({required int id, required int usuarioId}) async {
    final db = await _db;
    final linhas = await db.rawQuery('''
      SELECT t.id, t.usuario_id, t.descricao, t.valor, t.tipo,
             t.categoria_id, t.data, c.nome AS categoria
      FROM transacoes t
      LEFT JOIN categorias c ON c.id = t.categoria_id
      WHERE t.id = ? AND t.usuario_id = ?
      LIMIT 1
    ''', [id, usuarioId]);
    return linhas.isEmpty ? null : Transacao.fromMap(linhas.first);
  }

  /// Meses que possuem transacoes, do mais recente ao mais antigo.
  /// Alimenta o seletor de mes da listagem.
  Future<List<String>> mesesDisponiveis(int usuarioId) async {
    final db = await _db;
    final linhas = await db.rawQuery('''
      SELECT DISTINCT substr(data, 1, 7) AS mes
      FROM transacoes
      WHERE usuario_id = ?
      ORDER BY mes DESC
    ''', [usuarioId]);
    return linhas.map((m) => m['mes']! as String).toList();
  }

  /// Validacoes do `transacoes/create.php`.
  void _validar({
    required String descricao,
    required double? valor,
  }) {
    final v = Validador()
      ..checar(descricao.trim().isEmpty, 'A descricao e obrigatoria.')
      ..checar(valor == null || valor <= 0,
          'Informe um valor valido maior que zero.');
    v.lancarSeInvalido();
  }

  Future<int> criar({
    required int usuarioId,
    required String descricao,
    required double? valor,
    required TipoMovimento tipo,
    required DateTime data,
    int? categoriaId,
  }) async {
    _validar(descricao: descricao, valor: valor);

    final db = await _db;
    return db.insert('transacoes', {
      'usuario_id': usuarioId,
      'descricao': descricao.trim(),
      'valor': valor,
      'tipo': tipo.valor,
      'categoria_id': categoriaId,
      'data': Fmt.chaveData(data),
    });
  }

  Future<void> atualizar({
    required int id,
    required int usuarioId,
    required String descricao,
    required double? valor,
    required TipoMovimento tipo,
    required DateTime data,
    int? categoriaId,
  }) async {
    _validar(descricao: descricao, valor: valor);

    final db = await _db;
    final linhas = await db.update(
      'transacoes',
      {
        'descricao': descricao.trim(),
        'valor': valor,
        'tipo': tipo.valor,
        'categoria_id': categoriaId,
        'data': Fmt.chaveData(data),
      },
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [id, usuarioId],
    );
    if (linhas == 0) {
      throw RegraNegocioException.unica('Transacao nao encontrada.');
    }
  }

  Future<void> excluir({required int id, required int usuarioId}) async {
    final db = await _db;
    await db.delete(
      'transacoes',
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [id, usuarioId],
    );
  }
}
