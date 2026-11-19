```
███╗   ██╗███████╗██████╗ ██╗   ██╗     █████╗ ██████╗ ██████╗
████╗  ██║██╔════╝██╔══██╗██║   ██║    ██╔══██╗██╔══██╗██╔══██╗
██╔██╗ ██║█████╗  ██████╔╝██║   ██║    ███████║██████╔╝██████╔╝
██║╚██╗██║██╔══╝  ██╔══██╗╚██╗ ██╔╝    ██╔══██║██╔═══╝ ██╔═══╝
██║ ╚████║███████╗██║  ██║ ╚████╔╝     ██║  ██║██║     ██║
╚═╝  ╚═══╝╚══════╝╚═╝  ╚═══╝  ╚═══╝     ╚═╝  ╚═╝╚═╝     ╚═╝

// MAGI SYSTEM — CONTROLE FINANCEIRO
// VERSÃO APP — FLUTTER / DART
// PLATAFORMAS: ANDROID · iOS · WINDOWS · macOS · LINUX · WEB
```

Versão **aplicativo** do dashboard financeiro, escrita em **Flutter + Dart**.
É a mesma ideia do sistema em PHP que está na pasta acima, mas rodando como
app instalável no celular e no computador.

---

## ▸ A DIFERENÇA PRINCIPAL EM RELAÇÃO À VERSÃO WEB

| | Versão PHP (pasta acima) | Versão Flutter (esta pasta) |
|---|---|---|
| Onde os dados ficam | MySQL, num servidor | **SQLite, dentro do próprio aparelho** |
| Precisa de XAMPP? | Sim (Apache + MySQL) | **Não** |
| Precisa de internet? | Sim, para alcançar o servidor | **Não**, funciona offline |
| Como se usa | Pelo navegador | App instalado |

Em termos simples: **o app carrega o banco de dados dentro dele**. Não existe
servidor para ligar, não existe conexão para configurar. A contrapartida é que
os dados do app ficam só naquele aparelho — o que você lançar no celular não
aparece no site em PHP, e vice-versa.

---

## ▸ O QUE JÁ ESTÁ PRONTO

Tudo que a versão web faz foi portado:

- Login, cadastro de operador e logout
- Painel com saldo do mês, entradas, saídas e gráfico de pizza
- Alertas de recorrência pendente e de categoria perto do limite
- **CRUD de Transações** com filtros por tipo, mês e busca por descrição
- **CRUD de Categorias** com limite mensal e barra de uso
- **CRUD de Metas** com depósito, retirada e barra de progresso
- **CRUD de Recorrências** com lançamento mensal (individual ou em lote)
- **CRUD de Usuário** pela tela de perfil
- Relatórios de 3, 6 ou 12 meses com gráfico de barras e tabela
- Três skins: EVA // NERV, Escuro e Claro
- Animação de painel mecha na tela de login
- Layout que se adapta: barra lateral no computador, barra inferior no celular

---

## ▸ COMO RODAR

### Pré-requisito

Ter o **Flutter** instalado. Confira com:

```bash
flutter --version
```

### Rodar no navegador (o jeito mais rápido de ver funcionando)

```bash
cd app_flutter && flutter run -d chrome
```

### Rodar no Windows (precisa do Visual Studio, veja abaixo)

```bash
cd app_flutter && flutter run -d windows
```

### Rodar no celular Android (precisa do Android SDK, veja abaixo)

```bash
cd app_flutter && flutter run -d android
```

### Acesso de demonstração

O banco é criado sozinho na primeira abertura, já com as categorias padrão
e este operador:

```
E-mail : admin@financeiro.com
Senha  : 123456
```

---

## ▸ PARA GERAR OS INSTALADORES

O código já está pronto para todas as plataformas, mas **empacotar** cada uma
exige a ferramenta oficial daquele sistema. Rode `flutter doctor` para ver o
que falta na sua máquina.

### Android (arquivo `.apk` para instalar no celular)

1. Instale o [Android Studio](https://developer.android.com/studio)
2. Na primeira abertura, aceite instalar o **Android SDK**
3. Aceite as licenças: `flutter doctor --android-licenses`
4. Gere o arquivo:

```bash
cd app_flutter && flutter build apk --release
```

O `.apk` sai em `build/app/outputs/flutter-apk/app-release.apk`. Copie para o
celular e instale (é preciso permitir "instalar de fontes desconhecidas").

### Windows (arquivo `.exe`)

1. Instale o [Visual Studio](https://visualstudio.microsoft.com/downloads/)
   (a versão Community serve)
2. No instalador, marque a carga de trabalho **"Desenvolvimento para desktop
   com C++"**
3. Ative o **Modo de Desenvolvedor** do Windows (`ms-settings:developers`) —
   o Flutter precisa disso para criar links simbólicos dos plugins
4. Gere o executável:

```bash
cd app_flutter && flutter build windows --release
```

Sai em `build\windows\x64\runner\Release\`. A pasta inteira é o programa —
leve ela junto, não só o `.exe`.

### Web (site estático)

```bash
cd app_flutter && flutter build web
```

Sai em `build/web`. Para publicar numa subpasta, use
`--base-href "/caminho/da/subpasta/"`.

---

## ▸ ESTRUTURA DO PROJETO

A ideia é separar **o que é dado** de **o que é tela**, para que a lógica
financeira possa ser testada sem abrir o app.

```
app_flutter/
│
├── lib/
│   ├── main.dart                     → Abre o app e decide: login ou painel
│   │
│   ├── core/                         → Peças reaproveitadas por todas as telas
│   │   ├── theme/
│   │   │   ├── eva_palette.dart      → As 3 skins (cores vindas do custom.css)
│   │   │   └── app_theme.dart        → Monta o tema do Material a partir da skin
│   │   ├── utils/
│   │   │   ├── formatters.dart       → Dinheiro em real, datas, percentuais
│   │   │   └── responsive.dart       → Celular / tablet / computador
│   │   └── widgets/
│   │       └── eva_widgets.dart      → Cards, barras de progresso, alertas
│   │
│   ├── data/                         → Banco de dados e regras de negócio
│   │   ├── database/
│   │   │   ├── app_database.dart     → Cria as tabelas e os dados iniciais
│   │   │   ├── password_hasher.dart  → Guarda senhas com PBKDF2
│   │   │   ├── db_factory.dart       → Escolhe o motor conforme a plataforma
│   │   │   ├── db_factory_native.dart→ Celular e computador
│   │   │   └── db_factory_web.dart   → Navegador (SQLite em WebAssembly)
│   │   ├── models/
│   │   │   └── models.dart           → Usuario, Categoria, Transacao, Meta...
│   │   └── repositories/             → Todas as consultas ao banco
│   │       ├── auth_repository.dart
│   │       ├── categoria_repository.dart
│   │       ├── transacao_repository.dart
│   │       ├── meta_repository.dart
│   │       ├── recorrencia_repository.dart
│   │       ├── dashboard_repository.dart
│   │       └── regra_negocio.dart    → Erros de validação
│   │
│   ├── state/
│   │   └── app_state.dart            → Quem está logado e qual skin está ativa
│   │
│   └── features/                     → Uma pasta por tela
│       ├── auth/                     → Login, cadastro, fundo mecha animado
│       ├── shell/                    → Navegação (lateral ou inferior)
│       ├── dashboard/                → Painel principal
│       ├── transacoes/               → Listagem e formulário
│       ├── categorias/               → Listagem e formulário
│       ├── metas/                    → Cards, depósito e retirada
│       ├── recorrencias/             → Pendentes / lançadas / inativas
│       ├── relatorios/               → Gráficos por período
│       ├── perfil/                   → Conta, skin e zona de risco
│       └── shared/                   → Campos de formulário reaproveitados
│
├── test/                             → Testes automatizados
│   ├── password_hasher_test.dart
│   ├── formatters_test.dart
│   ├── categoria_dropdown_test.dart
│   └── repositories_test.dart
│
└── assets/fonts/                     → Orbitron e Share Tech Mono embutidas
```

---

## ▸ COMO O BANCO FOI TRADUZIDO

As tabelas são as mesmas do `database.sql`, adaptadas ao dialeto do SQLite:

| MySQL | SQLite |
|---|---|
| `INT AUTO_INCREMENT PRIMARY KEY` | `INTEGER PRIMARY KEY AUTOINCREMENT` |
| `ENUM('receita','despesa')` | `TEXT ... CHECK (tipo IN ('receita','despesa'))` |
| `DECIMAL(10,2)` | `REAL` |
| `DATE` | `TEXT` no formato `AAAA-MM-DD` |
| `DATE_FORMAT(data,'%Y-%m')` | `substr(data, 1, 7)` |

As datas ficam como texto `AAAA-MM-DD` de propósito: nesse formato a ordem
alfabética é a mesma da ordem cronológica, então `ORDER BY data` e as
comparações de período continuam funcionando.

O motor do SQLite muda conforme a plataforma, e a escolha acontece na hora de
compilar (`db_factory.dart`):

- **Android / iOS / macOS** → plugin nativo do `sqflite`
- **Windows / Linux** → `sqflite_common_ffi`
- **Web** → `sqflite_common_ffi_web`, que roda o SQLite compilado em
  WebAssembly e guarda os dados no IndexedDB do navegador

> Os arquivos `web/sqlite3.wasm` e `web/sqflite_sw.js` são gerados pelo
> comando `dart run sqflite_common_ffi_web:setup`. Se eles sumirem, rode esse
> comando de novo antes de compilar para web.

---

## ▸ SEGURANÇA

- Senhas guardadas com **PBKDF2-HMAC-SHA256**, 120 mil iterações e sal
  aleatório por senha (o equivalente em Dart ao `password_hash()` do PHP).
  A senha original nunca é gravada.
- Comparação de hash em tempo constante, para não vazar informação pela
  duração da verificação.
- Todas as consultas usam **parâmetros** (`?`), nunca texto concatenado —
  mesma proteção contra SQL Injection dos prepared statements do PDO.
- Toda consulta de transação, meta e recorrência filtra por `usuario_id`:
  um operador não lê nem apaga dado de outro.
- `PRAGMA foreign_keys = ON` ligado, para o `ON DELETE CASCADE` valer de fato.

---

## ▸ TESTES

```bash
cd app_flutter && flutter test
```

São 70 testes cobrindo as regras que importam: validações de cada formulário,
limite de depósito nas metas, bloqueio de categoria em uso, lançamento de
recorrência (inclusive vencimento dia 31 em fevereiro), cálculo dos alertas de
limite e montagem do painel e dos relatórios.

Para conferir o código sem rodar nada:

```bash
cd app_flutter && flutter analyze
```

---

## ▸ STACK UTILIZADA

| Camada | Tecnologia |
|---|---|
| Linguagem | Dart 3.13 |
| Framework | Flutter 3.47 |
| Banco local | SQLite (`sqflite`, `sqflite_common_ffi`, `..._ffi_web`) |
| Gráficos | `fl_chart` |
| Formatação pt-BR | `intl` |
| Preferências | `shared_preferences` |
| Criptografia | `crypto` (PBKDF2) |
| Tipografia | Orbitron + Share Tech Mono (embutidas, funcionam offline) |

---

```
// FIM DO DOCUMENTO
// NERV MAGI SYSTEM — VERSÃO APP
// ██████████████████████████████ 100%
```
