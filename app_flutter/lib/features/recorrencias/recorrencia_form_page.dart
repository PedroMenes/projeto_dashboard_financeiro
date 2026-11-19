import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/eva_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/categoria_repository.dart';
import '../../data/repositories/recorrencia_repository.dart';
import '../../main.dart';
import '../shared/form_widgets.dart';

/// Formulario de recorrencia -- porta de `recorrencias/create.php`
/// e `recorrencias/edit.php`.
class RecorrenciaFormPage extends StatefulWidget {
  const RecorrenciaFormPage({super.key, this.recorrencia});

  final Recorrencia? recorrencia;

  bool get editando => recorrencia != null;

  @override
  State<RecorrenciaFormPage> createState() => _RecorrenciaFormPageState();
}

class _RecorrenciaFormPageState extends State<RecorrenciaFormPage> {
  final _descricao = TextEditingController();
  final _valor = TextEditingController();
  final _repo = const RecorrenciaRepository();
  final _categoriasRepo = const CategoriaRepository();

  TipoMovimento _tipo = TipoMovimento.despesa;
  int _dia = 5;
  int? _categoriaId;
  bool _ativa = true;

  List<Categoria> _categorias = const [];
  List<String> _erros = const [];
  bool _salvando = false;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    final r = widget.recorrencia;
    if (r != null) {
      _descricao.text = r.descricao;
      _valor.text = Fmt.numero(r.valor);
      _tipo = r.tipo;
      _dia = r.diaVencimento;
      _categoriaId = r.categoriaId;
      _ativa = r.ativa;
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
          id: widget.recorrencia!.id,
          usuarioId: usuarioId,
          descricao: _descricao.text,
          valor: valor,
          tipo: _tipo,
          diaVencimento: _dia,
          categoriaId: _categoriaId,
          ativa: _ativa,
        );
      } else {
        await _repo.criar(
          usuarioId: usuarioId,
          descricao: _descricao.text,
          valor: valor,
          tipo: _tipo,
          diaVencimento: _dia,
          categoriaId: _categoriaId,
          ativa: _ativa,
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FormScaffold(
      titulo: widget.editando ? 'Editar Recorrencia' : 'Nova Recorrencia',
      subtitulo: widget.editando
          ? 'ajuste o valor ou o vencimento'
          : 'contas que repetem todo mes',
      erros: _erros,
      salvando: _salvando,
      onSalvar: _salvar,
      campos: [
        TipoSelector(
          valor: _tipo,
          onChanged: (t) => setState(() {
            _tipo = t;
            if (!_categorias.any((c) => c.id == _categoriaId && c.tipo == t)) {
              _categoriaId = null;
            }
          }),
        ),
        EvaField(
          rotulo: 'Descricao',
          controller: _descricao,
          dica: 'Ex.: Aluguel, Internet, Salario',
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
        ),
        CategoriaDropdown(
          categorias: _categorias,
          tipo: _tipo,
          valor: _categoriaId,
          onChanged: (v) => setState(() => _categoriaId = v),
        ),
        _SeletorDia(
          valor: _dia,
          onChanged: (d) => setState(() => _dia = d),
        ),
        SwitchListTile(
          value: _ativa,
          onChanged: (v) => setState(() => _ativa = v),
          contentPadding: EdgeInsets.zero,
          title: const Text('Recorrencia ativa'),
          subtitle: const Text(
            'Quando desligada, deixa de aparecer como pendente no painel.',
          ),
        ),
      ],
    );
  }
}

/// Dia do mes em que a conta vence (1 a 31).
class _SeletorDia extends StatelessWidget {
  const _SeletorDia({required this.valor, required this.onChanged});

  final int valor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DIA DO VENCIMENTO',
          style: TextStyle(
            fontFamily: AppTheme.titleFont,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: p.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        InputDecorator(
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: valor,
              isExpanded: true,
              isDense: true,
              dropdownColor: p.bgCard,
              borderRadius: BorderRadius.circular(4),
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 14,
                color: p.textBright,
              ),
              icon: Icon(Icons.expand_more, color: p.textMuted, size: 20),
              items: [
                for (var d = 1; d <= 31; d++)
                  DropdownMenuItem(value: d, child: Text('Dia $d')),
              ],
              onChanged: (v) => onChanged(v ?? valor),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            'Em meses mais curtos o lancamento cai no ultimo dia '
            'disponivel (ex.: dia 31 vira 28 em fevereiro).',
            style: TextStyle(fontSize: 10.5, color: p.textMuted),
          ),
        ),
      ],
    );
  }
}
