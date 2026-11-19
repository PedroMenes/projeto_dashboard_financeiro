import '../../core/utils/formatters.dart';

/// Tipo de movimentacao -- espelha o ENUM('receita','despesa') do MySQL.
enum TipoMovimento {
  receita('receita', 'Receita'),
  despesa('despesa', 'Despesa');

  const TipoMovimento(this.valor, this.label);

  /// Valor gravado no banco.
  final String valor;

  /// Texto exibido na interface.
  final String label;

  bool get isReceita => this == TipoMovimento.receita;

  static TipoMovimento fromDb(String v) =>
      v == 'receita' ? TipoMovimento.receita : TipoMovimento.despesa;
}

/// Tabela `usuarios`.
class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.criadoEm,
  });

  final int id;
  final String nome;
  final String email;
  final DateTime criadoEm;

  factory Usuario.fromMap(Map<String, Object?> m) => Usuario(
        id: m['id']! as int,
        nome: m['nome']! as String,
        email: m['email']! as String,
        criadoEm: DateTime.parse(m['created_at']! as String),
      );
}

/// Tabela `categorias`.
class Categoria {
  const Categoria({
    required this.id,
    required this.nome,
    required this.tipo,
    this.limiteMensal,
  });

  final int id;
  final String nome;
  final TipoMovimento tipo;

  /// Limite de gasto mensal (so faz sentido para despesas). Null = sem limite.
  final double? limiteMensal;

  factory Categoria.fromMap(Map<String, Object?> m) => Categoria(
        id: m['id']! as int,
        nome: m['nome']! as String,
        tipo: TipoMovimento.fromDb(m['tipo']! as String),
        limiteMensal: (m['limite_mensal'] as num?)?.toDouble(),
      );

  Map<String, Object?> toMap() => {
        'nome': nome,
        'tipo': tipo.valor,
        'limite_mensal': limiteMensal,
      };

  Categoria copyWith({String? nome, TipoMovimento? tipo, double? limiteMensal}) =>
      Categoria(
        id: id,
        nome: nome ?? this.nome,
        tipo: tipo ?? this.tipo,
        limiteMensal: limiteMensal,
      );
}

/// Tabela `transacoes`, com o nome da categoria vindo do JOIN.
class Transacao {
  const Transacao({
    required this.id,
    required this.usuarioId,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.data,
    this.categoriaId,
    this.categoriaNome,
  });

  final int id;
  final int usuarioId;
  final String descricao;
  final double valor;
  final TipoMovimento tipo;
  final DateTime data;
  final int? categoriaId;

  /// Preenchido quando a consulta faz LEFT JOIN em categorias.
  final String? categoriaNome;

  factory Transacao.fromMap(Map<String, Object?> m) => Transacao(
        id: m['id']! as int,
        usuarioId: m['usuario_id']! as int,
        descricao: m['descricao']! as String,
        valor: (m['valor']! as num).toDouble(),
        tipo: TipoMovimento.fromDb(m['tipo']! as String),
        data: DateTime.parse(m['data']! as String),
        categoriaId: m['categoria_id'] as int?,
        categoriaNome: m['categoria'] as String?,
      );

  Map<String, Object?> toMap() => {
        'usuario_id': usuarioId,
        'descricao': descricao,
        'valor': valor,
        'tipo': tipo.valor,
        'categoria_id': categoriaId,
        'data': Fmt.chaveData(data),
      };
}

/// Tabela `metas`.
class Meta {
  const Meta({
    required this.id,
    required this.usuarioId,
    required this.nome,
    required this.valorAlvo,
    required this.valorAtual,
    this.descricao,
    this.prazo,
  });

  final int id;
  final int usuarioId;
  final String nome;
  final String? descricao;
  final double valorAlvo;
  final double valorAtual;
  final DateTime? prazo;

  /// Progresso de 0 a 100, limitado em 100 como na versao web.
  double get percentual =>
      valorAlvo > 0 ? ((valorAtual / valorAlvo) * 100).clamp(0, 100) : 0;

  /// Quanto ainda falta para bater a meta.
  double get falta => (valorAlvo - valorAtual).clamp(0, double.infinity);

  bool get concluida => valorAtual >= valorAlvo;

  factory Meta.fromMap(Map<String, Object?> m) => Meta(
        id: m['id']! as int,
        usuarioId: m['usuario_id']! as int,
        nome: m['nome']! as String,
        descricao: m['descricao'] as String?,
        valorAlvo: (m['valor_alvo']! as num).toDouble(),
        valorAtual: (m['valor_atual']! as num).toDouble(),
        prazo: (m['prazo'] as String?) == null
            ? null
            : DateTime.parse(m['prazo']! as String),
      );

  Map<String, Object?> toMap() => {
        'usuario_id': usuarioId,
        'nome': nome,
        'descricao': descricao,
        'valor_alvo': valorAlvo,
        'valor_atual': valorAtual,
        'prazo': prazo == null ? null : Fmt.chaveData(prazo!),
      };
}

/// Tabela `recorrencias`.
class Recorrencia {
  const Recorrencia({
    required this.id,
    required this.usuarioId,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.diaVencimento,
    required this.ativa,
    this.categoriaId,
    this.categoriaNome,
    this.ultimoLancamento,
  });

  final int id;
  final int usuarioId;
  final String descricao;
  final double valor;
  final TipoMovimento tipo;
  final int diaVencimento;
  final bool ativa;
  final int? categoriaId;
  final String? categoriaNome;
  final DateTime? ultimoLancamento;

  /// true quando a recorrencia esta ativa e ainda nao foi lancada no mes.
  bool pendenteEm(DateTime mes) {
    if (!ativa) return false;
    if (ultimoLancamento == null) return true;
    return Fmt.chaveMes(ultimoLancamento!) != Fmt.chaveMes(mes);
  }

  factory Recorrencia.fromMap(Map<String, Object?> m) => Recorrencia(
        id: m['id']! as int,
        usuarioId: m['usuario_id']! as int,
        descricao: m['descricao']! as String,
        valor: (m['valor']! as num).toDouble(),
        tipo: TipoMovimento.fromDb(m['tipo']! as String),
        diaVencimento: m['dia_vencimento']! as int,
        ativa: (m['ativa']! as int) == 1,
        categoriaId: m['categoria_id'] as int?,
        categoriaNome: m['categoria'] as String?,
        ultimoLancamento: (m['ultimo_lancamento'] as String?) == null
            ? null
            : DateTime.parse(m['ultimo_lancamento']! as String),
      );

  Map<String, Object?> toMap() => {
        'usuario_id': usuarioId,
        'descricao': descricao,
        'valor': valor,
        'tipo': tipo.valor,
        'categoria_id': categoriaId,
        'dia_vencimento': diaVencimento,
        'ativa': ativa ? 1 : 0,
        'ultimo_lancamento':
            ultimoLancamento == null ? null : Fmt.chaveData(ultimoLancamento!),
      };
}

/// Uso de uma categoria contra seu limite no mes -- alimenta os alertas
/// do dashboard e a listagem de categorias.
class UsoCategoria {
  const UsoCategoria({
    required this.categoria,
    required this.gasto,
    required this.transacoes,
  });

  final Categoria categoria;
  final double gasto;
  final int transacoes;

  double? get percentual {
    final limite = categoria.limiteMensal;
    if (limite == null || limite <= 0) return null;
    return (gasto / limite) * 100;
  }

  /// A web dispara alerta a partir de 80% do limite.
  bool get emAlerta => (percentual ?? 0) >= 80;
  bool get estourou => (percentual ?? 0) >= 100;
}

/// Linha agregada de um mes, usada nos relatorios.
class ResumoMensal {
  const ResumoMensal({
    required this.mes,
    required this.receitas,
    required this.despesas,
  });

  /// Chave no formato YYYY-MM.
  final String mes;
  final double receitas;
  final double despesas;

  double get saldo => receitas - despesas;

  /// Rotulo MM/YYYY exibido nos graficos.
  String get label {
    final partes = mes.split('-');
    return '${partes[1]}/${partes[0]}';
  }
}

/// Par categoria + total, usado nos graficos de pizza e barras.
class TotalPorCategoria {
  const TotalPorCategoria({required this.categoria, required this.total});

  final String categoria;
  final double total;
}

/// Pacote com tudo que o dashboard precisa, montado numa unica consulta.
class DashboardData {
  const DashboardData({
    required this.totalReceitas,
    required this.totalDespesas,
    required this.ultimasTransacoes,
    required this.recorrenciasPendentes,
    required this.metas,
    required this.alertasLimite,
    required this.despesasPorCategoria,
  });

  final double totalReceitas;
  final double totalDespesas;
  final List<Transacao> ultimasTransacoes;
  final int recorrenciasPendentes;
  final List<Meta> metas;
  final List<UsoCategoria> alertasLimite;
  final List<TotalPorCategoria> despesasPorCategoria;

  double get saldo => totalReceitas - totalDespesas;
}

/// Pacote com os dados da tela de relatorios.
class RelatorioData {
  const RelatorioData({
    required this.evolucao,
    required this.topCategorias,
    required this.totalReceitas,
    required this.totalDespesas,
  });

  final List<ResumoMensal> evolucao;
  final List<TotalPorCategoria> topCategorias;
  final double totalReceitas;
  final double totalDespesas;

  double get saldo => totalReceitas - totalDespesas;
}
