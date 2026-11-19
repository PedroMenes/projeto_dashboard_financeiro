import 'package:sqflite/sqflite.dart';

import '../../core/utils/formatters.dart';
import '../database/app_database.dart';
import '../models/models.dart';
import 'regra_negocio.dart';

/// CRUD de metas financeiras + depositos.
/// Equivale a pasta `metas/` da versao web.
class MetaRepository {
  const MetaRepository();

  Future<Database> get _db => AppDatabase.instance.db;

  Future<List<Meta>> listar(int usuarioId, {int? limite}) async {
    final db = await _db;
    final linhas = await db.query(
      'metas',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'created_at DESC, id DESC',
      limit: limite,
    );
    return linhas.map(Meta.fromMap).toList();
  }

  Future<Meta?> buscar({required int id, required int usuarioId}) async {
    final db = await _db;
    final linhas = await db.query(
      'metas',
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [id, usuarioId],
      limit: 1,
    );
    return linhas.isEmpty ? null : Meta.fromMap(linhas.first);
  }

  /// Validacoes do `metas/create.php`.
  void _validar({
    required String nome,
    required double? valorAlvo,
    required double? valorAtual,
  }) {
    final v = Validador()
      ..checar(nome.trim().length < 2, 'O nome deve ter pelo menos 2 caracteres.')
      ..checar(valorAlvo == null || valorAlvo <= 0,
          'Informe um valor alvo valido maior que zero.')
      ..checar((valorAtual ?? 0) < 0, 'O valor atual nao pode ser negativo.');

    if (valorAlvo != null && valorAtual != null && valorAtual > valorAlvo) {
      v.add('O valor atual nao pode ser maior que o valor alvo.');
    }
    v.lancarSeInvalido();
  }

  Future<int> criar({
    required int usuarioId,
    required String nome,
    required double? valorAlvo,
    double? valorAtual,
    String? descricao,
    DateTime? prazo,
  }) async {
    _validar(nome: nome, valorAlvo: valorAlvo, valorAtual: valorAtual);

    final db = await _db;
    return db.insert('metas', {
      'usuario_id': usuarioId,
      'nome': nome.trim(),
      'descricao': (descricao ?? '').trim().isEmpty ? null : descricao!.trim(),
      'valor_alvo': valorAlvo,
      'valor_atual': valorAtual ?? 0,
      'prazo': prazo == null ? null : Fmt.chaveData(prazo),
    });
  }

  Future<void> atualizar({
    required int id,
    required int usuarioId,
    required String nome,
    required double? valorAlvo,
    required double? valorAtual,
    String? descricao,
    DateTime? prazo,
  }) async {
    _validar(nome: nome, valorAlvo: valorAlvo, valorAtual: valorAtual);

    final db = await _db;
    final linhas = await db.update(
      'metas',
      {
        'nome': nome.trim(),
        'descricao':
            (descricao ?? '').trim().isEmpty ? null : descricao!.trim(),
        'valor_alvo': valorAlvo,
        'valor_atual': valorAtual ?? 0,
        'prazo': prazo == null ? null : Fmt.chaveData(prazo),
      },
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [id, usuarioId],
    );
    if (linhas == 0) throw RegraNegocioException.unica('Meta nao encontrada.');
  }

  /// Registra um deposito na meta. Mesma regra do `metas/depositar.php`:
  /// o valor deve ser positivo e nao pode ultrapassar o valor alvo.
  Future<void> depositar({
    required int id,
    required int usuarioId,
    required double? valor,
  }) async {
    final meta = await buscar(id: id, usuarioId: usuarioId);
    if (meta == null) {
      throw RegraNegocioException.unica('Meta nao encontrada.');
    }

    if (valor == null || valor <= 0) {
      throw RegraNegocioException.unica(
        'Informe um valor valido maior que zero.',
      );
    }
    if (meta.valorAtual + valor > meta.valorAlvo) {
      throw RegraNegocioException.unica(
        'O deposito ultrapassa o valor alvo. '
        'Maximo permitido: ${Fmt.moeda(meta.falta)}',
      );
    }

    final db = await _db;
    await db.update(
      'metas',
      {'valor_atual': meta.valorAtual + valor},
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [id, usuarioId],
    );
  }

  /// Retira um valor ja depositado, caso o usuario tenha errado o lancamento.
  Future<void> retirar({
    required int id,
    required int usuarioId,
    required double? valor,
  }) async {
    final meta = await buscar(id: id, usuarioId: usuarioId);
    if (meta == null) {
      throw RegraNegocioException.unica('Meta nao encontrada.');
    }

    if (valor == null || valor <= 0) {
      throw RegraNegocioException.unica(
        'Informe um valor valido maior que zero.',
      );
    }
    if (valor > meta.valorAtual) {
      throw RegraNegocioException.unica(
        'A retirada e maior que o valor acumulado '
        '(${Fmt.moeda(meta.valorAtual)}).',
      );
    }

    final db = await _db;
    await db.update(
      'metas',
      {'valor_atual': meta.valorAtual - valor},
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [id, usuarioId],
    );
  }

  Future<void> excluir({required int id, required int usuarioId}) async {
    final db = await _db;
    await db.delete(
      'metas',
      where: 'id = ? AND usuario_id = ?',
      whereArgs: [id, usuarioId],
    );
  }
}
