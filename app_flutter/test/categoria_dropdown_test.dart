import 'package:financeiro_app/core/theme/app_theme.dart';
import 'package:financeiro_app/core/theme/eva_palette.dart';
import 'package:financeiro_app/core/widgets/eva_widgets.dart';
import 'package:financeiro_app/data/models/models.dart';
import 'package:financeiro_app/features/shared/form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regressao: ao trocar entre Receita e Despesa, a lista de categorias
/// precisa trocar junto e a selecao anterior precisa ser descartada.
///
/// A primeira versao usava DropdownButtonFormField, que guarda o valor
/// num estado interno proprio -- ele continuava apontando para a
/// categoria do tipo antigo e o campo quebrava.
void main() {
  const categorias = <Categoria>[
    Categoria(id: 1, nome: 'Salario', tipo: TipoMovimento.receita),
    Categoria(id: 2, nome: 'Freelance', tipo: TipoMovimento.receita),
    Categoria(
      id: 3,
      nome: 'Alimentacao',
      tipo: TipoMovimento.despesa,
      limiteMensal: 800,
    ),
    Categoria(id: 4, nome: 'Moradia', tipo: TipoMovimento.despesa),
  ];

  /// Monta um formulario minimo com o seletor de tipo e o de categoria,
  /// ligados como estao na tela de transacao.
  Widget harness() => MaterialApp(
        theme: AppTheme.build(EvaPalette.eva),
        home: PaletteScope(
          palette: EvaPalette.eva,
          child: Scaffold(
            body: _Harness(categorias: categorias),
          ),
        ),
      );

  testWidgets('lista so as categorias do tipo selecionado', (tester) async {
    await tester.pumpWidget(harness());

    // Comeca em Despesa.
    await tester.tap(find.byType(DropdownButton<int?>));
    await tester.pumpAndSettle();

    expect(find.text('Alimentacao'), findsWidgets);
    expect(find.text('Moradia'), findsWidgets);
    expect(find.text('Salario'), findsNothing);

    await tester.tapAt(const Offset(10, 10)); // fecha o menu
    await tester.pumpAndSettle();
  });

  testWidgets('trocar para Receita troca a lista de categorias',
      (tester) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.text('RECEITA'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<int?>));
    await tester.pumpAndSettle();

    expect(find.text('Salario'), findsWidgets);
    expect(find.text('Freelance'), findsWidgets);
    expect(find.text('Alimentacao'), findsNothing);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  });

  testWidgets('selecionar uma categoria e depois trocar o tipo limpa a escolha',
      (tester) async {
    await tester.pumpWidget(harness());

    // Escolhe Alimentacao (despesa).
    await tester.tap(find.byType(DropdownButton<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alimentacao').last);
    await tester.pumpAndSettle();

    final estado = tester.state<_HarnessState>(find.byType(_Harness));
    expect(estado.categoriaId, 3);

    // Troca para Receita: a categoria de despesa nao serve mais.
    await tester.tap(find.text('RECEITA'));
    await tester.pumpAndSettle();
    expect(estado.categoriaId, isNull);

    // E o campo volta a exibir "Sem categoria", sem quebrar a tela.
    expect(find.text('Sem categoria'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// Replica a ligacao entre TipoSelector e CategoriaDropdown que existe
/// nas telas de transacao e de recorrencia.
class _Harness extends StatefulWidget {
  const _Harness({required this.categorias});

  final List<Categoria> categorias;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  TipoMovimento tipo = TipoMovimento.despesa;
  int? categoriaId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TipoSelector(
            valor: tipo,
            onChanged: (t) => setState(() {
              tipo = t;
              if (!widget.categorias
                  .any((c) => c.id == categoriaId && c.tipo == t)) {
                categoriaId = null;
              }
            }),
          ),
          const SizedBox(height: 16),
          CategoriaDropdown(
            categorias: widget.categorias,
            tipo: tipo,
            valor: categoriaId,
            onChanged: (v) => setState(() => categoriaId = v),
          ),
        ],
      ),
    );
  }
}
