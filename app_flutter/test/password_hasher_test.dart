import 'package:financeiro_app/data/database/password_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Iteracoes baixas apenas nos testes: o PBKDF2 real usa 120 mil, o que
  // deixaria a suite lenta sem ganho nenhum de cobertura.
  const iteracoesRapidas = 1000;

  group('PasswordHasher', () {
    test('aceita a senha correta', () {
      final hash = PasswordHasher.hash('123456', iteracoes: iteracoesRapidas);
      expect(PasswordHasher.verify('123456', hash), isTrue);
    });

    test('rejeita senha errada', () {
      final hash = PasswordHasher.hash('123456', iteracoes: iteracoesRapidas);
      expect(PasswordHasher.verify('123457', hash), isFalse);
      expect(PasswordHasher.verify('', hash), isFalse);
      expect(PasswordHasher.verify('1234567', hash), isFalse);
    });

    test('nunca guarda a senha em texto puro', () {
      final hash = PasswordHasher.hash('senhaSecreta', iteracoes: iteracoesRapidas);
      expect(hash.contains('senhaSecreta'), isFalse);
    });

    test('gera hashes diferentes para a mesma senha (sal aleatorio)', () {
      final a = PasswordHasher.hash('igual', iteracoes: iteracoesRapidas);
      final b = PasswordHasher.hash('igual', iteracoes: iteracoesRapidas);
      expect(a, isNot(equals(b)));
      // Mesmo diferentes, os dois precisam validar a senma senha.
      expect(PasswordHasher.verify('igual', a), isTrue);
      expect(PasswordHasher.verify('igual', b), isTrue);
    });

    test('guarda o algoritmo e as iteracoes no proprio hash', () {
      final hash = PasswordHasher.hash('abc', iteracoes: iteracoesRapidas);
      final partes = hash.split(r'$');
      expect(partes, hasLength(4));
      expect(partes[0], 'pbkdf2_sha256');
      expect(partes[1], '$iteracoesRapidas');
    });

    test('rejeita hash malformado sem explodir', () {
      expect(PasswordHasher.verify('x', 'lixo'), isFalse);
      expect(PasswordHasher.verify('x', r'pbkdf2_sha256$abc$def$ghi'), isFalse);
      expect(PasswordHasher.verify('x', r'outro_algo$1000$AAAA$BBBB'), isFalse);
      expect(PasswordHasher.verify('x', ''), isFalse);
    });

    test('senha com acentos e emoji funciona', () {
      const senha = 'coração🔥';
      final hash = PasswordHasher.hash(senha, iteracoes: iteracoesRapidas);
      expect(PasswordHasher.verify(senha, hash), isTrue);
      expect(PasswordHasher.verify('coracao🔥', hash), isFalse);
    });
  });
}
