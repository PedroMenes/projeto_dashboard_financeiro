import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Guarda e verifica senhas com PBKDF2-HMAC-SHA256.
///
/// Na versao web o PHP usava `password_hash()` (bcrypt). Aqui o equivalente
/// em Dart puro e o PBKDF2: cada senha recebe um "sal" aleatorio e passa por
/// milhares de rodadas de hash, o que torna a quebra por forca bruta lenta.
/// A senha original nunca e gravada -- so o resultado do hash.
class PasswordHasher {
  const PasswordHasher._();

  static const _algoritmo = 'pbkdf2_sha256';
  static const _iteracoes = 120000;
  static const _tamanhoSal = 16;
  static const _tamanhoChave = 32;

  static final _rng = Random.secure();

  /// Gera o hash de uma senha nova.
  /// Formato: pbkdf2_sha256$iteracoes$salBase64$hashBase64
  static String hash(String senha, {int iteracoes = _iteracoes}) {
    final sal = Uint8List.fromList(
      List<int>.generate(_tamanhoSal, (_) => _rng.nextInt(256)),
    );
    final derivada = _pbkdf2(utf8.encode(senha), sal, iteracoes, _tamanhoChave);
    return [
      _algoritmo,
      '$iteracoes',
      base64.encode(sal),
      base64.encode(derivada),
    ].join(r'$');
  }

  /// Confere se a senha digitada corresponde ao hash guardado.
  static bool verify(String senha, String hashGuardado) {
    final partes = hashGuardado.split(r'$');
    if (partes.length != 4 || partes[0] != _algoritmo) return false;

    final iteracoes = int.tryParse(partes[1]);
    if (iteracoes == null || iteracoes <= 0) return false;

    final Uint8List sal;
    final Uint8List esperada;
    try {
      sal = base64.decode(partes[2]);
      esperada = base64.decode(partes[3]);
    } on FormatException {
      return false;
    }

    final derivada =
        _pbkdf2(utf8.encode(senha), sal, iteracoes, esperada.length);
    return _comparacaoSegura(derivada, esperada);
  }

  /// PBKDF2 conforme a RFC 8018, usando HMAC-SHA256 como funcao base.
  static Uint8List _pbkdf2(
    List<int> senha,
    List<int> sal,
    int iteracoes,
    int tamanhoSaida,
  ) {
    final hmac = Hmac(sha256, senha);
    final tamanhoBloco = sha256.convert(const []).bytes.length;
    final blocos = (tamanhoSaida / tamanhoBloco).ceil();
    final saida = Uint8List(blocos * tamanhoBloco);

    for (var i = 1; i <= blocos; i++) {
      // U1 = HMAC(senha, sal || contador_big_endian)
      final entrada = Uint8List(sal.length + 4)
        ..setRange(0, sal.length, sal)
        ..buffer.asByteData().setUint32(sal.length, i);

      var u = Uint8List.fromList(hmac.convert(entrada).bytes);
      final acumulado = Uint8List.fromList(u);

      // Un = HMAC(senha, Un-1), acumulado com XOR
      for (var r = 1; r < iteracoes; r++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var b = 0; b < acumulado.length; b++) {
          acumulado[b] ^= u[b];
        }
      }

      saida.setRange((i - 1) * tamanhoBloco, i * tamanhoBloco, acumulado);
    }

    return Uint8List.sublistView(saida, 0, tamanhoSaida);
  }

  /// Compara byte a byte sempre no mesmo tempo, para nao vazar informacao
  /// atraves da duracao da comparacao (ataque de temporizacao).
  static bool _comparacaoSegura(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diferenca = 0;
    for (var i = 0; i < a.length; i++) {
      diferenca |= a[i] ^ b[i];
    }
    return diferenca == 0;
  }
}
