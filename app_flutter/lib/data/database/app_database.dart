import 'package:sqflite/sqflite.dart';

import 'db_factory.dart';
import 'password_hasher.dart';

/// Ponto unico de acesso ao banco SQLite local.
///
/// E a traducao do `database.sql` e do `config/database.php` da versao web.
/// A diferenca e que aqui nao existe servidor: o banco e um arquivo dentro
/// do proprio aparelho (ou o IndexedDB, quando roda no navegador).
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _versao = 1;

  Database? _db;

  /// Caminho alternativo do banco. Os testes apontam para a memoria
  /// (`inMemoryDatabasePath`) para nao tocar em arquivo nenhum.
  static String? _caminhoOverride;

  /// Quando os testes ja configuraram o motor do SQLite por conta propria,
  /// nao faz sentido chamar [configurarMotorBanco] de novo.
  static bool _motorJaConfigurado = false;

  /// Prepara o banco para rodar em testes, sem tocar no disco.
  static void configurarParaTestes(String caminho) {
    _caminhoOverride = caminho;
    _motorJaConfigurado = true;
  }

  /// Abre o banco na primeira chamada e reaproveita a conexao depois.
  Future<Database> get db async => _db ??= await _abrir();

  Future<Database> _abrir() async {
    if (!_motorJaConfigurado) await configurarMotorBanco();
    final caminho = _caminhoOverride ?? await caminhoBanco();

    return openDatabase(
      caminho,
      version: _versao,
      onConfigure: (db) async {
        // O SQLite ignora chaves estrangeiras por padrao; aqui ligamos
        // para que o ON DELETE CASCADE do schema realmente funcione.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _criarTabelas(db);
        await _popularDadosIniciais(db);
      },
    );
  }

  /// Estrutura das tabelas -- mesma do MySQL, adaptada ao dialeto do SQLite:
  /// `AUTO_INCREMENT` vira `AUTOINCREMENT`, `ENUM` vira `TEXT` com `CHECK`
  /// e `DECIMAL(10,2)` vira `REAL`.
  Future<void> _criarTabelas(Database db) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        nome       TEXT NOT NULL,
        email      TEXT NOT NULL UNIQUE,
        senha      TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
      )
    ''');

    await db.execute('''
      CREATE TABLE categorias (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        nome          TEXT NOT NULL,
        tipo          TEXT NOT NULL CHECK (tipo IN ('receita', 'despesa')),
        limite_mensal REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE transacoes (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id   INTEGER NOT NULL,
        descricao    TEXT NOT NULL,
        valor        REAL NOT NULL,
        tipo         TEXT NOT NULL CHECK (tipo IN ('receita', 'despesa')),
        categoria_id INTEGER,
        data         TEXT NOT NULL,
        created_at   TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        FOREIGN KEY (usuario_id)   REFERENCES usuarios(id)   ON DELETE CASCADE,
        FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE metas (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id  INTEGER NOT NULL,
        nome        TEXT NOT NULL,
        descricao   TEXT,
        valor_alvo  REAL NOT NULL,
        valor_atual REAL NOT NULL DEFAULT 0,
        prazo       TEXT,
        created_at  TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recorrencias (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id        INTEGER NOT NULL,
        descricao         TEXT NOT NULL,
        valor             REAL NOT NULL,
        tipo              TEXT NOT NULL CHECK (tipo IN ('receita', 'despesa')),
        categoria_id      INTEGER,
        dia_vencimento    INTEGER NOT NULL,
        ativa             INTEGER NOT NULL DEFAULT 1,
        ultimo_lancamento TEXT,
        created_at        TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        FOREIGN KEY (usuario_id)   REFERENCES usuarios(id)   ON DELETE CASCADE,
        FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE SET NULL
      )
    ''');

    // Indices nas colunas mais filtradas pelas telas de listagem.
    await db.execute(
      'CREATE INDEX idx_transacoes_usuario_data ON transacoes(usuario_id, data)',
    );
    await db.execute(
      'CREATE INDEX idx_transacoes_categoria ON transacoes(categoria_id)',
    );
    await db.execute(
      'CREATE INDEX idx_recorrencias_usuario ON recorrencias(usuario_id, ativa)',
    );
    await db.execute('CREATE INDEX idx_metas_usuario ON metas(usuario_id)');
  }

  /// Mesmas categorias padrao e mesmo usuario de demonstracao
  /// do final do `database.sql`.
  Future<void> _popularDadosIniciais(Database db) async {
    final lote = db.batch();

    const categorias = <(String, String, double?)>[
      ('Salario', 'receita', null),
      ('Freelance', 'receita', null),
      ('Investimentos', 'receita', null),
      ('Outros (entrada)', 'receita', null),
      ('Alimentacao', 'despesa', 800.00),
      ('Moradia', 'despesa', 1500.00),
      ('Transporte', 'despesa', 400.00),
      ('Saude', 'despesa', 300.00),
      ('Educacao', 'despesa', 500.00),
      ('Lazer', 'despesa', 300.00),
      ('Outros (saida)', 'despesa', null),
    ];

    for (final (nome, tipo, limite) in categorias) {
      lote.insert('categorias', {
        'nome': nome,
        'tipo': tipo,
        'limite_mensal': limite,
      });
    }

    // Operador de demonstracao -- as mesmas credenciais da versao web.
    lote.insert('usuarios', {
      'nome': 'Administrador',
      'email': 'admin@financeiro.com',
      'senha': PasswordHasher.hash('123456'),
    });

    await lote.commit(noResult: true);
  }

  /// Fecha a conexao e apaga o banco, voltando ao estado de primeira
  /// instalacao. Usado pelo botao "redefinir dados" do perfil.
  Future<void> redefinir() async {
    await _db?.close();
    _db = null;
    if (_caminhoOverride != null) return;
    await apagarArquivoBanco();
  }

  /// Fecha a conexao sem apagar nada -- usado entre casos de teste.
  Future<void> fechar() async {
    await _db?.close();
    _db = null;
  }
}
