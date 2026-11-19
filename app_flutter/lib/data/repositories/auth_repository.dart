import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/password_hasher.dart';
import '../models/models.dart';
import 'regra_negocio.dart';

/// Cadastro, login e manutencao da conta.
/// Equivale a `register.php`, `login.php` e `perfil.php`.
class AuthRepository {
  const AuthRepository();

  Future<Database> get _db => AppDatabase.instance.db;

  static final _regexEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  /// Cria um novo operador. Mesmas regras do `register.php`:
  /// nome com 2+ caracteres, e-mail valido e unico, senha com 6+ caracteres.
  Future<Usuario> registrar({
    required String nome,
    required String email,
    required String senha,
    required String senhaConfirmacao,
  }) async {
    final nomeLimpo = nome.trim();
    final emailLimpo = email.trim().toLowerCase();

    final v = Validador()
      ..checar(nomeLimpo.length < 2, 'O nome deve ter pelo menos 2 caracteres.')
      ..checar(!_regexEmail.hasMatch(emailLimpo), 'Informe um e-mail valido.')
      ..checar(senha.length < 6, 'A senha deve ter pelo menos 6 caracteres.')
      ..checar(senha != senhaConfirmacao, 'As senhas nao coincidem.');
    v.lancarSeInvalido();

    final db = await _db;
    final jaExiste = await db.query(
      'usuarios',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [emailLimpo],
      limit: 1,
    );
    if (jaExiste.isNotEmpty) {
      throw RegraNegocioException.unica('Este e-mail ja esta cadastrado.');
    }

    final id = await db.insert('usuarios', {
      'nome': nomeLimpo,
      'email': emailLimpo,
      'senha': PasswordHasher.hash(senha),
    });

    return buscarPorId(id);
  }

  /// Autentica o operador. Retorna null quando e-mail ou senha nao batem --
  /// a mensagem na tela e generica de proposito, para nao revelar
  /// se o e-mail existe no sistema.
  Future<Usuario?> autenticar({
    required String email,
    required String senha,
  }) async {
    final db = await _db;
    final linhas = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (linhas.isEmpty) return null;

    final linha = linhas.first;
    if (!PasswordHasher.verify(senha, linha['senha']! as String)) return null;

    return Usuario.fromMap(linha);
  }

  Future<Usuario> buscarPorId(int id) async {
    final db = await _db;
    final linhas =
        await db.query('usuarios', where: 'id = ?', whereArgs: [id], limit: 1);
    if (linhas.isEmpty) {
      throw RegraNegocioException.unica('Operador nao encontrado.');
    }
    return Usuario.fromMap(linhas.first);
  }

  /// Atualiza nome, e-mail e, opcionalmente, a senha.
  /// Para trocar a senha e obrigatorio informar a senha atual.
  Future<Usuario> atualizarPerfil({
    required int id,
    required String nome,
    required String email,
    String? senhaAtual,
    String? novaSenha,
    String? novaSenhaConfirmacao,
  }) async {
    final nomeLimpo = nome.trim();
    final emailLimpo = email.trim().toLowerCase();
    final querTrocarSenha = (novaSenha ?? '').isNotEmpty;

    final v = Validador()
      ..checar(nomeLimpo.length < 2, 'O nome deve ter pelo menos 2 caracteres.')
      ..checar(!_regexEmail.hasMatch(emailLimpo), 'Informe um e-mail valido.');

    if (querTrocarSenha) {
      v
        ..checar((senhaAtual ?? '').isEmpty,
            'Informe a senha atual para poder troca-la.')
        ..checar(novaSenha!.length < 6,
            'A nova senha deve ter pelo menos 6 caracteres.')
        ..checar(novaSenha != novaSenhaConfirmacao,
            'A confirmacao da nova senha nao coincide.');
    }
    v.lancarSeInvalido();

    final db = await _db;
    final atual = await db
        .query('usuarios', where: 'id = ?', whereArgs: [id], limit: 1);
    if (atual.isEmpty) {
      throw RegraNegocioException.unica('Operador nao encontrado.');
    }

    if (querTrocarSenha &&
        !PasswordHasher.verify(senhaAtual!, atual.first['senha']! as String)) {
      throw RegraNegocioException.unica('A senha atual esta incorreta.');
    }

    final emailEmUso = await db.query(
      'usuarios',
      columns: ['id'],
      where: 'email = ? AND id != ?',
      whereArgs: [emailLimpo, id],
      limit: 1,
    );
    if (emailEmUso.isNotEmpty) {
      throw RegraNegocioException.unica(
        'Este e-mail ja esta em uso por outro operador.',
      );
    }

    await db.update(
      'usuarios',
      {
        'nome': nomeLimpo,
        'email': emailLimpo,
        if (querTrocarSenha) 'senha': PasswordHasher.hash(novaSenha!),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    return buscarPorId(id);
  }

  /// Exclui a conta. As transacoes, metas e recorrencias vao embora
  /// junto por causa do ON DELETE CASCADE do schema.
  Future<void> excluirConta(int id) async {
    final db = await _db;
    await db.delete('usuarios', where: 'id = ?', whereArgs: [id]);
  }

  /// Quantos operadores existem -- a tela de login usa isso para
  /// avisar quando o banco acabou de ser redefinido.
  Future<int> contarUsuarios() async {
    final db = await _db;
    final r = await db.rawQuery('SELECT COUNT(*) AS total FROM usuarios');
    return (r.first['total']! as num).toInt();
  }
}
