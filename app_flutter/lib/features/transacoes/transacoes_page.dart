import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/eva_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/transacao_repository.dart';
import '../../main.dart';
import '../shared/form_widgets.dart';
import 'transacao_form_page.dart';

/// Listagem de transacoes com filtros -- porta do `transacoes/index.php`.
class TransacoesPage extends StatefulWidget {
  const TransacoesPage({super.key});

  @override
  State<TransacoesPage> createState() => _TransacoesPageState();
}

class _TransacoesPageState extends State<TransacoesPage> {
  final _repo = const TransacaoRepository();
  final _busca = TextEditingController();

  TipoMovimento? _filtroTipo;
  DateTime _filtroMes = DateTime.now();
  bool _todosOsMeses = false;

  List<Transacao> _itens = const [];
  ({double receitas, double despesas}) _totais =
      (receitas: 0.0, despesas: 0.0);
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    if (!mounted) return;
    setState(() => _carregando = true);

    final usuarioId = context.app.usuarioId;
    final mes = _todosOsMeses ? null : _filtroMes;

    final itens = await _repo.listar(
      usuarioId: usuarioId,
      tipo: _filtroTipo,
      mes: mes,
      busca: _busca.text,
    );
    final totais = await _repo.totais(
      usuarioId: usuarioId,
      tipo: _filtroTipo,
      mes: mes,
      busca: _busca.text,
    );

    if (!mounted) return;
    setState(() {
      _itens = itens;
      _totais = totais;
      _carregando = false;
    });
  }

  Future<void> _abrirFormulario([Transacao? t]) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TransacaoFormPage(transacao: t)),
    );
    if (salvou == true && mounted) {
      context.app.notificarMudanca();
      avisar(
        context,
        t == null ? 'Transacao registrada.' : 'Transacao atualizada.',
      );
      await _carregar();
    }
  }

  Future<void> _excluir(Transacao t) async {
    final ok = await confirmar(
      context,
      titulo: 'Excluir transacao',
      mensagem: 'Remover "${t.descricao}" de ${Fmt.data(t.data)}? '
          'Esta acao nao pode ser desfeita.',
    );
    if (!ok || !mounted) return;

    await _repo.excluir(id: t.id, usuarioId: context.app.usuarioId);
    if (!mounted) return;
    context.app.notificarMudanca();
    avisar(context, 'Transacao excluida.');
    await _carregar();
  }

  Future<void> _escolherMes() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _filtroMes,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Escolha qualquer dia do mes',
      locale: const Locale('pt', 'BR'),
    );
    if (escolhida == null) return;
    setState(() {
      _filtroMes = escolhida;
      _todosOsMeses = false;
    });
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.eva;

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: context.paddingPagina,
        children: [
          EvaPageTitle(
            titulo: 'TRANSACOES',
            subtitulo: '// gerencie suas entradas e saidas',
            acao: FilledButton.icon(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.isMobile ? '' : 'NOVA'),
            ),
          ),
          const SizedBox(height: 18),
          _Filtros(
            busca: _busca,
            filtroTipo: _filtroTipo,
            mes: _filtroMes,
            todosOsMeses: _todosOsMeses,
            onTipo: (t) {
              setState(() => _filtroTipo = t);
              _carregar();
            },
            onEscolherMes: _escolherMes,
            onTodosOsMeses: () {
              setState(() => _todosOsMeses = !_todosOsMeses);
              _carregar();
            },
            onBuscar: _carregar,
          ),
          const SizedBox(height: 14),
          ResponsiveGrid(
            columns: context.isMobile ? 1 : 3,
            children: [
              SummaryCard(
                rotulo: 'Entradas (filtro)',
                valor: Fmt.moeda(_totais.receitas),
                icone: Icons.south_west,
                corValor: p.green,
              ),
              SummaryCard(
                rotulo: 'Saidas (filtro)',
                valor: Fmt.moeda(_totais.despesas),
                icone: Icons.north_east,
                corValor: p.red,
              ),
              SummaryCard(
                rotulo: 'Saldo (filtro)',
                valor: Fmt.moeda(_totais.receitas - _totais.despesas),
                icone: Icons.hexagon_outlined,
                corValor: _totais.receitas - _totais.despesas >= 0
                    ? p.green
                    : p.red,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_carregando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            EvaCard(
              header: EvaCardHeader(
                titulo: 'Lancamentos',
                subtitulo: '${_itens.length} registro(s)',
              ),
              padding: EdgeInsets.zero,
              child: _itens.isEmpty
                  ? EvaEmptyState(
                      icone: Icons.inbox_outlined,
                      mensagem: 'Nenhuma transacao encontrada com '
                          'estes filtros',
                      acao: FilledButton.icon(
                        onPressed: () => _abrirFormulario(),
                        icon: const Icon(Icons.add, size: 15),
                        label: const Text('ADICIONAR'),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < _itens.length; i++) ...[
                          if (i > 0) Divider(height: 1, color: p.border),
                          _ItemTransacao(
                            transacao: _itens[i],
                            onEditar: () => _abrirFormulario(_itens[i]),
                            onExcluir: () => _excluir(_itens[i]),
                          ),
                        ],
                      ],
                    ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.busca,
    required this.filtroTipo,
    required this.mes,
    required this.todosOsMeses,
    required this.onTipo,
    required this.onEscolherMes,
    required this.onTodosOsMeses,
    required this.onBuscar,
  });

  final TextEditingController busca;
  final TipoMovimento? filtroTipo;
  final DateTime mes;
  final bool todosOsMeses;
  final ValueChanged<TipoMovimento?> onTipo;
  final VoidCallback onEscolherMes;
  final VoidCallback onTodosOsMeses;
  final VoidCallback onBuscar;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;

    return EvaCard(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Filtro de tipo: Todos / Receita / Despesa
          _ChipFiltro(
            texto: 'Todos',
            ativo: filtroTipo == null,
            onTap: () => onTipo(null),
          ),
          for (final t in TipoMovimento.values)
            _ChipFiltro(
              texto: t.label,
              ativo: filtroTipo == t,
              cor: t.isReceita ? p.green : p.red,
              onTap: () => onTipo(t),
            ),
          Container(width: 1, height: 26, color: p.border),
          _ChipFiltro(
            texto: todosOsMeses ? 'Todos os meses' : Fmt.mesExtenso(mes),
            icone: Icons.calendar_month,
            ativo: !todosOsMeses,
            onTap: onEscolherMes,
          ),
          _ChipFiltro(
            texto: todosOsMeses ? 'Filtrar por mes' : 'Ver todos os meses',
            icone: Icons.all_inclusive,
            ativo: todosOsMeses,
            onTap: onTodosOsMeses,
          ),
          SizedBox(
            width: context.isMobile ? double.infinity : 220,
            child: TextField(
              controller: busca,
              onSubmitted: (_) => onBuscar(),
              onChanged: (_) => onBuscar(),
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 13,
                color: p.textBright,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Buscar descricao...',
                prefixIcon: const Icon(Icons.search, size: 17),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({
    required this.texto,
    required this.ativo,
    required this.onTap,
    this.icone,
    this.cor,
  });

  final String texto;
  final bool ativo;
  final VoidCallback onTap;
  final IconData? icone;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final c = cor ?? p.purple;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: ativo ? c.withValues(alpha: 0.14) : Colors.transparent,
          border: Border.all(
            color: ativo ? c.withValues(alpha: 0.5) : p.border,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone, size: 13, color: ativo ? c : p.textMuted),
              const SizedBox(width: 6),
            ],
            Text(
              texto,
              style: TextStyle(
                fontFamily: AppTheme.titleFont,
                fontSize: 9.5,
                fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.4,
                color: ativo ? c : p.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemTransacao extends StatelessWidget {
  const _ItemTransacao({
    required this.transacao,
    required this.onEditar,
    required this.onExcluir,
  });

  final Transacao transacao;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final t = transacao;
    final cor = t.tipo.isReceita ? p.green : p.red;

    return InkWell(
      onTap: onEditar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.1),
                border: Border.all(color: cor.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                t.tipo.isReceita ? Icons.south_west : Icons.north_east,
                size: 15,
                color: cor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.descricao,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, color: p.text),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        t.categoriaNome ?? 'Sem categoria',
                        style: TextStyle(fontSize: 10.5, color: p.textMuted),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 9, color: p.border),
                      const SizedBox(width: 8),
                      Text(
                        Fmt.data(t.data),
                        style: TextStyle(fontSize: 10.5, color: p.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            EvaMoney(valor: t.valor, cor: cor, sinal: t.tipo.isReceita),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: p.textMuted),
              onSelected: (v) {
                if (v == 'editar') onEditar();
                if (v == 'excluir') onExcluir();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 16, color: p.textMuted),
                      const SizedBox(width: 10),
                      const Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'excluir',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 16, color: p.red),
                      const SizedBox(width: 10),
                      Text('Excluir', style: TextStyle(color: p.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
