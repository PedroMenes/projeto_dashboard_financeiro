import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/eva_palette.dart';

/// Painel mecha animado do fundo da tela de login.
///
/// Porta do canvas `mechaBg` do `login.php`: grade de 48px, nos pulsantes
/// nas intersecoes, linha de varredura descendo e fragmentos de dados
/// flutuando. Toda a animacao e desenhada num unico [CustomPainter],
/// repintado a cada quadro por um [AnimationController].
class MechaBackground extends StatefulWidget {
  const MechaBackground({super.key, required this.palette, this.child});

  final EvaPalette palette;
  final Widget? child;

  @override
  State<MechaBackground> createState() => _MechaBackgroundState();
}

class _MechaBackgroundState extends State<MechaBackground>
    with SingleTickerProviderStateMixin {
  /// Duracao do ciclo. A varredura e os fragmentos derivam a posicao do
  /// tempo decorrido, nao da fase do ciclo, entao basta ser bem longo
  /// para que a repeticao nunca seja percebida.
  static const _cicloSegundos = 600.0;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 600),
  )..repeat();

  final _rng = Random(42);
  List<_Node> _nodes = const [];
  List<_Frag> _frags = const [];
  Size _ultimoTamanho = Size.zero;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Recria os nos e fragmentos quando a janela muda de tamanho.
  void _montarCena(Size size) {
    if (size == _ultimoTamanho) return;
    _ultimoTamanho = size;

    const grid = _MechaPainter.grid;
    final nodes = <_Node>[];
    final cols = (size.width / grid).ceil() + 1;
    final rows = (size.height / grid).ceil() + 1;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        // Apenas 18% das intersecoes recebem um no, como no original.
        if (_rng.nextDouble() < 0.18) {
          nodes.add(_Node(
            x: c * grid,
            y: r * grid,
            fase: _rng.nextDouble() * pi * 2,
            velocidade: 0.4 + _rng.nextDouble() * 0.8,
            tamanho: 1 + _rng.nextDouble() * 2,
            verde: _rng.nextDouble() >= 0.7,
          ));
        }
      }
    }

    final frags = <_Frag>[
      for (var i = 0; i < 26; i++)
        _Frag(
          x: _rng.nextDouble() * size.width,
          yInicial: _rng.nextDouble() * size.height,
          velocidade: 8 + _rng.nextDouble() * 22,
          texto: _textoAleatorio(_rng),
          opacidade: 0.18 + _rng.nextDouble() * 0.35,
          verde: _rng.nextDouble() < 0.6,
        ),
    ];

    _nodes = nodes;
    _frags = frags;
  }

  static const _hexChars = '0123456789ABCDEF';
  static const _frases = <String>[
    'MAGI-01', 'MAGI-02', 'MAGI-03', 'NERV//SYS',
    'EVA-01', 'UNIT-00', 'UNIT-02', 'SEELE//OK',
    'AT FIELD', 'SYNC 98%', 'CORE TEMP', 'PILOT OK',
    'LCL NORM', 'PWR 100%', 'ANGEL DET', 'ALERT LVL',
  ];

  static String _textoAleatorio(Random rng) {
    if (rng.nextBool()) {
      final len = 4 + rng.nextInt(8);
      return List.generate(len, (_) => _hexChars[rng.nextInt(16)]).join();
    }
    return _frases[rng.nextInt(_frases.length)];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _montarCena(Size(constraints.maxWidth, constraints.maxHeight));
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) => CustomPaint(
            painter: _MechaPainter(
              palette: widget.palette,
              segundos: _ctrl.value * _cicloSegundos,
              nodes: _nodes,
              frags: _frags,
            ),
            child: child,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _Node {
  const _Node({
    required this.x,
    required this.y,
    required this.fase,
    required this.velocidade,
    required this.tamanho,
    required this.verde,
  });

  final double x;
  final double y;
  final double fase;
  final double velocidade;
  final double tamanho;
  final bool verde;
}

class _Frag {
  const _Frag({
    required this.x,
    required this.yInicial,
    required this.velocidade,
    required this.texto,
    required this.opacidade,
    required this.verde,
  });

  final double x;
  final double yInicial;
  final double velocidade;
  final String texto;
  final double opacidade;
  final bool verde;
}

class _MechaPainter extends CustomPainter {
  const _MechaPainter({
    required this.palette,
    required this.segundos,
    required this.nodes,
    required this.frags,
  });

  final EvaPalette palette;

  /// Segundos decorridos desde o inicio da animacao.
  final double segundos;
  final List<_Node> nodes;
  final List<_Frag> frags;

  static const double grid = 48;
  static const double _velocidadeScan = 72; // px por segundo

  @override
  void paint(Canvas canvas, Size size) {
    _pintarGrade(canvas, size);
    _pintarNos(canvas, segundos);
    _pintarFragmentos(canvas, size, segundos);
    _pintarVarredura(canvas, size, segundos);
  }

  void _pintarGrade(Canvas canvas, Size size) {
    final fino = Paint()
      ..color = palette.border.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final grosso = Paint()
      ..color = palette.borderBright.withValues(alpha: 0.18)
      ..strokeWidth = 1;

    var i = 0;
    for (var x = 0.0; x <= size.width; x += grid, i++) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        i % 4 == 0 ? grosso : fino,
      );
    }
    i = 0;
    for (var y = 0.0; y <= size.height; y += grid, i++) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        i % 4 == 0 ? grosso : fino,
      );
    }
  }

  void _pintarNos(Canvas canvas, double segundos) {
    final paint = Paint();
    for (final n in nodes) {
      // Pulso suave entre 0.15 e 0.85 de opacidade.
      final pulso = (sin(segundos * n.velocidade + n.fase) + 1) / 2;
      final alpha = 0.15 + pulso * 0.7;
      paint.color = (n.verde ? palette.green : palette.purple)
          .withValues(alpha: alpha);
      canvas.drawCircle(Offset(n.x, n.y), n.tamanho, paint);
    }
  }

  void _pintarFragmentos(Canvas canvas, Size size, double segundos) {
    for (final f in frags) {
      // Sobem continuamente e reaparecem embaixo (modulo da altura).
      final y = (f.yInicial - f.velocidade * segundos) % (size.height + 40);
      final cor = (f.verde ? palette.green : palette.purpleLight)
          .withValues(alpha: f.opacidade);

      final tp = TextPainter(
        text: TextSpan(
          text: f.texto,
          style: TextStyle(
            fontFamily: AppTheme.monoFont,
            fontSize: 10,
            color: cor,
            letterSpacing: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(f.x, y));
    }
  }

  void _pintarVarredura(Canvas canvas, Size size, double segundos) {
    final scanY = (segundos * _velocidadeScan) % (size.height + 80);

    // Rastro esverdeado acima da linha.
    final rastro = Rect.fromLTWH(0, scanY - 60, size.width, 72);
    canvas.drawRect(
      rastro,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.green.withValues(alpha: 0),
            palette.green.withValues(alpha: 0.06),
            palette.green.withValues(alpha: 0.06),
          ],
          stops: const [0, 0.7, 1],
        ).createShader(rastro),
    );

    // A linha propriamente dita.
    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      Paint()
        ..color = palette.green.withValues(alpha: 0.55)
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_MechaPainter old) =>
      old.segundos != segundos || old.palette.id != palette.id;
}
