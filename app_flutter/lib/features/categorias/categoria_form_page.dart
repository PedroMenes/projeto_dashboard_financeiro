import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/categoria_repository.dart';
import '../shared/form_widgets.dart';

/// Formulario de categoria -- porta de `categorias/create.php` e
/// `categorias/edit.php`, incluindo a configuracao de limite mensal.
class CategoriaFormPage extends StatefulWidget {
  const CategoriaFormPage({super.key, this.categoria});

  final Categoria? categoria;

  bool get editando => categoria != null;

  @override
  State<CategoriaFormPage> createState() => _CategoriaFormPageState();
}

class _CategoriaFormPageState extends State<CategoriaFormPage> {
  final _nome = TextEditingController();
  final _limite = TextEditingController();
  final _repo = const CategoriaRepository();

  TipoMovimento _tipo = TipoMovimento.despesa;
  bool _usarLimite = false;
  List<String> _erros = const [];
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final c = widget.categoria;
    if (c != null) {
      _nome.text = c.nome;
      _tipo = c.tipo;
      _usarLimite = c.limiteMensal != null;
      if (c.limiteMensal != null) _limite.text = Fmt.numero(c.limiteMensal!);
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _limite.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erros = const [];
    });

    // O limite so vale para despesas, como na versao web.
    final limite = (_tipo.isReceita || !_usarLimite)
        ? null
        : Fmt.parseValor(_limite.text);

    final erros = await executarSalvando(() async {
      if (widget.editando) {
        await _repo.atualizar(
          id: widget.categoria!.id,
          nome: _nome.text,
          tipo: _tipo,
          limiteMensal: limite,
        );
      } else {
        await _repo.criar(
          nome: _nome.text,
          tipo: _tipo,
          limiteMensal: limite,
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
    return FormScaffold(
      titulo: widget.editando ? 'Editar Categoria' : 'Nova Categoria',
      subtitulo: widget.editando
          ? 'altere o nome, o tipo ou o limite'
          : 'classifique suas entradas e saidas',
      erros: _erros,
      salvando: _salvando,
      onSalvar: _salvar,
      campos: [
        TipoSelector(
          valor: _tipo,
          onChanged: (t) => setState(() {
            _tipo = t;
            if (t.isReceita) _usarLimite = false;
          }),
        ),
        EvaField(
          rotulo: 'Nome',
          controller: _nome,
          dica: 'Ex.: Alimentacao, Salario, Transporte',
          autofoco: true,
          ajuda: 'Minimo de 2 caracteres.',
        ),
        // Limite mensal: so faz sentido em categorias de despesa.
        if (!_tipo.isReceita) _BlocoLimite(
          ativo: _usarLimite,
          controller: _limite,
          onAlternar: (v) => setState(() => _usarLimite = v),
        ),
      ],
    );
  }
}

class _BlocoLimite extends StatelessWidget {
  const _BlocoLimite({
    required this.ativo,
    required this.controller,
    required this.onAlternar,
  });

  final bool ativo;
  final TextEditingController controller;
  final ValueChanged<bool> onAlternar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          value: ativo,
          onChanged: onAlternar,
          contentPadding: EdgeInsets.zero,
          title: const Text('Definir limite mensal'),
          subtitle: const Text(
            'O painel avisa quando o gasto do mes passa de 80% do limite.',
          ),
        ),
        if (ativo) ...[
          const SizedBox(height: 12),
          EvaField(
            rotulo: 'Limite mensal',
            controller: controller,
            dica: '0,00',
            prefixo: r'R$ ',
            teclado: const TextInputType.numberWithOptions(decimal: true),
            formatadores: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
        ],
      ],
    );
  }
}
