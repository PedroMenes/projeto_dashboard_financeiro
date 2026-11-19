import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/eva_palette.dart';
import '../utils/formatters.dart';

/// Disponibiliza a [EvaPalette] ativa para toda a arvore de widgets,
/// no lugar das variaveis CSS que o navegador resolvia sozinho.
class PaletteScope extends InheritedWidget {
  const PaletteScope({super.key, required this.palette, required super.child});

  final EvaPalette palette;

  static EvaPalette of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PaletteScope>();
    return scope?.palette ?? EvaPalette.eva;
  }

  @override
  bool updateShouldNotify(PaletteScope oldWidget) =>
      oldWidget.palette.id != palette.id;
}

extension PaletteContext on BuildContext {
  EvaPalette get eva => PaletteScope.of(this);
}

/// Malha de pontos roxos do fundo do tema EVA
/// (o radial-gradient de 28x28px do CSS).
class EvaGridBackground extends StatelessWidget {
  const EvaGridBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    if (!p.gridBackground) return child;
    return CustomPaint(
      painter: _DotGridPainter(color: p.border),
      child: child,
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({required this.color});

  final Color color;
  static const double _step = 28;
  static const double _radius = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = _step / 2; y < size.height; y += _step) {
      for (var x = _step / 2; x < size.width; x += _step) {
        canvas.drawCircle(Offset(x, y), _radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}

/// Barra de status animada do topo dos cards (.eva-status-bar).
/// No tema EVA o gradiente roxo/verde desliza continuamente.
class EvaStatusBar extends StatefulWidget {
  const EvaStatusBar({super.key, this.height = 3});

  final double height;

  @override
  State<EvaStatusBar> createState() => _EvaStatusBarState();
}

class _EvaStatusBarState extends State<EvaStatusBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.eva;

    if (!p.glow) {
      return Container(height: widget.height, color: p.purple);
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final shift = _ctrl.value * 2 - 1;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + shift, 0),
              end: Alignment(1 + shift, 0),
              colors: [p.purple, p.green, p.purple],
            ),
          ),
        );
      },
    );
  }
}

/// Card padrao do sistema, com borda e barra de status opcional.
class EvaCard extends StatelessWidget {
  const EvaCard({
    super.key,
    required this.child,
    this.statusBar = false,
    this.padding = const EdgeInsets.all(16),
    this.header,
  });

  final Widget child;
  final bool statusBar;
  final EdgeInsets padding;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Container(
      decoration: BoxDecoration(
        color: p.bgCard,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(6),
        boxShadow: p.glow
            ? [
                BoxShadow(
                  color: p.purple.withValues(alpha: 0.08),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusBar) const EvaStatusBar(),
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: header,
            ),
            Divider(height: 1, color: p.border),
          ],
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Cabecalho de card: titulo em Orbitron + subtitulo apagado,
/// equivalente ao par .page-title / .page-subtitle da web.
class EvaCardHeader extends StatelessWidget {
  const EvaCardHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acao,
  });

  final String titulo;
  final String? subtitulo;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontFamily: AppTheme.titleFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: p.textBright,
                ),
              ),
              if (subtitulo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitulo!,
                    style: TextStyle(fontSize: 11, color: p.textMuted),
                  ),
                ),
            ],
          ),
        ),
        ?acao,
      ],
    );
  }
}

/// Titulo de pagina: linha "// OPERADOR" + nome em destaque.
class EvaPageTitle extends StatelessWidget {
  const EvaPageTitle({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acao,
  });

  final String titulo;
  final String? subtitulo;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitulo != null)
                Text(
                  subtitulo!,
                  style: TextStyle(
                    fontFamily: AppTheme.titleFont,
                    fontSize: 10,
                    letterSpacing: 0.6,
                    color: p.textMuted,
                  ),
                ),
              const SizedBox(height: 3),
              Text(
                titulo,
                style: TextStyle(
                  fontFamily: AppTheme.titleFont,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: p.textBright,
                  shadows: p.glow
                      ? [
                          Shadow(
                            color: p.purple.withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
        ?acao,
      ],
    );
  }
}

/// Card de resumo com icone quadrado a esquerda (.summary-card).
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.icone,
    required this.corValor,
  });

  final String rotulo;
  final String valor;
  final IconData icone;
  final Color corValor;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return EvaCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.glow
                  ? p.border.withValues(alpha: 0.4)
                  : p.bgCardHover,
              border: Border.all(color: p.border),
              borderRadius: BorderRadius.circular(p.glow ? 4 : 8),
            ),
            child: Icon(icone, color: corValor, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '// $rotulo',
                  style: TextStyle(
                    fontFamily: AppTheme.titleFont,
                    fontSize: 9.5,
                    letterSpacing: 0.4,
                    color: p.textMuted,
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    valor,
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: corValor,
                      shadows: p.glow
                          ? [
                              Shadow(
                                color: corValor.withValues(alpha: 0.45),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
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

/// Barra de progresso de meta/limite (.meta-progress-track + fill).
class EvaProgressBar extends StatelessWidget {
  const EvaProgressBar({
    super.key,
    required this.percentual,
    required this.cor,
    this.altura = 6,
  });

  /// Valor de 0 a 100.
  final double percentual;
  final Color cor;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final frac = (percentual / 100).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(altura / 2),
      child: Container(
        height: altura,
        color: p.glow ? p.border.withValues(alpha: 0.5) : p.border,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: frac,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.circular(altura / 2),
                boxShadow: p.glow
                    ? [BoxShadow(color: cor, blurRadius: 6)]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Faixa de alerta, equivalente aos .alert do Bootstrap usados no dashboard.
class EvaAlert extends StatelessWidget {
  const EvaAlert({
    super.key,
    required this.icone,
    required this.cor,
    required this.child,
    this.onTap,
  });

  final IconData icone;
  final Color cor;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final conteudo = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.07),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: child),
          ?(onTap != null
              ? Icon(Icons.chevron_right, color: cor, size: 18)
              : null),
        ],
      ),
    );

    if (onTap == null) return conteudo;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: conteudo,
    );
  }
}

/// Estado vazio padrao das listagens.
class EvaEmptyState extends StatelessWidget {
  const EvaEmptyState({
    super.key,
    required this.icone,
    required this.mensagem,
    this.acao,
  });

  final IconData icone;
  final String mensagem;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 42, color: p.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: p.textMuted),
          ),
          if (acao != null) ...[const SizedBox(height: 16), acao!],
        ],
      ),
    );
  }
}

/// Etiqueta de tipo (Receita / Despesa) usada nas listagens.
class EvaChip extends StatelessWidget {
  const EvaChip({super.key, required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(
          fontFamily: AppTheme.titleFont,
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: cor,
        ),
      ),
    );
  }
}

/// Valor monetario em fonte monoespacada, com brilho no tema EVA.
class EvaMoney extends StatelessWidget {
  const EvaMoney({
    super.key,
    required this.valor,
    required this.cor,
    this.sinal,
    this.fontSize = 13.5,
    this.bold = true,
  });

  final num valor;
  final Color cor;

  /// true = receita (+), false = despesa (-), null = sem sinal.
  final bool? sinal;
  final double fontSize;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final texto = sinal == null
        ? Fmt.moeda(valor)
        : Fmt.moedaComSinal(valor, sinal!);
    return Text(
      texto,
      style: TextStyle(
        fontFamily: AppTheme.monoFont,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: cor,
        shadows: p.glow
            ? [Shadow(color: cor.withValues(alpha: 0.35), blurRadius: 8)]
            : null,
      ),
    );
  }
}
