/// Escolhe o motor do SQLite conforme a plataforma, em tempo de compilacao.
///
/// - Mobile (Android / iOS) e macOS: o plugin nativo do sqflite.
/// - Desktop (Windows / Linux): sqflite_common_ffi, que carrega a
///   biblioteca do SQLite via FFI.
/// - Web: sqflite_common_ffi_web, que roda o SQLite compilado em
///   WebAssembly e guarda os dados no IndexedDB do navegador.
///
/// O `if (dart.library.js_interop)` faz o compilador trocar o arquivo
/// quando o alvo e a web, evitando que o codigo de desktop (que depende
/// de `dart:io`) seja incluido no bundle do navegador.
library;

export 'db_factory_native.dart'
    if (dart.library.js_interop) 'db_factory_web.dart';
