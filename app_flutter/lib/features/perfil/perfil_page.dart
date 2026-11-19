import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/eva_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/eva_widgets.dart';
import '../../data/repositories/auth_repository.dart';
import '../../main.dart';
import '../shared/form_widgets.dart';

/// Perfil do operador: editar dados, trocar senha, escolher a skin,
/// excluir a conta e redefinir o banco local.
/// Porta do `perfil.php` mais o seletor de tema do `includes/tema.php`.
class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senhaAtual = TextEditingController();
  final _novaSenha = TextEditingController();
  final _confirmacao = TextEditingController();
  final _auth = const AuthRepository();

  List<String> _erros = const [];
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final u = context.app.usuario;
      if (u == null) return;
      _nome.text = u.nome;
      _email.text = u.email;
    });
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senhaAtual.dispose();
    _novaSenha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erros = const [];
    });

    final app = context.app;
    final erros = await executarSalvando(() async {
      final atualizado = await _auth.atualizarPerfil(
        id: app.usuarioId,
        nome: _nome.text,
        email: _email.text,
        senhaAtual: _senhaAtual.text,
        novaSenha: _novaSenha.text,
        novaSenhaConfirmacao: _confirmacao.text,
      );
      app.atualizarUsuario(atualizado);
    });

    if (!mounted) return;

    setState(() {
      _erros = erros;
      _salvando = false;
    });

    if (erros.isEmpty) {
      _senhaAtual.clear();
      _novaSenha.clear();
      _confirmacao.clear();
      avisar(context, 'Perfil atualizado.');
    }
  }

  Future<void> _excluirConta() async {
    final ok = await confirmar(
      context,
      titulo: 'Excluir conta',
      mensagem: 'Isso apaga permanentemente sua conta e TODAS as suas '
          'transacoes, metas e recorrencias deste aparelho. '
          'Nao da para desfazer.',
      rotuloConfirmar: 'Excluir tudo',
    );
    if (!ok || !mounted) return;

    final app = context.app;
    await _auth.excluirConta(app.usuarioId);
    await app.sair();
  }

  Future<void> _redefinirBanco() async {
    final ok = await confirmar(
      context,
      titulo: 'Redefinir dados',
      mensagem: 'Apaga o banco local inteiro e recria tudo do zero, '
          'com as categorias padrao e o operador de demonstracao. '
          'Todos os operadores e lancamentos serao perdidos.',
      rotuloConfirmar: 'Redefinir',
    );
    if (!ok || !mounted) return;

    await context.app.redefinirTudo();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = context.eva;
    final u = app.usuario;

    return ListView(
      padding: context.paddingPagina,
      children: [
        EvaPageTitle(
          titulo: 'MEU PERFIL',
          subtitulo: '// dados do operador e aparencia',
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.isMobile ? 9999 : 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cartao de identificacao
              EvaCard(
                statusBar: true,
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        border: Border.all(color: p.purple, width: 1.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: p.purpleLight,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (u?.nome ?? '').toUpperCase(),
                            style: TextStyle(
                              fontFamily: AppTheme.titleFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: p.textBright,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            u?.email ?? '',
                            style: TextStyle(fontSize: 11.5, color: p.text),
                          ),
                          if (u != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              'Operador desde ${Fmt.data(u.criadoEm)}',
                              style:
                                  TextStyle(fontSize: 10, color: p.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Aparencia / skin
              EvaCard(
                header: const EvaCardHeader(
                  titulo: 'Aparencia',
                  subtitulo: 'escolha a skin do sistema',
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final skin in EvaPalette.all) ...[
                      if (skin != EvaPalette.all.first)
                        const SizedBox(height: 8),
                      _OpcaoSkin(
                        skin: skin,
                        selecionada: app.palette.id == skin.id,
                        onTap: () => app.trocarTema(skin.id),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Dados da conta
              EvaCard(
                header: const EvaCardHeader(
                  titulo: 'Dados da conta',
                  subtitulo: 'altere nome, e-mail ou senha',
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ErroBox(erros: _erros),
                    EvaField(rotulo: 'Nome', controller: _nome),
                    const SizedBox(height: 16),
                    EvaField(
                      rotulo: 'E-mail',
                      controller: _email,
                      teclado: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(child: Divider(color: p.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'TROCAR SENHA (OPCIONAL)',
                            style: TextStyle(
                              fontFamily: AppTheme.titleFont,
                              fontSize: 8,
                              letterSpacing: 1.2,
                              color: p.textMuted,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: p.border)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    EvaField(
                      rotulo: 'Senha atual',
                      controller: _senhaAtual,
                      obscuro: true,
                      dica: 'necessaria para trocar',
                    ),
                    const SizedBox(height: 16),
                    EvaField(
                      rotulo: 'Nova senha',
                      controller: _novaSenha,
                      obscuro: true,
                      dica: 'minimo 6 caracteres',
                    ),
                    const SizedBox(height: 16),
                    EvaField(
                      rotulo: 'Confirmar nova senha',
                      controller: _confirmacao,
                      obscuro: true,
                      onSubmit: _salvar,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _salvando ? null : _salvar,
                      icon: _salvando
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 16),
                      label: const Text('SALVAR ALTERACOES'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Zona de risco
              EvaCard(
                header: EvaCardHeader(
                  titulo: 'Zona de risco',
                  subtitulo: 'acoes irreversiveis',
                  acao: Icon(Icons.warning_amber, color: p.red, size: 18),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AcaoPerigosa(
                      titulo: 'Excluir minha conta',
                      descricao: 'Remove este operador e todos os seus '
                          'lancamentos, metas e recorrencias.',
                      icone: Icons.person_remove_outlined,
                      onTap: _excluirConta,
                    ),
                    const SizedBox(height: 10),
                    _AcaoPerigosa(
                      titulo: 'Redefinir banco local',
                      descricao: 'Apaga tudo e recria o banco do zero, '
                          'com as categorias e o acesso de demonstracao.',
                      icone: Icons.restart_alt,
                      onTap: _redefinirBanco,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'NERV MAGI SYSTEM // v3.0.0 — dados armazenados '
                  'somente neste aparelho',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.titleFont,
                    fontSize: 8,
                    letterSpacing: 0.8,
                    color: p.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _OpcaoSkin extends StatelessWidget {
  const _OpcaoSkin({
    required this.skin,
    required this.selecionada,
    required this.onTap,
  });

  final EvaPalette skin;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selecionada
              ? p.purple.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: selecionada ? p.purple.withValues(alpha: 0.5) : p.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            // Amostra das cores da skin.
            Container(
              width: 44,
              height: 30,
              decoration: BoxDecoration(
                color: skin.bg,
                border: Border.all(color: skin.border),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 7, height: 7, color: skin.purple),
                  const SizedBox(width: 4),
                  Container(width: 7, height: 7, color: skin.green),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                skin.label,
                style: TextStyle(
                  fontFamily: AppTheme.titleFont,
                  fontSize: 11,
                  fontWeight:
                      selecionada ? FontWeight.w700 : FontWeight.w500,
                  color: selecionada ? p.purpleLight : p.text,
                ),
              ),
            ),
            Icon(
              selecionada
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: selecionada ? p.purple : p.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _AcaoPerigosa extends StatelessWidget {
  const _AcaoPerigosa({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.onTap,
  });

  final String titulo;
  final String descricao;
  final IconData icone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.eva;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: p.red.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icone, color: p.red, size: 19),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontFamily: AppTheme.titleFont,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: p.red,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    descricao,
                    style: TextStyle(fontSize: 10.5, color: p.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.red, size: 18),
          ],
        ),
      ),
    );
  }
}
