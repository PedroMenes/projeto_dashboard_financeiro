/// Erro de regra de negocio ou validacao.
///
/// Faz o papel do array `$erros` que as paginas PHP montavam antes de
/// gravar: a tela captura a excecao e lista as mensagens para o usuario.
class RegraNegocioException implements Exception {
  RegraNegocioException(this.erros);

  RegraNegocioException.unica(String erro) : erros = [erro];

  final List<String> erros;

  @override
  String toString() => erros.join(' ');
}

/// Acumula mensagens de validacao e dispara tudo de uma vez,
/// como as paginas PHP faziam com `if (empty($erros))`.
class Validador {
  final List<String> _erros = [];

  bool get temErros => _erros.isNotEmpty;

  void checar(bool condicaoInvalida, String mensagem) {
    if (condicaoInvalida) _erros.add(mensagem);
  }

  void add(String mensagem) => _erros.add(mensagem);

  /// Dispara a excecao se houver qualquer erro acumulado.
  void lancarSeInvalido() {
    if (_erros.isNotEmpty) throw RegraNegocioException(List.of(_erros));
  }
}
