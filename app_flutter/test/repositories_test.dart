import 'package:financeiro_app/core/utils/formatters.dart';
import 'package:financeiro_app/data/database/app_database.dart';
import 'package:financeiro_app/data/models/models.dart';
import 'package:financeiro_app/data/repositories/auth_repository.dart';
import 'package:financeiro_app/data/repositories/categoria_repository.dart';
import 'package:financeiro_app/data/repositories/dashboard_repository.dart';
import 'package:financeiro_app/data/repositories/meta_repository.dart';
import 'package:financeiro_app/data/repositories/recorrencia_repository.dart';
import 'package:financeiro_app/data/repositories/regra_negocio.dart';
import 'package:financeiro_app/data/repositories/transacao_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Testes de integracao dos repositorios contra um SQLite em memoria.
///
/// Cada caso comeca com o banco recem-criado (categorias padrao e o
/// operador de demonstracao), igual a uma instalacao nova do app.
void main() {
  const auth = AuthRepository();
  const categorias = CategoriaRepository();
  const transacoes = TransacaoRepository();
  const metas = MetaRepository();
  const recorrencias = RecorrenciaRepository();
  const dashboard = DashboardRepository();

  /// Id do operador de demonstracao criado junto com o banco.
  const demoId = 1;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.configurarParaTestes(inMemoryDatabasePath);
    // Alguns formatadores de data dependem dos dados de locale,
    // carregados no app pelo main().
    initializeDateFormatting('pt_BR');
  });

  setUp(() async {
    // Garante um banco limpo: fecha o anterior para que o proximo
    // acesso abra um ':memory:' novo e rode o onCreate outra vez.
    await AppDatabase.instance.fechar();
  });

  tearDownAll(() async => AppDatabase.instance.fechar());

  group('Dados iniciais', () {
    test('cria as 11 categorias padrao', () async {
      final todas = await categorias.listar();
      expect(todas, hasLength(11));
      expect(
        todas.where((c) => c.tipo.isReceita).length,
        4,
        reason: 'Salario, Freelance, Investimentos e Outros (entrada)',
      );
    });

    test('categorias de despesa trazem os limites do database.sql', () async {
      final todas = await categorias.listar(tipo: TipoMovimento.despesa);
      final alimentacao = todas.firstWhere((c) => c.nome == 'Alimentacao');
      final moradia = todas.firstWhere((c) => c.nome == 'Moradia');
      expect(alimentacao.limiteMensal, 800.00);
      expect(moradia.limiteMensal, 1500.00);
    });

    test('cria o operador de demonstracao com a senha 123456', () async {
      expect(await auth.contarUsuarios(), 1);
      final u = await auth.autenticar(
        email: 'admin@financeiro.com',
        senha: '123456',
      );
      expect(u, isNotNull);
      expect(u!.nome, 'Administrador');
    });
  });

  group('AuthRepository', () {
    test('recusa senha errada e e-mail inexistente', () async {
      expect(
        await auth.autenticar(email: 'admin@financeiro.com', senha: 'errada'),
        isNull,
      );
      expect(
        await auth.autenticar(email: 'ninguem@nerv.jp', senha: '123456'),
        isNull,
      );
    });

    test('login ignora diferenca de maiusculas no e-mail', () async {
      final u = await auth.autenticar(
        email: 'ADMIN@Financeiro.COM',
        senha: '123456',
      );
      expect(u, isNotNull);
    });

    test('registra um novo operador e permite o login', () async {
      final novo = await auth.registrar(
        nome: 'Shinji',
        email: 'shinji@nerv.jp',
        senha: 'senha123',
        senhaConfirmacao: 'senha123',
      );
      expect(novo.nome, 'Shinji');

      final logado = await auth.autenticar(
        email: 'shinji@nerv.jp',
        senha: 'senha123',
      );
      expect(logado?.id, novo.id);
    });

    test('acumula todos os erros de validacao de uma vez', () async {
      try {
        await auth.registrar(
          nome: 'A',
          email: 'nao-e-email',
          senha: '123',
          senhaConfirmacao: '456',
        );
        fail('deveria ter lancado RegraNegocioException');
      } on RegraNegocioException catch (e) {
        expect(e.erros, hasLength(4));
      }
    });

    test('bloqueia e-mail duplicado', () async {
      expect(
        () => auth.registrar(
          nome: 'Outro Admin',
          email: 'admin@financeiro.com',
          senha: 'senha123',
          senhaConfirmacao: 'senha123',
        ),
        throwsA(isA<RegraNegocioException>()),
      );
    });

    test('exige a senha atual para trocar de senha', () async {
      expect(
        () => auth.atualizarPerfil(
          id: demoId,
          nome: 'Administrador',
          email: 'admin@financeiro.com',
          senhaAtual: 'errada',
          novaSenha: 'novaSenha1',
          novaSenhaConfirmacao: 'novaSenha1',
        ),
        throwsA(isA<RegraNegocioException>()),
      );
    });

    test('troca a senha quando a atual esta correta', () async {
      await auth.atualizarPerfil(
        id: demoId,
        nome: 'Administrador',
        email: 'admin@financeiro.com',
        senhaAtual: '123456',
        novaSenha: 'novaSenha1',
        novaSenhaConfirmacao: 'novaSenha1',
      );

      expect(
        await auth.autenticar(
          email: 'admin@financeiro.com',
          senha: 'novaSenha1',
        ),
        isNotNull,
      );
      expect(
        await auth.autenticar(email: 'admin@financeiro.com', senha: '123456'),
        isNull,
      );
    });

    test('atualiza nome e e-mail sem mexer na senha', () async {
      final atualizado = await auth.atualizarPerfil(
        id: demoId,
        nome: 'Gendo Ikari',
        email: 'gendo@nerv.jp',
      );
      expect(atualizado.nome, 'Gendo Ikari');
      expect(
        await auth.autenticar(email: 'gendo@nerv.jp', senha: '123456'),
        isNotNull,
      );
    });

    test('excluir a conta leva as transacoes junto (ON DELETE CASCADE)',
        () async {
      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Teste',
        valor: 10,
        tipo: TipoMovimento.despesa,
        data: DateTime.now(),
      );
      expect(await transacoes.listar(usuarioId: demoId), hasLength(1));

      await auth.excluirConta(demoId);
      expect(await transacoes.listar(usuarioId: demoId), isEmpty);
      expect(await auth.contarUsuarios(), 0);
    });
  });

  group('TransacaoRepository', () {
    test('recusa descricao vazia e valor zero ou negativo', () async {
      try {
        await transacoes.criar(
          usuarioId: demoId,
          descricao: '   ',
          valor: 0,
          tipo: TipoMovimento.despesa,
          data: DateTime.now(),
        );
        fail('deveria ter lancado RegraNegocioException');
      } on RegraNegocioException catch (e) {
        expect(e.erros, hasLength(2));
      }

      expect(
        () => transacoes.criar(
          usuarioId: demoId,
          descricao: 'Negativa',
          valor: -5,
          tipo: TipoMovimento.despesa,
          data: DateTime.now(),
        ),
        throwsA(isA<RegraNegocioException>()),
      );
    });

    test('grava e devolve o nome da categoria pelo JOIN', () async {
      final despesas = await categorias.listar(tipo: TipoMovimento.despesa);
      final alimentacao = despesas.firstWhere((c) => c.nome == 'Alimentacao');

      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Supermercado',
        valor: 230.50,
        tipo: TipoMovimento.despesa,
        data: DateTime.now(),
        categoriaId: alimentacao.id,
      );

      final lista = await transacoes.listar(usuarioId: demoId);
      expect(lista, hasLength(1));
      expect(lista.first.categoriaNome, 'Alimentacao');
      expect(lista.first.valor, 230.50);
    });

    test('totais separam receitas de despesas', () async {
      final hoje = DateTime.now();
      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Salario',
        valor: 5000,
        tipo: TipoMovimento.receita,
        data: hoje,
      );
      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Aluguel',
        valor: 1500,
        tipo: TipoMovimento.despesa,
        data: hoje,
      );

      final t = await transacoes.totais(usuarioId: demoId, mes: hoje);
      expect(t.receitas, 5000);
      expect(t.despesas, 1500);
    });

    test('filtro de mes isola os lancamentos do periodo', () async {
      final hoje = DateTime.now();
      final mesPassado = DateTime(hoje.year, hoje.month - 1, 15);

      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Deste mes',
        valor: 100,
        tipo: TipoMovimento.despesa,
        data: hoje,
      );
      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Do mes passado',
        valor: 200,
        tipo: TipoMovimento.despesa,
        data: mesPassado,
      );

      expect(await transacoes.listar(usuarioId: demoId, mes: hoje),
          hasLength(1));
      expect(await transacoes.listar(usuarioId: demoId, mes: mesPassado),
          hasLength(1));
      // Sem filtro de mes, vem tudo.
      expect(await transacoes.listar(usuarioId: demoId), hasLength(2));
    });

    test('filtro de tipo e busca por descricao', () async {
      final hoje = DateTime.now();
      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Padaria do bairro',
        valor: 30,
        tipo: TipoMovimento.despesa,
        data: hoje,
      );
      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Salario mensal',
        valor: 5000,
        tipo: TipoMovimento.receita,
        data: hoje,
      );

      expect(
        await transacoes.listar(
            usuarioId: demoId, tipo: TipoMovimento.receita, mes: hoje),
        hasLength(1),
      );
      // A busca ignora maiusculas.
      expect(
        await transacoes.listar(
            usuarioId: demoId, mes: hoje, busca: 'PADARIA'),
        hasLength(1),
      );
      expect(
        await transacoes.listar(usuarioId: demoId, mes: hoje, busca: 'xyz'),
        isEmpty,
      );
    });

    test('um operador nao ve nem apaga transacao de outro', () async {
      final outro = await auth.registrar(
        nome: 'Rei',
        email: 'rei@nerv.jp',
        senha: 'senha123',
        senhaConfirmacao: 'senha123',
      );

      final id = await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Privada',
        valor: 50,
        tipo: TipoMovimento.despesa,
        data: DateTime.now(),
      );

      expect(await transacoes.listar(usuarioId: outro.id), isEmpty);
      expect(await transacoes.buscar(id: id, usuarioId: outro.id), isNull);

      // A exclusao filtra por usuario, entao nada e removido.
      await transacoes.excluir(id: id, usuarioId: outro.id);
      expect(await transacoes.buscar(id: id, usuarioId: demoId), isNotNull);
    });
  });

  group('CategoriaRepository', () {
    test('bloqueia nome duplicado no mesmo tipo', () async {
      expect(
        () => categorias.criar(
          nome: 'Alimentacao',
          tipo: TipoMovimento.despesa,
        ),
        throwsA(isA<RegraNegocioException>()),
      );
    });

    test('permite o mesmo nome em tipos diferentes', () async {
      final id = await categorias.criar(
        nome: 'Alimentacao',
        tipo: TipoMovimento.receita,
      );
      expect(id, greaterThan(0));
    });

    test('recusa nome com menos de 2 caracteres', () async {
      expect(
        () => categorias.criar(nome: 'A', tipo: TipoMovimento.despesa),
        throwsA(isA<RegraNegocioException>()),
      );
    });

    test('ignora o limite mensal em categorias de receita', () async {
      final id = await categorias.criar(
        nome: 'Bonus',
        tipo: TipoMovimento.receita,
        limiteMensal: 500,
      );
      final c = await categorias.buscar(id);
      expect(c!.limiteMensal, isNull);
    });

    test('bloqueia excluir categoria usada por uma transacao', () async {
      final id = await categorias.criar(
        nome: 'Temporaria',
        tipo: TipoMovimento.despesa,
      );
      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Gasto',
        valor: 10,
        tipo: TipoMovimento.despesa,
        data: DateTime.now(),
        categoriaId: id,
      );

      expect(
        () => categorias.excluir(id),
        throwsA(isA<RegraNegocioException>()),
      );
    });

    test('exclui categoria que nao esta em uso', () async {
      final id = await categorias.criar(
        nome: 'Sem uso',
        tipo: TipoMovimento.despesa,
      );
      await categorias.excluir(id);
      expect(await categorias.buscar(id), isNull);
    });

    test('calcula o gasto do mes por categoria', () async {
      final despesas = await categorias.listar(tipo: TipoMovimento.despesa);
      final lazer = despesas.firstWhere((c) => c.nome == 'Lazer');

      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Cinema',
        valor: 60,
        tipo: TipoMovimento.despesa,
        data: DateTime.now(),
        categoriaId: lazer.id,
      );
      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Show',
        valor: 140,
        tipo: TipoMovimento.despesa,
        data: DateTime.now(),
        categoriaId: lazer.id,
      );

      final uso = await categorias.listarComUso(
        usuarioId: demoId,
        mes: DateTime.now(),
      );
      final usoLazer = uso.firstWhere((u) => u.categoria.nome == 'Lazer');
      expect(usoLazer.gasto, 200);
      expect(usoLazer.transacoes, 2);
      // Limite de Lazer e 300, logo 200/300 = 66,7%.
      expect(usoLazer.percentual, closeTo(66.67, 0.01));
      expect(usoLazer.emAlerta, isFalse);
    });

    test('alerta dispara a partir de 80% do limite', () async {
      final despesas = await categorias.listar(tipo: TipoMovimento.despesa);
      final lazer = despesas.firstWhere((c) => c.nome == 'Lazer');

      // Limite 300; 240 e exatamente 80%.
      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Viagem curta',
        valor: 240,
        tipo: TipoMovimento.despesa,
        data: DateTime.now(),
        categoriaId: lazer.id,
      );

      final alertas = await categorias.alertasDeLimite(
        usuarioId: demoId,
        mes: DateTime.now(),
      );
      expect(alertas.map((a) => a.categoria.nome), contains('Lazer'));

      final alertaLazer =
          alertas.firstWhere((a) => a.categoria.nome == 'Lazer');
      expect(alertaLazer.emAlerta, isTrue);
      expect(alertaLazer.estourou, isFalse);
    });

    test('nao alerta abaixo de 80% do limite', () async {
      final despesas = await categorias.listar(tipo: TipoMovimento.despesa);
      final lazer = despesas.firstWhere((c) => c.nome == 'Lazer');

      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Pequeno lazer',
        valor: 239.99,
        tipo: TipoMovimento.despesa,
        data: DateTime.now(),
        categoriaId: lazer.id,
      );

      final alertas = await categorias.alertasDeLimite(
        usuarioId: demoId,
        mes: DateTime.now(),
      );
      expect(alertas.map((a) => a.categoria.nome), isNot(contains('Lazer')));
    });

    test('marca estouro quando passa de 100%', () async {
      final despesas = await categorias.listar(tipo: TipoMovimento.despesa);
      final lazer = despesas.firstWhere((c) => c.nome == 'Lazer');

      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Lazer caro',
        valor: 400,
        tipo: TipoMovimento.despesa,
        data: DateTime.now(),
        categoriaId: lazer.id,
      );

      final alertas = await categorias.alertasDeLimite(
        usuarioId: demoId,
        mes: DateTime.now(),
      );
      final alertaLazer =
          alertas.firstWhere((a) => a.categoria.nome == 'Lazer');
      expect(alertaLazer.estourou, isTrue);
    });
  });

  group('MetaRepository', () {
    Future<Meta> criarMeta({double alvo = 1000, double atual = 0}) async {
      final id = await metas.criar(
        usuarioId: demoId,
        nome: 'Reserva',
        valorAlvo: alvo,
        valorAtual: atual,
      );
      return (await metas.buscar(id: id, usuarioId: demoId))!;
    }

    test('recusa valor atual maior que o alvo', () async {
      expect(
        () => metas.criar(
          usuarioId: demoId,
          nome: 'Impossivel',
          valorAlvo: 100,
          valorAtual: 200,
        ),
        throwsA(isA<RegraNegocioException>()),
      );
    });

    test('recusa alvo zero ou negativo', () async {
      expect(
        () => metas.criar(usuarioId: demoId, nome: 'Zero', valorAlvo: 0),
        throwsA(isA<RegraNegocioException>()),
      );
    });

    test('calcula percentual e quanto falta', () async {
      final m = await criarMeta(alvo: 1000, atual: 250);
      expect(m.percentual, 25);
      expect(m.falta, 750);
      expect(m.concluida, isFalse);
    });

    test('deposito soma ao acumulado', () async {
      final m = await criarMeta(alvo: 1000);
      await metas.depositar(id: m.id, usuarioId: demoId, valor: 300);

      final atualizada = await metas.buscar(id: m.id, usuarioId: demoId);
      expect(atualizada!.valorAtual, 300);
      expect(atualizada.falta, 700);
    });

    test('deposito nao pode ultrapassar o alvo', () async {
      final m = await criarMeta(alvo: 1000, atual: 900);
      expect(
        () => metas.depositar(id: m.id, usuarioId: demoId, valor: 200),
        throwsA(isA<RegraNegocioException>()),
      );

      // O deposito exato que fecha a meta e permitido.
      await metas.depositar(id: m.id, usuarioId: demoId, valor: 100);
      final fechada = await metas.buscar(id: m.id, usuarioId: demoId);
      expect(fechada!.concluida, isTrue);
      expect(fechada.percentual, 100);
    });

    test('deposito recusa valor zero ou negativo', () async {
      final m = await criarMeta();
      expect(
        () => metas.depositar(id: m.id, usuarioId: demoId, valor: 0),
        throwsA(isA<RegraNegocioException>()),
      );
      expect(
        () => metas.depositar(id: m.id, usuarioId: demoId, valor: -50),
        throwsA(isA<RegraNegocioException>()),
      );
    });

    test('retirada devolve o valor e respeita o acumulado', () async {
      final m = await criarMeta(alvo: 1000, atual: 400);
      await metas.retirar(id: m.id, usuarioId: demoId, valor: 150);

      final atualizada = await metas.buscar(id: m.id, usuarioId: demoId);
      expect(atualizada!.valorAtual, 250);

      expect(
        () => metas.retirar(id: m.id, usuarioId: demoId, valor: 999),
        throwsA(isA<RegraNegocioException>()),
      );
    });
  });

  group('RecorrenciaRepository', () {
    test('recusa dia de vencimento fora de 1 a 31', () async {
      for (final dia in [0, 32, -1]) {
        expect(
          () => recorrencias.criar(
            usuarioId: demoId,
            descricao: 'Aluguel',
            valor: 1500,
            tipo: TipoMovimento.despesa,
            diaVencimento: dia,
          ),
          throwsA(isA<RegraNegocioException>()),
          reason: 'dia $dia deveria ser invalido',
        );
      }
    });

    test('nova recorrencia comeca pendente no mes atual', () async {
      await recorrencias.criar(
        usuarioId: demoId,
        descricao: 'Internet',
        valor: 120,
        tipo: TipoMovimento.despesa,
        diaVencimento: 10,
      );

      expect(
        await recorrencias.contarPendentes(
          usuarioId: demoId,
          mes: DateTime.now(),
        ),
        1,
      );
    });

    test('lancar gera a transacao e marca o mes como feito', () async {
      final id = await recorrencias.criar(
        usuarioId: demoId,
        descricao: 'Aluguel',
        valor: 1500,
        tipo: TipoMovimento.despesa,
        diaVencimento: 10,
      );

      final mes = DateTime(2026, 5, 1);
      await recorrencias.lancarNoMes(
        id: id,
        usuarioId: demoId,
        mesReferencia: mes,
      );

      final lancadas = await transacoes.listar(usuarioId: demoId, mes: mes);
      expect(lancadas, hasLength(1));
      expect(lancadas.first.descricao, 'Aluguel');
      expect(lancadas.first.valor, 1500);
      expect(Fmt.chaveData(lancadas.first.data), '2026-05-10');

      final rec = await recorrencias.buscar(id: id, usuarioId: demoId);
      expect(rec!.pendenteEm(mes), isFalse);
    });

    test('nao permite lancar duas vezes no mesmo mes', () async {
      final id = await recorrencias.criar(
        usuarioId: demoId,
        descricao: 'Aluguel',
        valor: 1500,
        tipo: TipoMovimento.despesa,
        diaVencimento: 10,
      );

      final mes = DateTime(2026, 5, 1);
      await recorrencias.lancarNoMes(
          id: id, usuarioId: demoId, mesReferencia: mes);

      expect(
        () => recorrencias.lancarNoMes(
            id: id, usuarioId: demoId, mesReferencia: mes),
        throwsA(isA<RegraNegocioException>()),
      );
      expect(await transacoes.listar(usuarioId: demoId, mes: mes),
          hasLength(1));
    });

    test('volta a ficar pendente no mes seguinte', () async {
      final id = await recorrencias.criar(
        usuarioId: demoId,
        descricao: 'Aluguel',
        valor: 1500,
        tipo: TipoMovimento.despesa,
        diaVencimento: 10,
      );

      await recorrencias.lancarNoMes(
        id: id,
        usuarioId: demoId,
        mesReferencia: DateTime(2026, 5, 1),
      );

      final rec = await recorrencias.buscar(id: id, usuarioId: demoId);
      expect(rec!.pendenteEm(DateTime(2026, 6, 1)), isTrue);
    });

    test('vencimento dia 31 cai no ultimo dia de fevereiro', () async {
      final id = await recorrencias.criar(
        usuarioId: demoId,
        descricao: 'Cartao',
        valor: 800,
        tipo: TipoMovimento.despesa,
        diaVencimento: 31,
      );

      // 2026 nao e bissexto: fevereiro termina em 28.
      final fev = DateTime(2026, 2, 1);
      await recorrencias.lancarNoMes(
          id: id, usuarioId: demoId, mesReferencia: fev);

      final lancadas = await transacoes.listar(usuarioId: demoId, mes: fev);
      expect(Fmt.chaveData(lancadas.first.data), '2026-02-28');
    });

    test('recorrencia inativa nao pode ser lancada nem conta como pendente',
        () async {
      final id = await recorrencias.criar(
        usuarioId: demoId,
        descricao: 'Academia',
        valor: 90,
        tipo: TipoMovimento.despesa,
        diaVencimento: 5,
        ativa: false,
      );

      expect(
        await recorrencias.contarPendentes(
            usuarioId: demoId, mes: DateTime.now()),
        0,
      );
      expect(
        () => recorrencias.lancarNoMes(id: id, usuarioId: demoId),
        throwsA(isA<RegraNegocioException>()),
      );
    });

    test('lancar todas as pendentes de uma vez', () async {
      for (var i = 1; i <= 3; i++) {
        await recorrencias.criar(
          usuarioId: demoId,
          descricao: 'Conta $i',
          valor: 100.0 * i,
          tipo: TipoMovimento.despesa,
          diaVencimento: i * 5,
        );
      }

      final mes = DateTime(2026, 7, 1);
      final quantas = await recorrencias.lancarTodasPendentes(
        usuarioId: demoId,
        mesReferencia: mes,
      );

      expect(quantas, 3);
      expect(await transacoes.listar(usuarioId: demoId, mes: mes),
          hasLength(3));
      expect(await recorrencias.contarPendentes(usuarioId: demoId, mes: mes),
          0);
    });
  });

  group('DashboardRepository', () {
    test('monta o resumo do mes com saldo, metas e pendencias', () async {
      final hoje = DateTime.now();

      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Salario',
        valor: 5000,
        tipo: TipoMovimento.receita,
        data: hoje,
      );
      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Aluguel',
        valor: 1500,
        tipo: TipoMovimento.despesa,
        data: hoje,
      );
      await metas.criar(
        usuarioId: demoId,
        nome: 'Reserva',
        valorAlvo: 10000,
        valorAtual: 2500,
      );
      await recorrencias.criar(
        usuarioId: demoId,
        descricao: 'Internet',
        valor: 120,
        tipo: TipoMovimento.despesa,
        diaVencimento: 10,
      );

      final d = await dashboard.carregar(usuarioId: demoId);

      expect(d.totalReceitas, 5000);
      expect(d.totalDespesas, 1500);
      expect(d.saldo, 3500);
      expect(d.ultimasTransacoes, hasLength(2));
      expect(d.metas, hasLength(1));
      expect(d.metas.first.percentual, 25);
      expect(d.recorrenciasPendentes, 1);
    });

    test('limita as ultimas transacoes a 5', () async {
      for (var i = 0; i < 8; i++) {
        await transacoes.criar(
          usuarioId: demoId,
          descricao: 'Gasto $i',
          valor: 10,
          tipo: TipoMovimento.despesa,
          data: DateTime.now(),
        );
      }
      final d = await dashboard.carregar(usuarioId: demoId);
      expect(d.ultimasTransacoes, hasLength(5));
    });

    test('agrupa despesas por categoria para o grafico', () async {
      final despesas = await categorias.listar(tipo: TipoMovimento.despesa);
      final moradia = despesas.firstWhere((c) => c.nome == 'Moradia');
      final transporte = despesas.firstWhere((c) => c.nome == 'Transporte');

      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Aluguel',
        valor: 1200,
        tipo: TipoMovimento.despesa,
        data: DateTime.now(),
        categoriaId: moradia.id,
      );
      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Condominio',
        valor: 300,
        tipo: TipoMovimento.despesa,
        data: DateTime.now(),
        categoriaId: moradia.id,
      );
      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Gasolina',
        valor: 250,
        tipo: TipoMovimento.despesa,
        data: DateTime.now(),
        categoriaId: transporte.id,
      );

      final d = await dashboard.carregar(usuarioId: demoId);
      expect(d.despesasPorCategoria, hasLength(2));
      // Vem ordenado do maior para o menor.
      expect(d.despesasPorCategoria.first.categoria, 'Moradia');
      expect(d.despesasPorCategoria.first.total, 1500);
      expect(d.despesasPorCategoria.last.total, 250);
    });

    test('relatorio devolve a serie completa, com meses vazios em zero',
        () async {
      await transacoes.criar(
        usuarioId: demoId,
        descricao: 'Salario',
        valor: 3000,
        tipo: TipoMovimento.receita,
        data: DateTime.now(),
      );

      final r = await dashboard.relatorio(usuarioId: demoId, periodoMeses: 6);

      expect(r.evolucao, hasLength(6), reason: 'seis meses, com ou sem dados');
      expect(r.totalReceitas, 3000);
      expect(r.saldo, 3000);
      // O ultimo mes da serie e o atual.
      expect(r.evolucao.last.mes, Fmt.chaveMes(DateTime.now()));
      expect(r.evolucao.last.receitas, 3000);
    });

    test('relatorio respeita o periodo escolhido', () async {
      for (final meses in [3, 6, 12]) {
        final r = await dashboard.relatorio(
          usuarioId: demoId,
          periodoMeses: meses,
        );
        expect(r.evolucao, hasLength(meses));
      }
    });
  });
}
