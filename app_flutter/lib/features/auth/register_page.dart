import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/eva_widgets.dart';
import '../../data/repositories/auth_repository.dart';
import '../shared/form_widgets.dart';
import 'mecha_background.dart';

/// Cadastro de novo operador -- porta do `register.php`.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  final _auth = const AuthRepository();

  List<String> _erros = const [];
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (_salvando) return;
    setState(() {
      _salvando = true;
      _erros = const [];
    });

    final erros = await executarSalvando(() async {
      await _auth.registrar(
        nome: _nome.text,
        email: _email.text,
        senha: _senha.text,
        senhaConfirmacao: _confirmacao.text,
      );
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
    final p = context.eva;

    return Scaffold(
      appBar: AppBar(title: const Text('NOVO OPERADOR')),
      body: MechaBackground(
        palette: p,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: EvaCard(
                statusBar: true,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'REGISTRO DE ACESSO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.titleFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: p.textBright,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '// preencha os dados do novo operador',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10.5, color: p.textMuted),
                    ),
                    const SizedBox(height: 22),
                    ErroBox(erros: _erros),
                    EvaField(
                      rotulo: 'Nome',
                      controller: _nome,
                      dica: 'Seu nome completo',
                      autofoco: true,
                    ),
                    const SizedBox(height: 16),
                    EvaField(
                      rotulo: 'E-mail',
                      controller: _email,
                      dica: 'operador@nerv.jp',
                      teclado: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    EvaField(
                      rotulo: 'Codigo de Acesso',
                      controller: _senha,
                      dica: 'minimo 6 caracteres',
                      obscuro: true,
                    ),
                    const SizedBox(height: 16),
                    EvaField(
                      rotulo: 'Confirmar Codigo',
                      controller: _confirmacao,
                      dica: 'repita o codigo',
                      obscuro: true,
                      onSubmit: _cadastrar,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _salvando ? null : _cadastrar,
                      icon: _salvando
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add, size: 16),
                      label: const Text('REGISTRAR'),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: _salvando
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('JA TENHO ACESSO'),
                      ),
                    ),
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
