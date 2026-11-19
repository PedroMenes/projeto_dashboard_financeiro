import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/eva_palette.dart';
import '../data/database/app_database.dart';
import '../data/models/models.dart';
import '../data/repositories/auth_repository.dart';

/// Estado global do app: quem esta logado e qual skin esta ativa.
///
/// Faz o papel do `includes/auth.php` (sessao do PHP) e do
/// `includes/tema.php` (cookie de tema) da versao web. A diferenca e que
/// aqui a "sessao" fica guardada no proprio aparelho, nas preferencias.
class AppState extends ChangeNotifier {
  AppState({AuthRepository? auth}) : _auth = auth ?? const AuthRepository();

  final AuthRepository _auth;

  static const _chaveUsuario = 'usuario_id';
  static const _chaveTema = 'tema';

  SharedPreferences? _prefs;

  Usuario? _usuario;
  EvaPalette _palette = EvaPalette.eva;
  bool _carregando = true;
  int _versaoDados = 0;

  Usuario? get usuario => _usuario;
  EvaPalette get palette => _palette;
  bool get carregando => _carregando;
  bool get logado => _usuario != null;

  /// Contador incrementado a cada gravacao no banco. As telas usam esse
  /// numero na chave do widget, de modo que uma alteracao feita numa tela
  /// faca as outras recarregarem os dados quando forem exibidas.
  int get versaoDados => _versaoDados;

  /// Avisa o app de que algo foi gravado e as telas devem recarregar.
  void notificarMudanca() {
    _versaoDados++;
    notifyListeners();
  }

  /// Id do operador logado -- atalho usado pelos repositorios.
  /// Só deve ser lido quando [logado] e verdadeiro.
  int get usuarioId => _usuario!.id;

  /// Le as preferencias salvas e restaura a sessao anterior, se houver.
  /// Chamado uma vez na abertura do app.
  Future<void> inicializar() async {
    _prefs = await SharedPreferences.getInstance();

    _palette = EvaPalette.fromName(_prefs!.getString(_chaveTema));

    final id = _prefs!.getInt(_chaveUsuario);
    if (id != null) {
      try {
        _usuario = await _auth.buscarPorId(id);
      } catch (_) {
        // O operador foi excluido ou o banco foi redefinido:
        // descarta a sessao e segue para a tela de login.
        await _prefs!.remove(_chaveUsuario);
      }
    }

    _carregando = false;
    notifyListeners();
  }

  /// Marca o operador como logado e guarda a sessao.
  Future<void> entrar(Usuario usuario) async {
    _usuario = usuario;
    await _prefs?.setInt(_chaveUsuario, usuario.id);
    notifyListeners();
  }

  /// Encerra a sessao -- equivale ao `logout.php`.
  Future<void> sair() async {
    _usuario = null;
    await _prefs?.remove(_chaveUsuario);
    notifyListeners();
  }

  /// Atualiza os dados do operador em memoria depois de editar o perfil.
  void atualizarUsuario(Usuario usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  /// Troca a skin ativa e guarda a escolha.
  Future<void> trocarTema(SkinId id) async {
    _palette = EvaPalette.fromId(id);
    await _prefs?.setString(_chaveTema, id.name);
    notifyListeners();
  }

  /// Apaga o banco e volta ao estado de primeira instalacao.
  /// Usado pelo botao de redefinir dados na tela de perfil.
  Future<void> redefinirTudo() async {
    await AppDatabase.instance.redefinir();
    _usuario = null;
    await _prefs?.remove(_chaveUsuario);
    notifyListeners();
  }
}
