import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/eva_widgets.dart';
import '../../main.dart';
import '../categorias/categorias_page.dart';
import '../dashboard/dashboard_page.dart';
import '../metas/metas_page.dart';
import '../perfil/perfil_page.dart';
import '../recorrencias/recorrencias_page.dart';
import '../relatorios/relatorios_page.dart';
import '../shared/form_widgets.dart';
import '../transacoes/transacoes_page.dart';

/// Uma entrada do menu de navegacao.
class _Destino {
  const _Destino({
    required this.rotulo,
    required this.curto,
    required this.icone,
    required this.construtor,
    this.naBarraInferior = false,
  });

  final String rotulo;
  final String curto;
  final IconData icone;
  final Widget Function() construtor;

  /// Se aparece na barra inferior do celular (as demais ficam no menu).
  final bool naBarraInferior;
}

const _destinos = <_Destino>[
  _Destino(
    rotulo: 'Painel',
    curto: 'Painel',
    icone: Icons.dashboard_outlined,
    construtor: DashboardPage.new,
    naBarraInferior: true,
  ),
  _Destino(
    rotulo: 'Transacoes',
    curto: 'Lancar',
    icone: Icons.swap_vert,
    construtor: TransacoesPage.new,
    naBarraInferior: true,
  ),
  _Destino(
    rotulo: 'Metas',
    curto: 'Metas',
    icone: Icons.flag_outlined,
    construtor: MetasPage.new,
    naBarraInferior: true,
  ),
  _Destino(
    rotulo: 'Relatorios',
    curto: 'Relat.',
    icone: Icons.insights_outlined,
    construtor: RelatoriosPage.new,
    naBarraInferior: true,
  ),
  _Destino(
    rotulo: 'Categorias',
    curto: 'Categ.',
    icone: Icons.sell_outlined,
    construtor: CategoriasPage.new,
  ),
  _Destino(
    rotulo: 'Recorrencias',
    curto: 'Recorr.',
    icone: Icons.autorenew,
    construtor: RecorrenciasPage.new,
  ),
  _Destino(
    rotulo: 'Perfil',
    curto: 'Perfil',
    icone: Icons.person_outline,
    construtor: PerfilPage.new,
  ),
];

/// Casca do app depois do login.
///
/// Substitui o `includes/navbar.php`: no desktop a navegacao e uma barra
/// lateral fixa; no celular, uma barra inferior com as quatro telas mais
/// usadas e um menu lateral com o resto.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _indice = 0;

  /// Indices que aparecem na barra inferior do celular.
  static final _indicesBarraInferior = [
    for (var i = 0; i < _destinos.length; i++)
      if (_destinos[i].naBarraInferior) i,
  ];

  void _ir(int indice) {
    if (indice == _indice) return;
    setState(() => _indice = indice);
  }

  Future<void> _sair() async {
    final confirmou = await confirmar(
      context,
      titulo: 'Encerrar sessao',
      mensagem: 'Deseja sair do sistema? Seus dados continuam salvos '
          'neste aparelho.',
      rotuloConfirmar: 'Sair',
      destrutivo: false,
    );
    if (confirmou && mounted) await context.app.sair();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final destino = _destinos[_indice];

    // A chave inclui a versao dos dados: quando qualquer tela grava algo,
    // a tela exibida e remontada e recarrega do banco.
    final pagina = KeyedSubtree(
      key: ValueKey('${destino.rotulo}-${app.versaoDados}'),
      child: destino.construtor(),
    );

    if (context.usaBarraLateral) {
      return _LayoutDesktop(
        indice: _indice,
        onIr: _ir,
        onSair: _sair,
        child: pagina,
      );
    }
    return _LayoutMobile(
      indice: _indice,
      indicesBarra: _indicesBarraInferior,
      onIr: _ir,
      onSair: _sair,
      child: pagina,
    );
  }
}

/// Desktop e tablet: barra lateral fixa a esquerda.
class _LayoutDesktop extends StatelessWidget {
  const _LayoutDesktop({
    required this.indice,
    required this.onIr,
    required this.onSair,
    required this.child,
  });

  final int indice;
  final ValueChanged<int> onIr;
  final VoidCallback onSair;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final app = context.app;
    // Em telas bem largas a barra mostra os rotulos ao lado dos icones.
    final estendida = context.screenWidth >= 1280;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: estendida ? 212 : 86,
            decoration: BoxDecoration(
              color: p.bgCard,
              border: Border(right: BorderSide(color: p.border)),
            ),
            child: Column(
              children: [
                const EvaStatusBar(),
                _CabecalhoLateral(estendida: estendida),
                Divider(height: 1, color: p.border),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        for (var i = 0; i < _destinos.length; i++)
                          _ItemLateral(
                            destino: _destinos[i],
                            selecionado: i == indice,
                            estendida: estendida,
                            onTap: () => onIr(i),
                          ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: p.border),
                _RodapeLateral(
                  estendida: estendida,
                  nome: app.usuario?.nome ?? '',
                  onSair: onSair,
                ),
              ],
            ),
          ),
          Expanded(child: EvaGridBackground(child: child)),
        ],
      ),
    );
  }
}

class _CabecalhoLateral extends StatelessWidget {
  const _CabecalhoLateral({required this.estendida});

  final bool estendida;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: estendida ? 16 : 8,
        vertical: 16,
      ),
      child: Row(
        mainAxisAlignment:
            estendida ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Icon(Icons.hexagon_outlined, color: p.green, size: 22),
          if (estendida) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NERV',
                    style: TextStyle(
                      fontFamily: AppTheme.titleFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      color: p.textBright,
                    ),
                  ),
                  Text(
                    'MAGI SYSTEM',
                    style: TextStyle(
                      fontFamily: AppTheme.titleFont,
                      fontSize: 7,
                      letterSpacing: 1.4,
                      color: p.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemLateral extends StatelessWidget {
  const _ItemLateral({
    required this.destino,
    required this.selecionado,
    required this.estendida,
    required this.onTap,
  });

  final _Destino destino;
  final bool selecionado;
  final bool estendida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final cor = selecionado ? p.purpleLight : p.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Tooltip(
        message: estendida ? '' : destino.rotulo,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: estendida ? 12 : 0,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: selecionado
                  ? p.purple.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: Border.all(
                color: selecionado
                    ? p.purple.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: estendida
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(destino.icone, size: 19, color: cor),
                if (estendida) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      destino.rotulo,
                      style: TextStyle(
                        fontFamily: AppTheme.titleFont,
                        fontSize: 10.5,
                        fontWeight:
                            selecionado ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.5,
                        color: cor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RodapeLateral extends StatelessWidget {
  const _RodapeLateral({
    required this.estendida,
    required this.nome,
    required this.onSair,
  });

  final bool estendida;
  final String nome;
  final VoidCallback onSair;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: estendida ? 12 : 8,
        vertical: 12,
      ),
      child: Column(
        children: [
          if (estendida) ...[
            Row(
              children: [
                Icon(Icons.circle, size: 7, color: p.green),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    nome.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.titleFont,
                      fontSize: 8.5,
                      letterSpacing: 0.6,
                      color: p.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Tooltip(
            message: estendida ? '' : 'Encerrar sessao',
            child: InkWell(
              onTap: onSair,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: p.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 15, color: p.red),
                    if (estendida) ...[
                      const SizedBox(width: 8),
                      Text(
                        'SAIR',
                        style: TextStyle(
                          fontFamily: AppTheme.titleFont,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: p.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Celular: barra inferior com as quatro telas principais e um menu
/// lateral (drawer) com as demais.
class _LayoutMobile extends StatelessWidget {
  const _LayoutMobile({
    required this.indice,
    required this.indicesBarra,
    required this.onIr,
    required this.onSair,
    required this.child,
  });

  final int indice;
  final List<int> indicesBarra;
  final ValueChanged<int> onIr;
  final VoidCallback onSair;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    final app = context.app;
    final naBarra = indicesBarra.contains(indice);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.hexagon_outlined, color: p.green, size: 18),
            const SizedBox(width: 8),
            Text(_destinos[indice].rotulo.toUpperCase()),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: p.bgCard,
        child: SafeArea(
          child: Column(
            children: [
              const EvaStatusBar(),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(Icons.hexagon_outlined, color: p.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NERV',
                            style: TextStyle(
                              fontFamily: AppTheme.titleFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                              color: p.textBright,
                            ),
                          ),
                          Text(
                            (app.usuario?.nome ?? '').toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTheme.titleFont,
                              fontSize: 8,
                              letterSpacing: 1,
                              color: p.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: p.border),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (var i = 0; i < _destinos.length; i++)
                      ListTile(
                        leading: Icon(
                          _destinos[i].icone,
                          size: 19,
                          color: i == indice ? p.purpleLight : p.textMuted,
                        ),
                        title: Text(
                          _destinos[i].rotulo,
                          style: TextStyle(
                            fontFamily: AppTheme.titleFont,
                            fontSize: 11,
                            fontWeight: i == indice
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: i == indice ? p.purpleLight : p.text,
                          ),
                        ),
                        selected: i == indice,
                        selectedTileColor: p.purple.withValues(alpha: 0.1),
                        onTap: () {
                          Navigator.of(context).pop();
                          onIr(i);
                        },
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: p.border),
              ListTile(
                leading: Icon(Icons.logout, size: 18, color: p.red),
                title: Text(
                  'Sair',
                  style: TextStyle(
                    fontFamily: AppTheme.titleFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.red,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onSair();
                },
              ),
            ],
          ),
        ),
      ),
      body: EvaGridBackground(child: child),
      bottomNavigationBar: NavigationBar(
        // Quando a tela atual nao esta na barra (ex.: Perfil), nenhum
        // item fica aceso -- o destaque fica no menu lateral.
        selectedIndex: naBarra ? indicesBarra.indexOf(indice) : 0,
        onDestinationSelected: (i) => onIr(indicesBarra[i]),
        destinations: [
          for (final i in indicesBarra)
            NavigationDestination(
              icon: Icon(_destinos[i].icone),
              label: _destinos[i].curto,
            ),
        ],
      ),
    );
  }
}
