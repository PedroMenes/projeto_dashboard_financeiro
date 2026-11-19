import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/eva_widgets.dart';
import 'features/auth/login_page.dart';
import 'features/shell/app_shell.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega os nomes de meses e dias em portugues para o intl.
  initializeDateFormatting('pt_BR');

  final estado = AppState();
  await estado.inicializar();

  runApp(FinanceiroApp(estado: estado));
}

/// Deixa o [AppState] acessivel de qualquer ponto da arvore e reconstroi
/// os widgets interessados quando algo muda (login, logout, troca de tema).
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope nao encontrado na arvore.');
    return scope!.notifier!;
  }
}

extension AppStateContext on BuildContext {
  AppState get app => AppStateScope.of(this);
}

class FinanceiroApp extends StatelessWidget {
  const FinanceiroApp({super.key, required this.estado});

  final AppState estado;

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: estado,
      child: Builder(
        builder: (context) {
          final app = context.app;
          final palette = app.palette;

          return MaterialApp(
            title: 'Controle Financeiro // NERV',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(palette),
            // Calendarios, botoes do sistema e nomes de mes em portugues.
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [Locale('pt', 'BR')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => PaletteScope(
              palette: palette,
              child: child ?? const SizedBox.shrink(),
            ),
            // Enquanto a sessao e restaurada mostramos uma tela de carga;
            // depois vai para o painel ou para o login.
            home: app.carregando
                ? const _TelaCarregando()
                : (app.logado ? const AppShell() : const LoginPage()),
          );
        },
      ),
    );
  }
}

class _TelaCarregando extends StatelessWidget {
  const _TelaCarregando();

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'MAGI SYSTEM',
              style: TextStyle(
                fontFamily: AppTheme.titleFont,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: p.purpleLight,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: p.green,
                backgroundColor: p.border,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'INICIALIZANDO...',
              style: TextStyle(
                fontFamily: AppTheme.titleFont,
                fontSize: 9,
                letterSpacing: 2,
                color: p.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
