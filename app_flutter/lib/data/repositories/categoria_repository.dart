import 'package:sqflite/sqflite.dart';

import '../../core/utils/formatters.dart';
import '../database/app_database.dart';
import '../models/models.dart';
import 'regra_negocio.dart';

/// CRUD de categorias -- equivale a pasta `categorias/` da versao web.
///
/// Como no projeto original, as categorias sao compartilhadas (a tabela
/// nao tem `usuario_id`), mas o calculo de uso contra o limite e sempre
/// feito em cima das transacoes do operador logado.
class CategoriaRepository {
  const CategoriaRepository();

  Future<Database> get _db => AppDatabase.instance.db;

  Future<List<Categoria>> listar({TipoMovimento? tipo}) async {
    final db = await _db;
    final linhas = await db.query(
      'categorias',
      where: tipo == null ? null : 'tipo = ?',
      whereArgs: tipo == null ? null : [tipo.valor],
      orderBy: 'tipo, nome',
    );
    return linhas.map(Categoria.fromMap).toList();
  }

  Future<Categoria?> buscar(int id) async {
    final db = await _db;
    final linhas = await db
        .query('categorias', where: 'id = ?', whereArgs: [id], limit: 1);
    return linhas.isEmpty ? null : Categoria.fromMap(linhas.first);
  }

  /// Listagem com o gasto do mes de cada categoria, como o
  /// `categorias/index.php` faz para mostrar "uso vs limite".
  Future<List<UsoCategoria>> listarComUso({
    required int usuarioId,
    required DateTime mes,
  }) async {
    final db = await _db;
    final linhas = await db.rawQuery('''
      SELECT c.id, c.nome, c.tipo, c.limite_mensal,
             COALESCE(SUM(t.valor), 0) AS gasto,
             COUNT(t.id)               AS qtd
      FROM categorias c
      LEFT JOIN transacoes t
             ON t.categoria_id = c.id
            AND t.usuario_id = ?
            AND substr(t.data, 1, 7) = ?
      GROUP BY c.id, c.nome, c.tipo, c.limite_mensal
      ORDER BY c.tipo, c.nome
    ''', [usuarioId, Fmt.chaveMes(mes)]);

    return linhas
        .map((m) => UsoCategoria(
              categoria: Categoria.fromMap(m),
              gasto: (m['gasto']! as num).toDouble(),
              transacoes: (m['qtd']! as num).toInt(),
            ))
        .toList();
  }

  /// Categorias de despesa que chegaram a 80% ou mais do limite no mes.
  /// Mesma consulta do bloco de alertas do `dashboard.php`.
  Future<List<UsoCategoria>> alertasDeLimite({
    required int usuarioId,
    required DateTime mes,
  }) async {
    final db = await _db;
    final linhas = await db.rawQuery('''
      SELECT c.id, c.nome, c.tipo, c.limite_mensal,
             COALESCE(SUM(t.valor), 0) AS gasto,
             COUNT(t.id)               AS qtd
      FROM categorias c
      LEFT JOIN transacoes t
             ON t.categoria_id = c.id
            AND t.usuario_id = ?
            AND t.tipo = 'despesa'
            AND substr(t.data, 1, 7) = ?
      WHERE c.tipo = 'despesa' AND c.limite_mensal IS NOT NULL
      GROUP BY c.id, c.nome, c.tipo, c.limite_mensal
      HAVING COALESCE(SUM(t.valor), 0) >= c.limite_mensal * 0.8
      ORDER BY COALESCE(SUM(t.valor), 0) / c.limite_mensal DESC
    ''', [usuarioId, Fmt.chaveMes(mes)]);

    return linhas
        .map((m) => UsoCategoria(
              categoria: Categoria.fromMap(m),
              gasto: (m['gasto']! as num).toDouble(),
              transacoes: (m['qtd']! as num).toInt(),
            ))
        .toList();
  }

  /// Cria a categoria. Regras do `categorias/create.php`:
  /// nome com 2+ caracteres e sem duplicata de nome+tipo.
  Future<int> criar({
    required String nome,
    required TipoMovimento tipo,
    double? limiteMensal,
  }) async {
    final nomeLimpo = nome.trim();

    final v = Validador()
      ..checar(nomeLimpo.length < 2, 'O nome deve ter pelo menos 2 caracteres.')
      ..checar(limiteMensal != null && limiteMensal <= 0,
          'O limite mensal deve ser maior que zero.');
    v.lancarSeInvalido();

    final db = await _db;
    await _garantirNomeLivre(db, nomeLimpo, tipo);

    return db.insert('categorias', {
      'nome': nomeLimpo,
      'tipo': tipo.valor,
      // Limite so se aplica a despesas, igual a versao web.
      'limite_mensal': tipo.isReceita ? null : limiteMensal,
    });
  }

  Future<void> atualizar({
    required int id,
    required String nome,
    required TipoMovimento tipo,
    double? limiteMensal,
  }) async {
    final nomeLimpo = nome.trim();

    final v = Validador()
      ..checar(nomeLimpo.length < 2, 'O nome deve ter pelo menos 2 caracteres.')
      ..checar(limiteMensal != null && limiteMensal <= 0,
          'O limite mensal deve ser maior que zero.');
    v.lancarSeInvalido();

    final db = await _db;
    await _garantirNomeLivre(db, nomeLimpo, tipo, ignorarId: id);

    await db.update(
      'categorias',
      {
        'nome': nomeLimpo,
        'tipo': tipo.valor,
        'limite_mensal': tipo.isReceita ? null : limiteMensal,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Exclui a categoria, mas bloqueia se houver transacao vinculada --
  /// a mesma protecao do `categorias/delete.php`.
  Future<void> excluir(int id) async {
    final db = await _db;

    final emUso = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM transacoes WHERE categoria_id = ?',
      [id],
    );
    if ((emUso.first['total']! as num).toInt() > 0) {
      throw RegraNegocioException.unica(
        'Esta categoria esta vinculada a transacoes e nao pode ser excluida.',
      );
    }

    final emRecorrencia = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM recorrencias WHERE categoria_id = ?',
      [id],
    );
    if ((emRecorrencia.first['total']! as num).toInt() > 0) {
      throw RegraNegocioException.unica(
        'Esta categoria esta vinculada a recorrencias e nao pode ser excluida.',
      );
    }

    await db.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _garantirNomeLivre(
    Database db,
    String nome,
    TipoMovimento tipo, {
    int? ignorarId,
  }) async {
    final linhas = await db.query(
      'categorias',
      columns: ['id'],
      where: 'nome = ? AND tipo = ?${ignorarId == null ? '' : ' AND id != ?'}',
      whereArgs: [nome, tipo.valor, ?ignorarId],
      limit: 1,
    );
    if (linhas.isNotEmpty) {
      throw RegraNegocioException.unica(
        'Ja existe uma categoria com este nome e tipo.',
      );
    }
  }
}
