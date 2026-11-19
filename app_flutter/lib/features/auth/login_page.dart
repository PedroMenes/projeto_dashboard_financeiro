import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/eva_widgets.dart';
import '../../data/repositories/auth_repository.dart';
import '../../main.dart';
import '../shared/form_widgets.dart';
import 'mecha_background.dart';
import 'register_page.dart';

/// Terminal de acesso -- porta do `login.php`, incluindo o painel
/// mecha animado no fundo.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _auth = const AuthRepository();

  List<String> _erros = const [];
  bool _entrando = false;
  bool _mostrarSenha = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_entrando) return;
    setState(() {
      _entrando = true;
      _erros = const [];
    });

    try {
      final usuario = await _auth.autenticar(
        email: _email.text,
        senha: _senha.text,
      );

      if (!mounted) return;

      if (usuario == null) {
        setState(() {
          _erros = const ['ID do operador ou codigo de acesso incorreto.'];
          _entrando = false;
        });
        return;
      }

      // O AppState notifica e o MaterialApp troca para o painel.
      await context.app.entrar(usuario);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erros = ['Falha ao acessar o sistema: $e'];
        _entrando = false;
      });
    }
  }

  Future<void> _abrirCadastro() async {
    final criou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
    if (criou == true && mounted) {
      avisar(context, 'Operador cadastrado. Faca o acesso.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.eva;

    return Scaffold(
      body: MechaBackground(
        palette: p,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: EvaCard(
                statusBar: true,
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Marca(),
                    const SizedBox(height: 22),
                    const _SeparadorRotulado(texto: 'IDENTIFICACAO'),
                    const SizedBox(height: 20),
                    ErroBox(erros: _erros),
                    EvaField(
                      rotulo: 'ID do Operador',
                      controller: _email,
                      dica: 'operador@nerv.jp',
                      teclado: TextInputType.emailAddress,
                      autofoco: true,
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        EvaField(
                          rotulo: 'Codigo de Acesso',
                          controller: _senha,
                          dica: '••••••',
                          obscuro: !_mostrarSenha,
                          onSubmit: _entrar,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 18, right: 4),
                          child: IconButton(
                            icon: Icon(
                              _mostrarSenha
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                              color: p.textMuted,
                            ),
                            onPressed: () => setState(
                              () => _mostrarSenha = !_mostrarSenha,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _entrando ? null : _entrar,
                      icon: _entrando
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login, size: 16),
                      label: Text(
                        _entrando ? 'AUTENTICANDO...' : 'INICIAR SESSAO',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton(
                        onPressed: _entrando ? null : _abrirCadastro,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'NOVO OPERADOR?  ',
                                style: TextStyle(color: p.textMuted),
                              ),
                              TextSpan(
                                text: 'REGISTRAR ACESSO',
                                style: TextStyle(color: p.purpleLight),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontFamily: AppTheme.titleFont,
                            fontSize: 9.5,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _CredenciaisDemo(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            border: Border.all(color: p.purple, width: 1.5),
            borderRadius: BorderRadius.circular(4),
            boxShadow: p.glow
                ? [
                    BoxShadow(
                      color: p.purple.withValues(alpha: 0.45),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Icon(Icons.hexagon_outlined, color: p.green, size: 26),
        ),
        const SizedBox(height: 14),
        Text(
          'NERV',
          style: TextStyle(
            fontFamily: AppTheme.titleFont,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
            color: p.textBright,
            shadows: p.glow
                ? [
                    Shadow(
                      color: p.purple.withValues(alpha: 0.7),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'MAGI SYSTEM // CONTROLE FINANCEIRO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.titleFont,
            fontSize: 8,
            letterSpacing: 1.6,
            color: p.textMuted,
          ),
        ),
      ],
    );
  }
}

class _SeparadorRotulado extends StatelessWidget {
  const _SeparadorRotulado({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: p.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            texto,
            style: TextStyle(
              fontFamily: AppTheme.titleFont,
              fontSize: 8,
              letterSpacing: 2.4,
              color: p.purpleLight,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: p.border)),
      ],
    );
  }
}

/// Lembrete das credenciais de demonstracao criadas junto com o banco,
/// as mesmas que o `database.sql` inseria na versao web.
class _CredenciaisDemo extends StatelessWidget {
  const _CredenciaisDemo();

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.purple.withValues(alpha: 0.05),
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// ACESSO DE DEMONSTRACAO',
            style: TextStyle(
              fontFamily: AppTheme.titleFont,
              fontSize: 8,
              letterSpacing: 1.2,
              color: p.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'admin@financeiro.com  /  123456',
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 11.5,
              color: p.green,
            ),
          ),
        ],
      ),
    );
  }
}
