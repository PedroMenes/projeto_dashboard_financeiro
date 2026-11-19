import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Nome do banco no IndexedDB do navegador.
const kNomeBanco = 'financeiro.db';

/// Na web o SQLite roda compilado em WebAssembly e persiste no IndexedDB.
/// Os arquivos de apoio (sqlite3.wasm e sqflite_sw.js) ficam em `web/`.
Future<void> configurarMotorBanco() async {
  databaseFactory = databaseFactoryFfiWeb;
}

/// Na web nao existe caminho de arquivo: o nome ja identifica o banco.
Future<String> caminhoBanco() async => kNomeBanco;

/// Apaga o banco do IndexedDB -- usado pelo botao de redefinir dados.
Future<void> apagarArquivoBanco() async {
  await databaseFactory.deleteDatabase(kNomeBanco);
}
