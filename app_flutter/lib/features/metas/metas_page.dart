import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/eva_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/meta_repository.dart';
import '../../main.dart';
import '../shared/form_widgets.dart';
import 'meta_form_page.dart';

/// Cards de metas com progresso -- porta do `metas/index.php`,
/// incluindo o deposito do `metas/depositar.php`.
class MetasPage extends StatefulWidget {
  const MetasPage({super.key});

  @override
  State<MetasPage> createState() => _MetasPageState();
}

class _MetasPageState extends State<MetasPage> {
  final _repo = const MetaRepository();

  List<Meta> _itens = const [];
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

  Future<void> _abrirFormulario([Meta? m]) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MetaFormPage(meta: m)),
    );
    if (salvou == true && mounted) {
      context.app.notificarMudanca();
      avisar(context, m == null ? 'Meta criada.' : 'Meta atualizada.');
      await _carregar();
    }
  }

  Future<void> _excluir(Meta m) async {
    final ok = await confirmar(
      context,
      titulo: 'Excluir meta',
      mensagem: 'Remover a meta "${m.nome}"? '
          'O valor acumulado registrado aqui sera perdido.',
    );
    if (!ok || !mounted) return;

    await _repo.excluir(id: m.id, usuarioId: context.app.usuarioId);
    if (!mounted) return;
    context.app.notificarMudanca();
    avisar(context, 'Meta excluida.');
    await _carregar();
  }

  /// Abre a folha de deposito ou de retirada.
  Future<void> _movimentar(Meta m, {required bool depositar}) async {
    final valor = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FolhaMovimento(meta: m, depositar: depositar),
    );
    if (valor == null || !mounted) return;

    final usuarioId = context.app.usuarioId;
    final erros = await executarSalvando(() async {
      if (depositar) {
        await _repo.depositar(id: m.id, usuarioId: usuarioId, valor: valor);
      } else {
        await _repo.retirar(id: m.id, usuarioId: usuarioId, valor: valor);
      }
    });

    if (!mounted) return;

    if (erros.isNotEmpty) {
      avisar(context, erros.first, erro: true);
      return;
    }
    context.app.notificarMudanca();
    avisar(
      context,
      depositar
          ? 'Deposito de ${Fmt.moeda(valor)} registrado.'
          : 'Retirada de ${Fmt.moeda(valor)} registrada.',
    );
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: context.paddingPagina,
        children: [
          EvaPageTitle(
            titulo: 'METAS FINANCEIRAS',
            subtitulo: '// acompanhe seus objetivos',
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
          else if (_itens.isEmpty)
            EvaCard(
              child: EvaEmptyState(
                icone: Icons.flag_outlined,
                mensagem: 'Nenhuma meta cadastrada.\n'
                    'Defina um objetivo e acompanhe o progresso.',
                acao: FilledButton.icon(
                  onPressed: () => _abrirFormulario(),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('CRIAR PRIMEIRA META'),
                ),
              ),
            )
          else
            ResponsiveGrid(
              columns: context.isMobile ? 1 : (context.isTablet ? 2 : 3),
              children: [
                for (final m in _itens)
                  _CardMeta(
                    meta: m,
                    onEditar: () => _abrirFormulario(m),
                    onExcluir: () => _excluir(m),
                    onDepositar: () => _movimentar(m, depositar: true),
                    onRetirar: () => _movimentar(m, depositar: false),
                  ),
              ],
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _CardMeta extends StatelessWidget {
  const _CardMeta({
    required this.meta,
    required this.onEditar,
    required this.onExcluir,
    required this.onDepositar,
    required this.onRetirar,
  });

  final Meta meta;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final VoidCallback onDepositar;
  final VoidCallback onRetirar;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final pct = meta.percentual;
    final cor = pct >= 100
        ? p.green
        : (pct >= 60 ? p.yellow : p.purpleLight);

    return EvaCard(
      statusBar: meta.concluida,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.nome,
                      style: TextStyle(
                        fontFamily: AppTheme.titleFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: p.purpleLight,
                      ),
                    ),
                    if ((meta.descricao ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta.descricao!,
                        style: TextStyle(fontSize: 11, color: p.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: p.textMuted),
                onSelected: (v) {
                  if (v == 'editar') onEditar();
                  if (v == 'excluir') onExcluir();
                  if (v == 'retirar') onRetirar();
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
                  if (meta.valorAtual > 0)
                    PopupMenuItem(
                      value: 'retirar',
                      child: Row(
                        children: [
                          Icon(Icons.undo, size: 16, color: p.yellow),
                          const SizedBox(width: 10),
                          const Text('Retirar valor'),
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
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EvaMoney(valor: meta.valorAtual, cor: cor, fontSize: 16),
              Text(
                Fmt.pct(pct),
                style: TextStyle(
                  fontFamily: AppTheme.titleFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          EvaProgressBar(percentual: pct, cor: cor, altura: 7),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Meta: ${Fmt.moeda(meta.valorAlvo)}',
                  style: TextStyle(fontSize: 10.5, color: p.textMuted),
                ),
              ),
              if (meta.prazo != null)
                Text(
                  'Prazo: ${Fmt.data(meta.prazo!)}',
                  style: TextStyle(fontSize: 10.5, color: p.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (meta.concluida)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: p.green.withValues(alpha: 0.1),
                border: Border.all(color: p.green.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 15, color: p.green),
                  const SizedBox(width: 8),
                  Text(
                    'META CONCLUIDA',
                    style: TextStyle(
                      fontFamily: AppTheme.titleFont,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: p.green,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Faltam ${Fmt.moeda(meta.falta)}',
                  style: TextStyle(fontSize: 11, color: p.green),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: onDepositar,
                  icon: const Icon(Icons.savings_outlined, size: 15),
                  label: const Text('DEPOSITAR'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Folha inferior para informar o valor do deposito ou da retirada.
class _FolhaMovimento extends StatefulWidget {
  const _FolhaMovimento({required this.meta, required this.depositar});

  final Meta meta;
  final bool depositar;

  @override
  State<_FolhaMovimento> createState() => _FolhaMovimentoState();
}

class _FolhaMovimentoState extends State<_FolhaMovimento> {
  final _valor = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  double get _maximo =>
      widget.depositar ? widget.meta.falta : widget.meta.valorAtual;

  void _confirmar() {
    final v = Fmt.parseValor(_valor.text);
    if (v == null || v <= 0) {
      setState(() => _erro = 'Informe um valor valido maior que zero.');
      return;
    }
    if (v > _maximo) {
      setState(() => _erro = 'O maximo permitido e ${Fmt.moeda(_maximo)}.');
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final m = widget.meta;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: p.bgCard,
          border: Border(top: BorderSide(color: p.border)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.depositar ? 'DEPOSITAR NA META' : 'RETIRAR DA META',
              style: TextStyle(
                fontFamily: AppTheme.titleFont,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: p.textBright,
              ),
            ),
            const SizedBox(height: 4),
            Text(m.nome, style: TextStyle(fontSize: 12, color: p.purpleLight)),
            const SizedBox(height: 16),
            EvaProgressBar(
              percentual: m.percentual,
              cor: p.purpleLight,
              altura: 7,
            ),
            const SizedBox(height: 8),
            Text(
              '${Fmt.moeda(m.valorAtual)} de ${Fmt.moeda(m.valorAlvo)}',
              style: TextStyle(fontSize: 11, color: p.textMuted),
            ),
            const SizedBox(height: 20),
            if (_erro != null) ErroBox(erros: [_erro!]),
            EvaField(
              rotulo: 'Valor',
              controller: _valor,
              dica: '0,00',
              prefixo: r'R$ ',
              autofoco: true,
              teclado: const TextInputType.numberWithOptions(decimal: true),
              formatadores: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              ajuda: 'Maximo: ${Fmt.moeda(_maximo)}',
              onSubmit: _confirmar,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _confirmar,
                    icon: Icon(
                      widget.depositar ? Icons.savings_outlined : Icons.undo,
                      size: 15,
                    ),
                    label: Text(
                      widget.depositar ? 'CONFIRMAR' : 'RETIRAR',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCELAR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
