import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/meta_repository.dart';
import '../../main.dart';
import '../shared/form_widgets.dart';

/// Formulario de meta -- porta de `metas/create.php` e `metas/edit.php`.
class MetaFormPage extends StatefulWidget {
  const MetaFormPage({super.key, this.meta});

  final Meta? meta;

  bool get editando => meta != null;

  @override
  State<MetaFormPage> createState() => _MetaFormPageState();
}

class _MetaFormPageState extends State<MetaFormPage> {
  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  final _valorAlvo = TextEditingController();
  final _valorAtual = TextEditingController(text: '0,00');
  final _repo = const MetaRepository();

  DateTime? _prazo;
  List<String> _erros = const [];
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final m = widget.meta;
    if (m != null) {
      _nome.text = m.nome;
      _descricao.text = m.descricao ?? '';
      _valorAlvo.text = Fmt.numero(m.valorAlvo);
      _valorAtual.text = Fmt.numero(m.valorAtual);
      _prazo = m.prazo;
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _valorAlvo.dispose();
    _valorAtual.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erros = const [];
    });

    final usuarioId = context.app.usuarioId;
    final alvo = Fmt.parseValor(_valorAlvo.text);
    final atual = Fmt.parseValor(_valorAtual.text) ?? 0;

    final erros = await executarSalvando(() async {
      if (widget.editando) {
        await _repo.atualizar(
          id: widget.meta!.id,
          usuarioId: usuarioId,
          nome: _nome.text,
          valorAlvo: alvo,
          valorAtual: atual,
          descricao: _descricao.text,
          prazo: _prazo,
        );
      } else {
        await _repo.criar(
          usuarioId: usuarioId,
          nome: _nome.text,
          valorAlvo: alvo,
          valorAtual: atual,
          descricao: _descricao.text,
          prazo: _prazo,
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
      titulo: widget.editando ? 'Editar Meta' : 'Nova Meta',
      subtitulo: widget.editando
          ? 'ajuste o objetivo ou o prazo'
          : 'defina quanto quer acumular',
      erros: _erros,
      salvando: _salvando,
      onSalvar: _salvar,
      campos: [
        EvaField(
          rotulo: 'Nome da meta',
          controller: _nome,
          dica: 'Ex.: Reserva de emergencia, Viagem',
          autofoco: true,
        ),
        EvaField(
          rotulo: 'Descricao (opcional)',
          controller: _descricao,
          dica: 'Detalhe o objetivo',
          maxLines: 2,
        ),
        EvaField(
          rotulo: 'Valor alvo',
          controller: _valorAlvo,
          dica: '0,00',
          prefixo: r'R$ ',
          teclado: const TextInputType.numberWithOptions(decimal: true),
          formatadores: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
        ),
        EvaField(
          rotulo: 'Valor ja acumulado',
          controller: _valorAtual,
          dica: '0,00',
          prefixo: r'R$ ',
          teclado: const TextInputType.numberWithOptions(decimal: true),
          formatadores: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          ajuda: 'Nao pode ser maior que o valor alvo.',
        ),
        DataField(
          rotulo: 'Prazo (opcional)',
          valor: _prazo,
          permiteVazio: true,
          onChanged: (d) => setState(() => _prazo = d),
        ),
      ],
    );
  }
}
