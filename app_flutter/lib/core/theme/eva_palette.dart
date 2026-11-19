import 'package:flutter/material.dart';

/// Paleta de cores do sistema, portada diretamente do `assets/css/custom.css`
/// da versao web. Cada skin aqui corresponde a um bloco de tokens do CSS:
///   - [EvaPalette.eva]    -> body.tema-eva
///   - [EvaPalette.escuro] -> body.tema-escuro
///   - [EvaPalette.normal] -> :root (tema claro padrao)
enum SkinId { eva, escuro, normal }

@immutable
class EvaPalette {
  const EvaPalette({
    required this.id,
    required this.label,
    required this.bg,
    required this.bgCard,
    required this.bgCardHover,
    required this.border,
    required this.borderBright,
    required this.purple,
    required this.purpleLight,
    required this.green,
    required this.greenDim,
    required this.orange,
    required this.yellow,
    required this.red,
    required this.text,
    required this.textMuted,
    required this.textBright,
    required this.glow,
    required this.gridBackground,
    required this.monoFont,
  });

  final SkinId id;
  final String label;

  final Color bg;
  final Color bgCard;
  final Color bgCardHover;
  final Color border;
  final Color borderBright;
  final Color purple;
  final Color purpleLight;
  final Color green;
  final Color greenDim;
  final Color orange;
  final Color yellow;
  final Color red;
  final Color text;
  final Color textMuted;
  final Color textBright;

  /// Se o skin usa brilho neon (box-shadow) nos elementos.
  final bool glow;

  /// Se o fundo recebe a malha de pontos roxos do tema EVA.
  final bool gridBackground;

  /// Se o corpo do app usa a fonte monoespacada sci-fi.
  final bool monoFont;

  bool get isDark => id != SkinId.normal;

  /// Tema NERV / Evangelion -- o visual principal do projeto.
  static const eva = EvaPalette(
    id: SkinId.eva,
    label: 'EVA // NERV',
    bg: Color(0xFF05000D),
    bgCard: Color(0xFF0B0016),
    bgCardHover: Color(0xFF0F001E),
    border: Color(0xFF2D1254),
    borderBright: Color(0xFF5B21B6),
    purple: Color(0xFF7C3AED),
    purpleLight: Color(0xFFA78BFA),
    green: Color(0xFF39FF14),
    greenDim: Color(0xFF4ADE80),
    orange: Color(0xFFF97316),
    yellow: Color(0xFFFBBF24),
    red: Color(0xFFEF4444),
    text: Color(0xFFD4C4F0),
    textMuted: Color(0xFF6B5F8A),
    textBright: Color(0xFFEDE9FE),
    glow: true,
    gridBackground: true,
    monoFont: true,
  );

  static const escuro = EvaPalette(
    id: SkinId.escuro,
    label: 'Escuro',
    bg: Color(0xFF16181D),
    bgCard: Color(0xFF1F2228),
    bgCardHover: Color(0xFF272B33),
    border: Color(0xFF343A40),
    borderBright: Color(0xFF495057),
    purple: Color(0xFF9D7BF0),
    purpleLight: Color(0xFFB794F6),
    green: Color(0xFF2DD36F),
    greenDim: Color(0xFF20C997),
    orange: Color(0xFFFD9843),
    yellow: Color(0xFFFFCA2C),
    red: Color(0xFFF1556C),
    text: Color(0xFFE9ECEF),
    textMuted: Color(0xFF9AA3AF),
    textBright: Color(0xFFFFFFFF),
    glow: false,
    gridBackground: false,
    monoFont: false,
  );

  static const normal = EvaPalette(
    id: SkinId.normal,
    label: 'Claro',
    bg: Color(0xFFF1F3F6),
    bgCard: Color(0xFFFFFFFF),
    bgCardHover: Color(0xFFF7F8FA),
    border: Color(0xFFE1E5EA),
    borderBright: Color(0xFFC5CBD3),
    purple: Color(0xFF6F42C1),
    purpleLight: Color(0xFF8B5CF6),
    green: Color(0xFF198754),
    greenDim: Color(0xFF20C997),
    orange: Color(0xFFFD7E14),
    yellow: Color(0xFFFFC107),
    red: Color(0xFFDC3545),
    text: Color(0xFF2B2F36),
    textMuted: Color(0xFF6C757D),
    textBright: Color(0xFF111418),
    glow: false,
    gridBackground: false,
    monoFont: false,
  );

  static const all = <EvaPalette>[eva, escuro, normal];

  static EvaPalette fromId(SkinId id) =>
      all.firstWhere((p) => p.id == id, orElse: () => eva);

  static EvaPalette fromName(String? name) => all.firstWhere(
        (p) => p.id.name == name,
        orElse: () => eva,
      );

  /// Cores usadas nas fatias dos graficos, na mesma ordem do Chart.js da web.
  List<Color> get chartColors => <Color>[
        purple,
        green,
        orange,
        purpleLight,
        yellow,
        red,
      ];
}
