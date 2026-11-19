import 'package:flutter/material.dart';

/// Faixas de largura de tela, equivalentes aos breakpoints do Bootstrap
/// usados na versao web (sm / md / lg / xl).
enum FormFactor { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  FormFactor get formFactor {
    final w = screenWidth;
    if (w < 700) return FormFactor.mobile;
    if (w < 1100) return FormFactor.tablet;
    return FormFactor.desktop;
  }

  bool get isMobile => formFactor == FormFactor.mobile;
  bool get isTablet => formFactor == FormFactor.tablet;
  bool get isDesktop => formFactor == FormFactor.desktop;

  /// No desktop a navegacao fica numa barra lateral fixa; no mobile,
  /// numa barra inferior. O tablet segue o desktop.
  bool get usaBarraLateral => !isMobile;

  /// Quantas colunas os cards de resumo ocupam na grade.
  int get colunasResumo => switch (formFactor) {
        FormFactor.mobile => 1,
        FormFactor.tablet => 2,
        FormFactor.desktop => 3,
      };

  /// Espacamento horizontal das paginas (px-4 do Bootstrap vs. mobile).
  EdgeInsets get paddingPagina => EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 16 : 20,
      );

  /// Largura maxima para formularios -- evita campos gigantes no desktop.
  double get larguraFormulario => isMobile ? double.infinity : 560;
}

/// Grade simples que distribui filhos em N colunas com espacamento igual,
/// no lugar do sistema de `row g-3 col-*` do Bootstrap.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    required this.columns,
    this.spacing = 12,
  });

  final List<Widget> children;
  final int columns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.skip(i).take(columns).toList();
      rows.add(
        // IntrinsicHeight da a linha uma altura concreta (a do filho mais
        // alto). Sem isso, o `stretch` dentro de uma lista rolavel pediria
        // altura infinita e a tela quebraria.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) SizedBox(width: spacing),
                Expanded(
                  child: j < slice.length ? slice[j] : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
      if (i + columns < children.length) rows.add(SizedBox(height: spacing));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}
