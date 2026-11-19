import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/eva_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../main.dart';

/// Relatorios por periodo com graficos -- porta do `relatorios.php`.
class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  final _repo = const DashboardRepository();

  /// Mesmas opcoes da versao web: 3, 6 ou 12 meses.
  static const _periodos = [3, 6, 12];
  int _periodo = 6;

  RelatorioData? _dados;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    if (!mounted) return;
    setState(() => _carregando = true);
    final dados = await _repo.relatorio(
      usuarioId: context.app.usuarioId,
      periodoMeses: _periodo,
    );
    if (!mounted) return;
    setState(() {
      _dados = dados;
      _carregando = false;
    });
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
            titulo: 'RELATORIOS',
            subtitulo: '// analise do periodo selecionado',
          ),
          const SizedBox(height: 14),
          // Seletor de periodo.
          Wrap(
            spacing: 8,
            children: [
              for (final meses in _periodos)
                _BotaoPeriodo(
                  texto: '$meses meses',
                  ativo: _periodo == meses,
                  onTap: () {
                    setState(() => _periodo = meses);
                    _carregar();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_carregando || _dados == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            ResponsiveGrid(
              columns: context.colunasResumo,
              children: [
                SummaryCard(
                  rotulo: 'Total Entradas',
                  valor: Fmt.moeda(_dados!.totalReceitas),
                  icone: Icons.south_west,
                  corValor: p.green,
                ),
                SummaryCard(
                  rotulo: 'Total Saidas',
                  valor: Fmt.moeda(_dados!.totalDespesas),
                  icone: Icons.north_east,
                  corValor: p.red,
                ),
                SummaryCard(
                  rotulo: 'Saldo do Periodo',
                  valor: Fmt.moeda(_dados!.saldo),
                  icone: Icons.hexagon_outlined,
                  corValor: _dados!.saldo >= 0 ? p.green : p.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CardEvolucao(dados: _dados!),
            const SizedBox(height: 12),
            _CardTopCategorias(dados: _dados!),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _BotaoPeriodo extends StatelessWidget {
  const _BotaoPeriodo({
    required this.texto,
    required this.ativo,
    required this.onTap,
  });

  final String texto;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: ativo ? p.purple : Colors.transparent,
          border: Border.all(color: ativo ? p.purple : p.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          texto.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTheme.titleFont,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: ativo ? Colors.white : p.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Grafico de barras agrupadas: entradas vs saidas por mes.
class _CardEvolucao extends StatelessWidget {
  const _CardEvolucao({required this.dados});

  final RelatorioData dados;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final serie = dados.evolucao;
    final temMovimento =
        serie.any((m) => m.receitas > 0 || m.despesas > 0);

    final maximo = serie.fold<double>(
      0,
      (max, m) => [max, m.receitas, m.despesas].reduce((a, b) => a > b ? a : b),
    );

    // Cada rotulo (MM/AAAA) ocupa cerca de 52px. Em telas estreitas nao
    // cabe um por mes, entao mostramos de N em N -- contando a partir do
    // mes mais recente, que e o que mais interessa.
    final larguraGrafico = context.screenWidth - (context.isMobile ? 90 : 190);
    final cabem = (larguraGrafico / 52).floor().clamp(1, serie.length);
    final passo = (serie.length / cabem).ceil();

    return EvaCard(
      header: const EvaCardHeader(
        titulo: 'Evolucao Mensal',
        subtitulo: 'entradas e saidas mes a mes',
      ),
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
      child: !temMovimento
          ? const EvaEmptyState(
              icone: Icons.bar_chart,
              mensagem: 'Nenhuma movimentacao neste periodo',
            )
          : Column(
              children: [
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maximo * 1.15,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => p.bg,
                          tooltipBorder: BorderSide(color: p.border),
                          getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                            Fmt.moeda(rod.toY),
                            TextStyle(
                              fontFamily: AppTheme.monoFont,
                              fontSize: 11,
                              color: rod.color,
                            ),
                          ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 52,
                            getTitlesWidget: (valor, meta) => Text(
                              _abreviar(valor),
                              style: TextStyle(
                                fontFamily: AppTheme.monoFont,
                                fontSize: 9,
                                color: p.textMuted,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (valor, meta) {
                              final i = valor.toInt();
                              if (i < 0 || i >= serie.length) {
                                return const SizedBox.shrink();
                              }
                              // Conta a partir do fim para o ultimo mes
                              // sempre aparecer.
                              if ((serie.length - 1 - i) % passo != 0) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  serie[i].label,
                                  style: TextStyle(
                                    fontFamily: AppTheme.titleFont,
                                    fontSize: 8,
                                    color: p.textMuted,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: p.border, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        for (var i = 0; i < serie.length; i++)
                          BarChartGroupData(
                            x: i,
                            barsSpace: 3,
                            barRods: [
                              BarChartRodData(
                                toY: serie[i].receitas,
                                color: p.green,
                                width: 7,
                                borderRadius: BorderRadius.circular(1),
                              ),
                              BarChartRodData(
                                toY: serie[i].despesas,
                                color: p.red,
                                width: 7,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Legenda(cor: p.green, texto: 'Entradas'),
                    const SizedBox(width: 20),
                    _Legenda(cor: p.red, texto: 'Saidas'),
                  ],
                ),
                const SizedBox(height: 14),
                // Tabela com os numeros exatos de cada mes.
                _TabelaEvolucao(serie: serie),
              ],
            ),
    );
  }

  /// Encurta os valores do eixo (1.500 -> 1,5k) para nao poluir.
  static String _abreviar(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _TabelaEvolucao extends StatelessWidget {
  const _TabelaEvolucao({required this.serie});

  final List<ResumoMensal> serie;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          // Cabecalho
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            color: p.bgCardHover,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _celula('MES', 76, p.textMuted, titulo: true),
                _celula('ENTRADAS', 112, p.textMuted, titulo: true),
                _celula('SAIDAS', 112, p.textMuted, titulo: true),
                _celula('SALDO', 112, p.textMuted, titulo: true),
              ],
            ),
          ),
          for (final m in serie)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _celula(m.label, 76, p.text),
                  _celula(Fmt.moeda(m.receitas), 112, p.green),
                  _celula(Fmt.moeda(m.despesas), 112, p.red),
                  _celula(
                    Fmt.moeda(m.saldo),
                    112,
                    m.saldo >= 0 ? p.green : p.red,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _celula(String texto, double largura, Color cor,
          {bool titulo = false}) =>
      SizedBox(
        width: largura,
        child: Text(
          texto,
          style: TextStyle(
            fontFamily: titulo ? AppTheme.titleFont : AppTheme.monoFont,
            fontSize: titulo ? 8.5 : 11,
            fontWeight: titulo ? FontWeight.w700 : FontWeight.w400,
            letterSpacing: titulo ? 0.6 : 0,
            color: cor,
          ),
        ),
      );
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.cor, required this.texto});

  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Row(
      children: [
        Container(width: 10, height: 10, color: cor),
        const SizedBox(width: 7),
        Text(
          texto,
          style: TextStyle(
            fontFamily: AppTheme.titleFont,
            fontSize: 9,
            letterSpacing: 0.4,
            color: p.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Top 6 categorias de despesa do periodo, em barras horizontais.
class _CardTopCategorias extends StatelessWidget {
  const _CardTopCategorias({required this.dados});

  final RelatorioData dados;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final itens = dados.topCategorias;
    final maximo = itens.isEmpty
        ? 0.0
        : itens.map((e) => e.total).reduce((a, b) => a > b ? a : b);

    return EvaCard(
      header: const EvaCardHeader(
        titulo: 'Maiores Despesas por Categoria',
        subtitulo: 'top 6 do periodo',
      ),
      padding: const EdgeInsets.all(16),
      child: itens.isEmpty
          ? const EvaEmptyState(
              icone: Icons.sell_outlined,
              mensagem: 'Nenhuma despesa neste periodo',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < itens.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  _BarraCategoria(
                    item: itens[i],
                    maximo: maximo,
                    cor: p.chartColors[i % p.chartColors.length],
                    percentualDoTotal: dados.totalDespesas > 0
                        ? (itens[i].total / dados.totalDespesas) * 100
                        : 0,
                  ),
                ],
              ],
            ),
    );
  }
}

class _BarraCategoria extends StatelessWidget {
  const _BarraCategoria({
    required this.item,
    required this.maximo,
    required this.cor,
    required this.percentualDoTotal,
  });

  final TotalPorCategoria item;
  final double maximo;
  final Color cor;
  final double percentualDoTotal;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.categoria,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: p.text),
              ),
            ),
            Text(
              '${Fmt.pct(percentualDoTotal)}  ',
              style: TextStyle(fontSize: 10, color: p.textMuted),
            ),
            EvaMoney(valor: item.total, cor: cor, fontSize: 12),
          ],
        ),
        const SizedBox(height: 6),
        EvaProgressBar(
          percentual: maximo > 0 ? (item.total / maximo) * 100 : 0,
          cor: cor,
        ),
      ],
    );
  }
}
