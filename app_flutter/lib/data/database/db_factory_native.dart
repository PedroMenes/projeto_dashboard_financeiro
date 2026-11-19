import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Nome do arquivo do banco no disco.
const kNomeBanco = 'financeiro.db';

/// Prepara o motor do SQLite para a plataforma atual.
///
/// No Windows e no Linux o sqflite nao tem plugin nativo, entao usamos a
/// variante FFI. No Android, iOS e macOS o plugin padrao ja funciona.
Future<void> configurarMotorBanco() async {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

/// Caminho completo do arquivo do banco.
///
/// No desktop usamos a pasta de documentos de suporte do app; no mobile,
/// o diretorio de bancos padrao do sistema.
Future<String> caminhoBanco() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return p.join(dir.path, kNomeBanco);
  }
  return p.join(await getDatabasesPath(), kNomeBanco);
}

/// Apaga o arquivo do banco -- usado pelo botao de redefinir dados.
Future<void> apagarArquivoBanco() async {
  final caminho = await caminhoBanco();
  await deleteDatabase(caminho);
}
