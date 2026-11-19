import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/eva_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../main.dart';
import '../shared/form_widgets.dart';
import '../transacoes/transacao_form_page.dart';

/// Painel de controle -- porta do `dashboard.php`.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _repo = const DashboardRepository();
  Future<DashboardData>? _futuro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _futuro ??= _repo.carregar(usuarioId: context.app.usuarioId);
  }

  Future<void> _recarregar() async {
    setState(() {
      _futuro = _repo.carregar(usuarioId: context.app.usuarioId);
    });
    await _futuro;
  }

  Future<void> _novaTransacao() async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TransacaoFormPage()),
    );
    if (salvou == true && mounted) {
      context.app.notificarMudanca();
      avisar(context, 'Transacao registrada.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;

    return RefreshIndicator(
      onRefresh: _recarregar,
      child: FutureBuilder<DashboardData>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErroCarga(erro: snap.error!, onTentar: _recarregar);
          }

          final dados = snap.data!;
          return ListView(
            padding: context.paddingPagina,
            children: [
              EvaPageTitle(
                titulo: 'PAINEL DE CONTROLE',
                subtitulo:
                    '// OPERADOR: ${(app.usuario?.nome ?? '').toUpperCase()}',
                acao: FilledButton.icon(
                  onPressed: _novaTransacao,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(context.isMobile ? '' : 'REGISTRAR'),
                ),
              ),
              const SizedBox(height: 18),
              _CardsResumo(dados: dados),
              const SizedBox(height: 14),
              _Alertas(dados: dados, onRecarregar: _recarregar),
              _ConteudoPrincipal(dados: dados),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

class _CardsResumo extends StatelessWidget {
  const _CardsResumo({required this.dados});

  final DashboardData dados;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return ResponsiveGrid(
      columns: context.colunasResumo,
      children: [
        SummaryCard(
          rotulo: 'Saldo Mensal',
          valor: Fmt.moeda(dados.saldo),
          icone: Icons.hexagon_outlined,
          corValor: dados.saldo >= 0 ? p.green : p.red,
        ),
        SummaryCard(
          rotulo: 'Entradas',
          valor: Fmt.moeda(dados.totalReceitas),
          icone: Icons.south_west,
          corValor: p.green,
        ),
        SummaryCard(
          rotulo: 'Saidas',
          valor: Fmt.moeda(dados.totalDespesas),
          icone: Icons.north_east,
          corValor: p.red,
        ),
      ],
    );
  }
}

/// Avisos de recorrencia pendente e de categorias perto do limite.
class _Alertas extends StatelessWidget {
  const _Alertas({required this.dados, required this.onRecarregar});

  final DashboardData dados;
  final Future<void> Function() onRecarregar;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final avisos = <Widget>[];

    if (dados.recorrenciasPendentes > 0) {
      avisos.add(
        EvaAlert(
          icone: Icons.autorenew,
          cor: p.yellow,
          child: Text(
            '${dados.recorrenciasPendentes} recorrencia(s) pendente(s) '
            'para este mes. Abra Recorrencias para lancar.',
            style: TextStyle(fontSize: 12, color: p.yellow),
          ),
        ),
      );
    }

    for (final a in dados.alertasLimite) {
      final pct = a.percentual ?? 0;
      final cor = a.estourou ? p.red : p.yellow;
      avisos.add(
        EvaAlert(
          icone: a.estourou ? Icons.error_outline : Icons.warning_amber,
          cor: cor,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: a.categoria.nome,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ': ${Fmt.moeda(a.gasto)} de '
                      '${Fmt.moeda(a.categoria.limiteMensal!)} '
                      '(${Fmt.pct(pct)})',
                ),
              ],
            ),
            style: TextStyle(fontSize: 12, color: cor),
          ),
        ),
      );
    }

    if (avisos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ResponsiveGrid(
        columns: context.isMobile ? 1 : 2,
        children: avisos,
      ),
    );
  }
}

/// Grafico de despesas, metas e ultimas transacoes.
///
/// No desktop ficam lado a lado; no celular, empilhados.
class _ConteudoPrincipal extends StatelessWidget {
  const _ConteudoPrincipal({required this.dados});

  final DashboardData dados;

  @override
  Widget build(BuildContext context) {
    final grafico = _CardDespesasPorCategoria(dados: dados);
    final metas = dados.metas.isEmpty ? null : _CardMetas(metas: dados.metas);
    final ultimas = _CardUltimasTransacoes(dados: dados);

    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          grafico,
          if (metas != null) ...[const SizedBox(height: 12), metas],
          const SizedBox(height: 12),
          ultimas,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 4, child: grafico),
              if (metas != null) ...[
                const SizedBox(width: 12),
                Expanded(flex: 4, child: metas),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        ultimas,
      ],
    );
  }
}

class _CardDespesasPorCategoria extends StatelessWidget {
  const _CardDespesasPorCategoria({required this.dados});

  final DashboardData dados;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final itens = dados.despesasPorCategoria;

    return EvaCard(
      header: const EvaCardHeader(
        titulo: 'Despesas por Categoria',
        subtitulo: 'Mes atual',
      ),
      padding: const EdgeInsets.all(16),
      child: itens.isEmpty
          ? const EvaEmptyState(
              icone: Icons.pie_chart_outline,
              mensagem: 'Nenhuma despesa registrada este mes',
            )
          : Column(
              children: [
                SizedBox(
                  height: 170,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 44,
                      startDegreeOffset: -90,
                      sections: [
                        for (var i = 0; i < itens.length; i++)
                          PieChartSectionData(
                            value: itens[i].total,
                            radius: 30,
                            showTitle: false,
                            color: p.chartColors[i % p.chartColors.length]
                                .withValues(alpha: 0.75),
                            borderSide: BorderSide(color: p.border, width: 1),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Legenda com valor ao lado, no lugar do tooltip da web.
                for (var i = 0; i < itens.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: p.chartColors[i % p.chartColors.length]
                                .withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            itens[i].categoria,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, color: p.text),
                          ),
                        ),
                        EvaMoney(
                          valor: itens[i].total,
                          cor: p.purpleLight,
                          fontSize: 11.5,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _CardMetas extends StatelessWidget {
  const _CardMetas({required this.metas});

  final List<Meta> metas;

  @override
  Widget build(BuildContext context) {
    return EvaCard(
      header: const EvaCardHeader(
        titulo: 'Metas',
        subtitulo: 'Progresso atual',
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final m in metas) ...[
            if (m != metas.first) const SizedBox(height: 16),
            _LinhaMeta(meta: m),
          ],
        ],
      ),
    );
  }
}

class _LinhaMeta extends StatelessWidget {
  const _LinhaMeta({required this.meta});

  final Meta meta;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final pct = meta.percentual;
    // Mesma escala de cores do dashboard.php.
    final cor = pct >= 100
        ? p.green
        : (pct >= 60 ? p.yellow : p.purpleLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                meta.nome,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontSize: 12.5,
                  color: p.text,
                ),
              ),
            ),
            Text(
              Fmt.pct(pct),
              style: TextStyle(
                fontFamily: AppTheme.titleFont,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: cor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        EvaProgressBar(percentual: pct, cor: cor),
        const SizedBox(height: 5),
        Text(
          '${Fmt.moeda(meta.valorAtual)} / ${Fmt.moeda(meta.valorAlvo)}',
          style: TextStyle(fontSize: 10, color: p.textMuted),
        ),
      ],
    );
  }
}

class _CardUltimasTransacoes extends StatelessWidget {
  const _CardUltimasTransacoes({required this.dados});

  final DashboardData dados;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final itens = dados.ultimasTransacoes;

    return EvaCard(
      header: const EvaCardHeader(
        titulo: 'Ultimas Transacoes',
        subtitulo: '5 mais recentes',
      ),
      padding: EdgeInsets.zero,
      child: itens.isEmpty
          ? const EvaEmptyState(
              icone: Icons.inbox_outlined,
              mensagem: 'Nenhuma transacao registrada ainda',
            )
          : Column(
              children: [
                for (var i = 0; i < itens.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: p.border),
                  _LinhaTransacao(transacao: itens[i]),
                ],
              ],
            ),
    );
  }
}

class _LinhaTransacao extends StatelessWidget {
  const _LinhaTransacao({required this.transacao});

  final Transacao transacao;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final t = transacao;
    final cor = t.tipo.isReceita ? p.green : p.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            t.tipo.isReceita ? Icons.south_west : Icons.north_east,
            size: 14,
            color: cor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.descricao,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: p.text),
                ),
                const SizedBox(height: 2),
                Text(
                  '${t.categoriaNome ?? 'Sem categoria'}  -  ${Fmt.data(t.data)}',
                  style: TextStyle(fontSize: 10.5, color: p.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          EvaMoney(valor: t.valor, cor: cor, sinal: t.tipo.isReceita),
        ],
      ),
    );
  }
}

class _ErroCarga extends StatelessWidget {
  const _ErroCarga({required this.erro, required this.onTentar});

  final Object erro;
  final Future<void> Function() onTentar;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: p.red, size: 36),
            const SizedBox(height: 12),
            Text(
              'Falha ao carregar os dados',
              style: TextStyle(
                fontFamily: AppTheme.titleFont,
                fontSize: 12,
                color: p.textBright,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$erro',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: p.textMuted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onTentar,
              icon: const Icon(Icons.refresh, size: 15),
              label: const Text('TENTAR DE NOVO'),
            ),
          ],
        ),
      ),
    );
  }
}
