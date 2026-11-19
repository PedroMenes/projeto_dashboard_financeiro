import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/eva_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/recorrencia_repository.dart';
import '../../main.dart';
import '../shared/form_widgets.dart';
import 'recorrencia_form_page.dart';

/// Listagem de recorrencias separada em pendentes / lancadas / inativas,
/// como o `recorrencias/index.php`.
class RecorrenciasPage extends StatefulWidget {
  const RecorrenciasPage({super.key});

  @override
  State<RecorrenciasPage> createState() => _RecorrenciasPageState();
}

class _RecorrenciasPageState extends State<RecorrenciasPage> {
  final _repo = const RecorrenciaRepository();
  final _mes = DateTime.now();

  List<Recorrencia> _itens = const [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    if (!mounted) return;
    setState(() => _carregando = true);
    final itens = await _repo.listar(context.app.usuarioId);
    if (!mounted) return;
    setState(() {
      _itens = itens;
      _carregando = false;
    });
  }

  Future<void> _abrirFormulario([Recorrencia? r]) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RecorrenciaFormPage(recorrencia: r)),
    );
    if (salvou == true && mounted) {
      context.app.notificarMudanca();
      avisar(
        context,
        r == null ? 'Recorrencia criada.' : 'Recorrencia atualizada.',
      );
      await _carregar();
    }
  }

  Future<void> _lancar(Recorrencia r) async {
    final erros = await executarSalvando(() async {
      await _repo.lancarNoMes(
        id: r.id,
        usuarioId: context.app.usuarioId,
        mesReferencia: _mes,
      );
    });
    if (!mounted) return;

    if (erros.isNotEmpty) {
      avisar(context, erros.first, erro: true);
      return;
    }
    context.app.notificarMudanca();
    avisar(context, '"${r.descricao}" lancada em ${Fmt.mesAno(_mes)}.');
    await _carregar();
  }

  Future<void> _lancarTodas(int quantidade) async {
    final ok = await confirmar(
      context,
      titulo: 'Lancar pendentes',
      mensagem: 'Gerar $quantidade transacao(oes) para '
          '${Fmt.mesExtenso(_mes)}?',
      rotuloConfirmar: 'Lancar',
      destrutivo: false,
    );
    if (!ok || !mounted) return;

    final erros = await executarSalvando(() async {
      await _repo.lancarTodasPendentes(
        usuarioId: context.app.usuarioId,
        mesReferencia: _mes,
      );
    });
    if (!mounted) return;

    if (erros.isNotEmpty) {
      avisar(context, erros.first, erro: true);
      return;
    }
    context.app.notificarMudanca();
    avisar(context, '$quantidade recorrencia(s) lancada(s).');
    await _carregar();
  }

  Future<void> _alternar(Recorrencia r) async {
    await _repo.alternarAtiva(
      id: r.id,
      usuarioId: context.app.usuarioId,
      ativa: !r.ativa,
    );
    if (!mounted) return;
    context.app.notificarMudanca();
    avisar(context, r.ativa ? 'Recorrencia desativada.' : 'Recorrencia ativada.');
    await _carregar();
  }

  Future<void> _excluir(Recorrencia r) async {
    final ok = await confirmar(
      context,
      titulo: 'Excluir recorrencia',
      mensagem: 'Remover "${r.descricao}"? As transacoes ja lancadas '
          'a partir dela continuam no historico.',
    );
    if (!ok || !mounted) return;

    await _repo.excluir(id: r.id, usuarioId: context.app.usuarioId);
    if (!mounted) return;
    context.app.notificarMudanca();
    avisar(context, 'Recorrencia excluida.');
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.eva;

    final pendentes = _itens.where((r) => r.pendenteEm(_mes)).toList();
    final lancadas =
        _itens.where((r) => r.ativa && !r.pendenteEm(_mes)).toList();
    final inativas = _itens.where((r) => !r.ativa).toList();

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: context.paddingPagina,
        children: [
          EvaPageTitle(
            titulo: 'RECORRENCIAS',
            subtitulo: '// contas fixas de ${Fmt.mesExtenso(_mes)}',
            acao: FilledButton.icon(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.isMobile ? '' : 'NOVA'),
            ),
          ),
          const SizedBox(height: 18),
          if (_carregando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (pendentes.length > 1) ...[
              EvaAlert(
                icone: Icons.autorenew,
                cor: p.yellow,
                onTap: () => _lancarTodas(pendentes.length),
                child: Text(
                  '${pendentes.length} pendentes. Toque para lancar '
                  'todas de uma vez.',
                  style: TextStyle(fontSize: 12, color: p.yellow),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _Secao(
              titulo: 'Pendentes neste mes',
              subtitulo: 'aguardando lancamento',
              cor: p.yellow,
              itens: pendentes,
              mes: _mes,
              onLancar: _lancar,
              onEditar: _abrirFormulario,
              onAlternar: _alternar,
              onExcluir: _excluir,
            ),
            const SizedBox(height: 12),
            _Secao(
              titulo: 'Ja lancadas',
              subtitulo: 'geradas em ${Fmt.mesAno(_mes)}',
              cor: p.green,
              itens: lancadas,
              mes: _mes,
              onLancar: _lancar,
              onEditar: _abrirFormulario,
              onAlternar: _alternar,
              onExcluir: _excluir,
            ),
            if (inativas.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Secao(
                titulo: 'Inativas',
                subtitulo: 'nao geram lancamento',
                cor: p.textMuted,
                itens: inativas,
                mes: _mes,
                onLancar: _lancar,
                onEditar: _abrirFormulario,
                onAlternar: _alternar,
                onExcluir: _excluir,
              ),
            ],
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({
    required this.titulo,
    required this.subtitulo,
    required this.cor,
    required this.itens,
    required this.mes,
    required this.onLancar,
    required this.onEditar,
    required this.onAlternar,
    required this.onExcluir,
  });

  final String titulo;
  final String subtitulo;
  final Color cor;
  final List<Recorrencia> itens;
  final DateTime mes;
  final void Function(Recorrencia) onLancar;
  final void Function(Recorrencia) onEditar;
  final void Function(Recorrencia) onAlternar;
  final void Function(Recorrencia) onExcluir;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return EvaCard(
      header: Row(
        children: [
          Container(width: 3, height: 26, color: cor),
          const SizedBox(width: 10),
          Expanded(
            child: EvaCardHeader(
              titulo: titulo,
              subtitulo: '$subtitulo  -  ${itens.length}',
            ),
          ),
        ],
      ),
      padding: EdgeInsets.zero,
      child: itens.isEmpty
          ? const EvaEmptyState(
              icone: Icons.autorenew,
              mensagem: 'Nada aqui no momento',
            )
          : Column(
              children: [
                for (var i = 0; i < itens.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: p.border),
                  _ItemRecorrencia(
                    recorrencia: itens[i],
                    mes: mes,
                    onLancar: () => onLancar(itens[i]),
                    onEditar: () => onEditar(itens[i]),
                    onAlternar: () => onAlternar(itens[i]),
                    onExcluir: () => onExcluir(itens[i]),
                  ),
                ],
              ],
            ),
    );
  }
}

class _ItemRecorrencia extends StatelessWidget {
  const _ItemRecorrencia({
    required this.recorrencia,
    required this.mes,
    required this.onLancar,
    required this.onEditar,
    required this.onAlternar,
    required this.onExcluir,
  });

  final Recorrencia recorrencia;
  final DateTime mes;
  final VoidCallback onLancar;
  final VoidCallback onEditar;
  final VoidCallback onAlternar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final r = recorrencia;
    final cor = r.tipo.isReceita ? p.green : p.red;
    final pendente = r.pendenteEm(mes);

    return InkWell(
      onTap: onEditar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Selo com o dia do vencimento.
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: p.border.withValues(alpha: 0.4),
                border: Border.all(color: p.border),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${r.diaVencimento}',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: r.ativa ? p.purpleLight : p.textMuted,
                    ),
                  ),
                  Text(
                    'DIA',
                    style: TextStyle(
                      fontFamily: AppTheme.titleFont,
                      fontSize: 6,
                      letterSpacing: 0.5,
                      color: p.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          r.descricao,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: r.ativa ? p.text : p.textMuted,
                          ),
                        ),
                      ),
                      if (!r.ativa) ...[
                        const SizedBox(width: 8),
                        EvaChip(texto: 'Inativa', cor: p.textMuted),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    r.ultimoLancamento == null
                        ? '${r.categoriaNome ?? 'Sem categoria'}  -  '
                            'nunca lancada'
                        : '${r.categoriaNome ?? 'Sem categoria'}  -  '
                            'ultimo: ${Fmt.data(r.ultimoLancamento!)}',
                    style: TextStyle(fontSize: 10.5, color: p.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                EvaMoney(valor: r.valor, cor: cor, sinal: r.tipo.isReceita),
                if (pendente && r.ativa) ...[
                  const SizedBox(height: 5),
                  SizedBox(
                    height: 26,
                    child: FilledButton(
                      onPressed: onLancar,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: p.yellow.withValues(alpha: 0.18),
                        foregroundColor: p.yellow,
                        textStyle: const TextStyle(
                          fontFamily: AppTheme.titleFont,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('LANCAR'),
                    ),
                  ),
                ],
              ],
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: p.textMuted),
              onSelected: (v) {
                if (v == 'editar') onEditar();
                if (v == 'alternar') onAlternar();
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
                  value: 'alternar',
                  child: Row(
                    children: [
                      Icon(
                        r.ativa ? Icons.pause_circle_outline : Icons.play_circle_outline,
                        size: 16,
                        color: p.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Text(r.ativa ? 'Desativar' : 'Ativar'),
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
