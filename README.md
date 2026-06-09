```
███╗   ██╗███████╗██████╗ ██╗   ██╗
████╗  ██║██╔════╝██╔══██╗██║   ██║
██╔██╗ ██║█████╗  ██████╔╝██║   ██║
██║╚██╗██║██╔══╝  ██╔══██╗╚██╗ ██╔╝
██║ ╚████║███████╗██║  ██║ ╚████╔╝
╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝  ╚═══╝

// MAGI SYSTEM — CONTROLE FINANCEIRO
// CLASSIFICAÇÃO: OPERACIONAL
// VERSÃO: 3.0.0
```

---

> **"Humanos não são deuses. Mas com os dados certos, chegam perto."**
> — *NERV Financial Division*

---

## ▸ IDENTIFICAÇÃO DO SISTEMA

Sistema de **controle financeiro pessoal** desenvolvido em PHP com MySQL. Interface inspirada na estética da **Unidade Evangelion 01** — painel de controle da NERV, com fundo escuro, verde neon e tipografia sci-fi.

Funcionalidades:
- Autenticação de operadores (login / cadastro / logout)
- Dashboard com resumo mensal, alertas de limite e widgets de metas
- **CRUD completo de Transações** (receitas e despesas)
- **CRUD completo de Categorias** com limite mensal configurável
- **CRUD completo de Usuários** via página de perfil
- **CRUD completo de Metas Financeiras** com depósitos e barra de progresso
- **CRUD completo de Transações Recorrentes** com lançamento mensal
- **Relatórios por período** com gráficos comparativos (3, 6 ou 12 meses)
- Alertas automáticos de limite de categoria (80% / 100%)
- Animação de painel mecha na tela de login
- Design responsivo (mobile e desktop)

---

## ▸ REQUISITOS DO SISTEMA

| Componente | Versão mínima | Observação |
|---|---|---|
| **PHP** | 8.1+ | PDO e extensão `pdo_mysql` habilitados |
| **MySQL** | 5.7+ ou MariaDB 10.3+ | Suporte a `utf8mb4` |
| **XAMPP** | 8.x recomendado | Apache + MySQL + PHP juntos |
| **Navegador** | Qualquer moderno | Chrome, Firefox, Edge, Safari |
| **Conexão** | Internet (CDN) | Bootstrap 5, Orbitron font, Chart.js via CDN |

---

## ▸ ESTRUTURA DO PROJETO

```
projeto_dashboard_financeiro/
│
├── 📄 index.php                  → Porta de entrada (redireciona)
├── 📄 login.php                  → Terminal de acesso (com animação mecha)
├── 📄 register.php               → Cadastro de novo operador
├── 📄 logout.php                 → Encerramento de sessão
├── 📄 dashboard.php              → Painel de controle principal
├── 📄 perfil.php                 → Perfil do usuário (editar / excluir conta)
├── 📄 relatorios.php             → Relatórios por período com gráficos
├── 📄 database.sql               → Script de criação do banco de dados
│
├── 📁 transacoes/
│   ├── index.php                 → Listagem com filtros
│   ├── create.php                → Registro de nova transação
│   ├── edit.php                  → Edição de transação existente
│   └── delete.php                → Remoção de transação
│
├── 📁 categorias/
│   ├── index.php                 → Listagem com uso vs limite mensal
│   ├── create.php                → Nova categoria
│   ├── edit.php                  → Edição + configuração de limite
│   └── delete.php                → Remoção (bloqueada se em uso)
│
├── 📁 metas/
│   ├── index.php                 → Cards de metas com progresso
│   ├── create.php                → Nova meta
│   ├── edit.php                  → Edição de meta
│   ├── delete.php                → Remoção de meta
│   └── depositar.php             → Registrar depósito na meta
│
├── 📁 recorrencias/
│   ├── index.php                 → Listagem: pendentes / lançadas / inativas
│   ├── create.php                → Nova recorrência
│   ├── edit.php                  → Edição de recorrência
│   ├── delete.php                → Remoção de recorrência
│   └── lancar.php                → Lança como transação no mês atual
│
├── 📁 config/
│   └── database.php              → Conexão PDO com o MySQL
│
├── 📁 includes/
│   ├── auth.php                  → Controle de sessão e autenticação
│   ├── header.php                → Cabeçalho HTML (fontes, CSS)
│   ├── navbar.php                → Barra de navegação responsiva
│   └── footer.php                → Rodapé + scripts JS
│
└── 📁 assets/
    └── css/
        └── custom.css            → Tema EVA-01 completo
```

---

## ▸ CRUDs IMPLEMENTADOS

| Operação | Usuários | Transações | Categorias | Metas | Recorrências |
|---|---|---|---|---|---|
| **Create** | `register.php` | `transacoes/create.php` | `categorias/create.php` | `metas/create.php` | `recorrencias/create.php` |
| **Read** | `perfil.php` | `transacoes/index.php` | `categorias/index.php` | `metas/index.php` | `recorrencias/index.php` |
| **Update** | `perfil.php` | `transacoes/edit.php` | `categorias/edit.php` | `metas/edit.php` | `recorrencias/edit.php` |
| **Delete** | `perfil.php` | `transacoes/delete.php` | `categorias/delete.php` | `metas/delete.php` | `recorrencias/delete.php` |

---

## ▸ INSTALAÇÃO — PROTOCOLO DE ATIVAÇÃO

### 01 — Clonar o repositório

```bash
git clone https://github.com/PedroMenes/projeto_dashboard_financeiro.git
```

Mova a pasta para dentro do diretório raiz do XAMPP:

```
C:\xampp\htdocs\projeto_dashboard_financeiro\
```

### 02 — Iniciar serviços

Abra o **XAMPP Control Panel** e inicie:
- ✅ Apache
- ✅ MySQL

### 03 — Criar o banco de dados

1. Acesse `http://localhost/phpmyadmin`
2. Clique na aba **SQL**
3. Cole o conteúdo do arquivo `database.sql` e clique em **Executar**

### 04 — Acessar o sistema

```
http://localhost/projeto_dashboard_financeiro
```

### 05 — Credenciais de demonstração

```
ID do Operador : admin@financeiro.com
Código         : 123456
```

---

## ▸ BANCO DE DADOS — ESTRUTURA

```sql
usuarios     → id, nome, email, senha, created_at
categorias   → id, nome, tipo (receita | despesa), limite_mensal
transacoes   → id, usuario_id, descricao, valor, tipo, categoria_id, data, created_at
metas        → id, usuario_id, nome, descricao, valor_alvo, valor_atual, prazo, created_at
recorrencias → id, usuario_id, descricao, valor, tipo, categoria_id, dia_vencimento, ativa, ultimo_lancamento, created_at
```

Categorias padrão incluídas com limites mensais pré-configurados: Alimentação (R$ 800), Moradia (R$ 1.500), Transporte (R$ 400), Saúde (R$ 300), Educação (R$ 500), Lazer (R$ 300).

---

## ▸ STACK UTILIZADA

| Camada | Tecnologia |
|---|---|
| Backend | PHP 8.1+ (PDO, Sessions, password_hash) |
| Banco de dados | MySQL / MariaDB |
| Frontend | Bootstrap 5.3 |
| Tipografia | Orbitron + Share Tech Mono (Google Fonts) |
| Gráficos | Chart.js 4.4 |
| Ícones | Bootstrap Icons 1.11 |
| Servidor local | XAMPP (Apache) |

---

## ▸ SEGURANÇA

- Senhas armazenadas com `password_hash()` (bcrypt)
- Queries com **PDO Prepared Statements** (proteção contra SQL Injection)
- Dados de saída escapados com `htmlspecialchars()` (proteção contra XSS)
- Regeneração de ID de sessão no login
- Exclusão de categoria bloqueada quando vinculada a transações
- Todas as rotas protegidas verificam autenticação

---

```
// FIM DO DOCUMENTO
// NERV MAGI SYSTEM — TODOS OS DIREITOS RESERVADOS
// ██████████████████████████████ 100%
```
