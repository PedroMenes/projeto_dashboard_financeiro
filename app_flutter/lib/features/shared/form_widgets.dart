import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/eva_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/regra_negocio.dart';

/// Campo de texto padrao do sistema, com rotulo em Orbitron acima.
class EvaField extends StatelessWidget {
  const EvaField({
    super.key,
    required this.rotulo,
    required this.controller,
    this.dica,
    this.ajuda,
    this.teclado,
    this.obscuro = false,
    this.maxLines = 1,
    this.formatadores,
    this.prefixo,
    this.autofoco = false,
    this.habilitado = true,
    this.onSubmit,
  });

  final String rotulo;
  final TextEditingController controller;
  final String? dica;
  final String? ajuda;
  final TextInputType? teclado;
  final bool obscuro;
  final int maxLines;
  final List<TextInputFormatter>? formatadores;
  final String? prefixo;
  final bool autofoco;
  final bool habilitado;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTheme.titleFont,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: p.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscuro,
          keyboardType: teclado,
          maxLines: obscuro ? 1 : maxLines,
          inputFormatters: formatadores,
          autofocus: autofoco,
          enabled: habilitado,
          onSubmitted: onSubmit == null ? null : (_) => onSubmit!(),
          style: TextStyle(
            fontFamily: AppTheme.monoFont,
            fontSize: 14,
            color: p.textBright,
          ),
          decoration: InputDecoration(
            hintText: dica,
            prefixText: prefixo,
            prefixStyle: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 14,
              color: p.textMuted,
            ),
          ),
        ),
        if (ajuda != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              ajuda!,
              style: TextStyle(fontSize: 10.5, color: p.textMuted),
            ),
          ),
      ],
    );
  }
}

/// Seletor Receita / Despesa em dois botoes, como os radios da versao web.
class TipoSelector extends StatelessWidget {
  const TipoSelector({
    super.key,
    required this.valor,
    required this.onChanged,
    this.rotulo = 'Tipo',
  });

  final TipoMovimento valor;
  final ValueChanged<TipoMovimento> onChanged;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTheme.titleFont,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: p.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final t in TipoMovimento.values) ...[
              if (t != TipoMovimento.values.first) const SizedBox(width: 8),
              Expanded(
                child: _TipoBotao(
                  tipo: t,
                  selecionado: valor == t,
                  onTap: () => onChanged(t),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TipoBotao extends StatelessWidget {
  const _TipoBotao({
    required this.tipo,
    required this.selecionado,
    required this.onTap,
  });

  final TipoMovimento tipo;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final cor = tipo.isReceita ? p.green : p.red;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selecionado ? cor.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: selecionado ? cor.withValues(alpha: 0.6) : p.border,
            width: selecionado ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tipo.isReceita ? Icons.south_west : Icons.north_east,
              size: 15,
              color: selecionado ? cor : p.textMuted,
            ),
            const SizedBox(width: 7),
            Text(
              tipo.label.toUpperCase(),
              style: TextStyle(
                fontFamily: AppTheme.titleFont,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: selecionado ? cor : p.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de categorias filtrada pelo tipo escolhido, como o JS da
/// versao web fazia ao trocar entre receita e despesa.
class CategoriaDropdown extends StatelessWidget {
  const CategoriaDropdown({
    super.key,
    required this.categorias,
    required this.tipo,
    required this.valor,
    required this.onChanged,
  });

  final List<Categoria> categorias;
  final TipoMovimento tipo;
  final int? valor;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final disponiveis = categorias.where((c) => c.tipo == tipo).toList();
    // Se a categoria selecionada nao pertence ao tipo atual, cai em "nenhuma".
    final selecionado =
        disponiveis.any((c) => c.id == valor) ? valor : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORIA',
          style: TextStyle(
            fontFamily: AppTheme.titleFont,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: p.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        // DropdownButton (e nao DropdownButtonFormField) de proposito:
        // o FormField guarda o valor num estado interno proprio, que nao
        // acompanha a troca de tipo feita pelo formulario. Aqui o valor
        // vem sempre de quem usa o widget, entao trocar de receita para
        // despesa reconstroi a lista e a selecao sem inconsistencia.
        InputDecorator(
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: selecionado,
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
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    'Sem categoria',
                    style: TextStyle(color: p.textMuted, fontSize: 13.5),
                  ),
                ),
                for (final c in disponiveis)
                  DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.nome, style: TextStyle(color: p.textBright)),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Campo de data que abre o calendario nativo da plataforma.
class DataField extends StatelessWidget {
  const DataField({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.onChanged,
    this.permiteVazio = false,
    this.primeiroDia,
    this.ultimoDia,
  });

  final String rotulo;
  final DateTime? valor;
  final ValueChanged<DateTime?> onChanged;
  final bool permiteVazio;
  final DateTime? primeiroDia;
  final DateTime? ultimoDia;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTheme.titleFont,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: p.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final escolhida = await showDatePicker(
              context: context,
              initialDate: valor ?? DateTime.now(),
              firstDate: primeiroDia ?? DateTime(2000),
              lastDate: ultimoDia ?? DateTime(2100),
              locale: const Locale('pt', 'BR'),
            );
            if (escolhida != null) onChanged(escolhida);
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: p.isDark ? p.bg : p.bgCardHover,
              border: Border.all(color: p.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: p.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    valor == null ? 'Nao definido' : Fmt.data(valor!),
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 14,
                      color: valor == null ? p.textMuted : p.textBright,
                    ),
                  ),
                ),
                if (permiteVazio && valor != null)
                  InkWell(
                    onTap: () => onChanged(null),
                    child: Icon(Icons.close, size: 16, color: p.textMuted),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Caixa vermelha com a lista de erros de validacao,
/// equivalente ao `alert alert-danger` das paginas PHP.
class ErroBox extends StatelessWidget {
  const ErroBox({super.key, required this.erros});

  final List<String> erros;

  @override
  Widget build(BuildContext context) {
    if (erros.isEmpty) return const SizedBox.shrink();
    final p = context.eva;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.red.withValues(alpha: 0.08),
        border: Border.all(color: p.red.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: p.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in erros)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(
                      e,
                      style: TextStyle(fontSize: 12.5, color: p.red),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Casca das telas de formulario: titulo, voltar, card centralizado
/// e barra de acoes no rodape.
class FormScaffold extends StatelessWidget {
  const FormScaffold({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.campos,
    required this.onSalvar,
    required this.erros,
    required this.salvando,
    this.rotuloSalvar = 'Salvar',
    this.iconeSalvar = Icons.check,
    this.extra,
  });

  final String titulo;
  final String subtitulo;
  final List<Widget> campos;
  final VoidCallback onSalvar;
  final List<String> erros;
  final bool salvando;
  final String rotuloSalvar;
  final IconData iconeSalvar;

  /// Conteudo opcional acima do formulario (ex.: resumo da meta).
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo.toUpperCase())),
      body: EvaGridBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: context.paddingPagina,
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: context.larguraFormulario),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EvaPageTitle(titulo: titulo, subtitulo: '// $subtitulo'),
                  const SizedBox(height: 18),
                  if (extra != null) ...[extra!, const SizedBox(height: 16)],
                  ErroBox(erros: erros),
                  EvaCard(
                    statusBar: true,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < campos.length; i++) ...[
                          if (i > 0) const SizedBox(height: 18),
                          campos[i],
                        ],
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: salvando ? null : onSalvar,
                                icon: salvando
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(iconeSalvar, size: 16),
                                label: Text(rotuloSalvar.toUpperCase()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: salvando
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                              child: const Text('CANCELAR'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Executa uma operacao de gravacao tratando [RegraNegocioException].
///
/// Devolve a lista de erros (vazia em caso de sucesso), para a tela
/// exibir no [ErroBox] -- o mesmo fluxo do `$erros` do PHP.
Future<List<String>> executarSalvando(Future<void> Function() acao) async {
  try {
    await acao();
    return const [];
  } on RegraNegocioException catch (e) {
    return e.erros;
  } catch (e) {
    return ['Nao foi possivel concluir a operacao: $e'];
  }
}

/// Dialogo de confirmacao usado antes de excluir registros.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String rotuloConfirmar = 'Excluir',
  bool destrutivo = true,
}) async {
  final p = context.eva;
  final resposta = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo.toUpperCase()),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destrutivo
              ? FilledButton.styleFrom(backgroundColor: p.red)
              : null,
          child: Text(rotuloConfirmar.toUpperCase()),
        ),
      ],
    ),
  );
  return resposta ?? false;
}

/// Mostra um aviso curto no rodape da tela.
void avisar(BuildContext context, String mensagem, {bool erro = false}) {
  final p = context.eva;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            erro ? Icons.error_outline : Icons.check_circle_outline,
            size: 17,
            color: erro ? p.red : p.green,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(mensagem)),
        ],
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
