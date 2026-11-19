import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/categoria_repository.dart';
import '../../data/repositories/transacao_repository.dart';
import '../../main.dart';
import '../shared/form_widgets.dart';

/// Formulario de transacao -- porta de `transacoes/create.php` e
/// `transacoes/edit.php` numa unica tela (o modo e dado por [transacao]).
class TransacaoFormPage extends StatefulWidget {
  const TransacaoFormPage({super.key, this.transacao});

  /// Null = criar; preenchida = editar.
  final Transacao? transacao;

  bool get editando => transacao != null;

  @override
  State<TransacaoFormPage> createState() => _TransacaoFormPageState();
}

class _TransacaoFormPageState extends State<TransacaoFormPage> {
  final _descricao = TextEditingController();
  final _valor = TextEditingController();
  final _repo = const TransacaoRepository();
  final _categoriasRepo = const CategoriaRepository();

  TipoMovimento _tipo = TipoMovimento.despesa;
  DateTime _data = DateTime.now();
  int? _categoriaId;

  List<Categoria> _categorias = const [];
  List<String> _erros = const [];
  bool _salvando = false;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();

    final t = widget.transacao;
    if (t != null) {
      _descricao.text = t.descricao;
      _valor.text = Fmt.numero(t.valor);
      _tipo = t.tipo;
      _data = t.data;
      _categoriaId = t.categoriaId;
    }

    _carregarCategorias();
  }

  Future<void> _carregarCategorias() async {
    final lista = await _categoriasRepo.listar();
    if (!mounted) return;
    setState(() {
      _categorias = lista;
      _carregando = false;
    });
  }

  @override
  void dispose() {
    _descricao.dispose();
    _valor.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erros = const [];
    });

    final usuarioId = context.app.usuarioId;
    final valor = Fmt.parseValor(_valor.text);

    final erros = await executarSalvando(() async {
      if (widget.editando) {
        await _repo.atualizar(
          id: widget.transacao!.id,
          usuarioId: usuarioId,
          descricao: _descricao.text,
          valor: valor,
          tipo: _tipo,
          data: _data,
          categoriaId: _categoriaId,
        );
      } else {
        await _repo.criar(
          usuarioId: usuarioId,
          descricao: _descricao.text,
          valor: valor,
          tipo: _tipo,
          data: _data,
          categoriaId: _categoriaId,
        );
      }
    });

    if (!mounted) return;

    if (erros.isEmpty) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _erros = erros;
      _salvando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FormScaffold(
      titulo: widget.editando ? 'Editar Transacao' : 'Nova Transacao',
      subtitulo: widget.editando
          ? 'altere os dados do lancamento'
          : 'registre uma entrada ou saida',
      erros: _erros,
      salvando: _salvando,
      onSalvar: _salvar,
      rotuloSalvar: widget.editando ? 'Salvar' : 'Registrar',
      campos: [
        TipoSelector(
          valor: _tipo,
          onChanged: (t) => setState(() {
            _tipo = t;
            // Ao trocar o tipo a categoria pode nao servir mais.
            if (!_categorias.any((c) => c.id == _categoriaId && c.tipo == t)) {
              _categoriaId = null;
            }
          }),
        ),
        EvaField(
          rotulo: 'Descricao',
          controller: _descricao,
          dica: 'Ex.: Supermercado, Salario, Conta de luz',
          autofoco: true,
        ),
        EvaField(
          rotulo: 'Valor',
          controller: _valor,
          dica: '0,00',
          prefixo: r'R$ ',
          teclado: const TextInputType.numberWithOptions(decimal: true),
          formatadores: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          ajuda: 'Use virgula para os centavos. Ex.: 1.250,90',
        ),
        CategoriaDropdown(
          categorias: _categorias,
          tipo: _tipo,
          valor: _categoriaId,
          onChanged: (v) => setState(() => _categoriaId = v),
        ),
        DataField(
          rotulo: 'Data',
          valor: _data,
          onChanged: (d) => setState(() => _data = d ?? _data),
        ),
      ],
    );
  }
}
