import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/eva_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/categoria_repository.dart';
import '../../data/repositories/regra_negocio.dart';
import '../../main.dart';
import '../shared/form_widgets.dart';
import 'categoria_form_page.dart';

/// Listagem de categorias com uso vs limite -- porta do
/// `categorias/index.php`.
class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  final _repo = const CategoriaRepository();

  List<UsoCategoria> _itens = const [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    if (!mounted) return;
    setState(() => _carregando = true);

    final itens = await _repo.listarComUso(
      usuarioId: context.app.usuarioId,
      mes: DateTime.now(),
    );

    if (!mounted) return;
    setState(() {
      _itens = itens;
      _carregando = false;
    });
  }

  Future<void> _abrirFormulario([Categoria? c]) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CategoriaFormPage(categoria: c)),
    );
    if (salvou == true && mounted) {
      context.app.notificarMudanca();
      avisar(
        context,
        c == null ? 'Categoria criada.' : 'Categoria atualizada.',
      );
      await _carregar();
    }
  }

  Future<void> _excluir(Categoria c) async {
    final ok = await confirmar(
      context,
      titulo: 'Excluir categoria',
      mensagem: 'Remover a categoria "${c.nome}"?',
    );
    if (!ok || !mounted) return;

    try {
      await _repo.excluir(c.id);
      if (!mounted) return;
      context.app.notificarMudanca();
      avisar(context, 'Categoria excluida.');
      await _carregar();
    } on RegraNegocioException catch (e) {
      if (!mounted) return;
      avisar(context, e.erros.first, erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receitas =
        _itens.where((u) => u.categoria.tipo.isReceita).toList();
    final despesas =
        _itens.where((u) => !u.categoria.tipo.isReceita).toList();

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: context.paddingPagina,
        children: [
          EvaPageTitle(
            titulo: 'CATEGORIAS',
            subtitulo: '// classifique e limite seus gastos',
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
            _Secao(
              titulo: 'Despesas',
              subtitulo: 'uso no mes de ${Fmt.mesExtenso(DateTime.now())}',
              itens: despesas,
              onEditar: _abrirFormulario,
              onExcluir: _excluir,
            ),
            const SizedBox(height: 12),
            _Secao(
              titulo: 'Receitas',
              subtitulo: 'entradas recebidas no mes',
              itens: receitas,
              onEditar: _abrirFormulario,
              onExcluir: _excluir,
            ),
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
    required this.itens,
    required this.onEditar,
    required this.onExcluir,
  });

  final String titulo;
  final String subtitulo;
  final List<UsoCategoria> itens;
  final void Function(Categoria) onEditar;
  final void Function(Categoria) onExcluir;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return EvaCard(
      header: EvaCardHeader(
        titulo: titulo,
        subtitulo: '$subtitulo  -  ${itens.length} categoria(s)',
      ),
      padding: EdgeInsets.zero,
      child: itens.isEmpty
          ? const EvaEmptyState(
              icone: Icons.sell_outlined,
              mensagem: 'Nenhuma categoria cadastrada aqui',
            )
          : Column(
              children: [
                for (var i = 0; i < itens.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: p.border),
                  _ItemCategoria(
                    uso: itens[i],
                    onEditar: () => onEditar(itens[i].categoria),
                    onExcluir: () => onExcluir(itens[i].categoria),
                  ),
                ],
              ],
            ),
    );
  }
}

class _ItemCategoria extends StatelessWidget {
  const _ItemCategoria({
    required this.uso,
    required this.onEditar,
    required this.onExcluir,
  });

  final UsoCategoria uso;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final c = uso.categoria;
    final pct = uso.percentual;
    final corTipo = c.tipo.isReceita ? p.green : p.red;

    // Mesma escala do dashboard: vermelho estourou, amarelo em alerta.
    final corBarra = pct == null
        ? p.purpleLight
        : (uso.estourou ? p.red : (uso.emAlerta ? p.yellow : p.purpleLight));

    return InkWell(
      onTap: onEditar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          c.nome,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5, color: p.text),
                        ),
                      ),
                      const SizedBox(width: 8),
                      EvaChip(texto: c.tipo.label, cor: corTipo),
                    ],
                  ),
                ),
                if (pct == null)
                  Text(
                    uso.gasto > 0 ? Fmt.moeda(uso.gasto) : 'sem limite',
                    style: TextStyle(fontSize: 11, color: p.textMuted),
                  )
                else
                  Text(
                    Fmt.pct(pct),
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: corBarra,
                    ),
                  ),
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
                          Icon(Icons.edit_outlined,
                              size: 16, color: p.textMuted),
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
            // Barra de uso aparece so quando existe limite configurado.
            if (pct != null) ...[
              const SizedBox(height: 4),
              EvaProgressBar(percentual: pct, cor: corBarra),
              const SizedBox(height: 5),
              Text(
                '${Fmt.moeda(uso.gasto)} de '
                '${Fmt.moeda(c.limiteMensal!)}  -  '
                '${uso.transacoes} lancamento(s)',
                style: TextStyle(fontSize: 10, color: p.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
