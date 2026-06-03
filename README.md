```
███╗   ██╗███████╗██████╗ ██╗   ██╗
████╗  ██║██╔════╝██╔══██╗██║   ██║
██╔██╗ ██║█████╗  ██████╔╝██║   ██║
██║╚██╗██║██╔══╝  ██╔══██╗╚██╗ ██╔╝
██║ ╚████║███████╗██║  ██║ ╚████╔╝
╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝  ╚═══╝

// MAGI SYSTEM — CONTROLE FINANCEIRO
// CLASSIFICAÇÃO: OPERACIONAL
// VERSÃO: 1.0.0
```

---

> **"Humanos não são deuses. Mas com os dados certos, chegam perto."**
> — *NERV Financial Division*

---

## ▸ IDENTIFICAÇÃO DO SISTEMA

Sistema de **controle financeiro pessoal** desenvolvido em PHP com MySQL. Interface inspirada na estética da **Unidade Evangelion 01** — painel de controle da NERV, com fundo escuro, verde neon e tipografia sci-fi.

Funcionalidades:
- Autenticação de operadores (login / cadastro / logout)
- Dashboard com resumo mensal e gráfico de despesas por categoria
- CRUD completo de transações (receitas e despesas)
- Filtros por mês e tipo
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
├── 📄 login.php                  → Terminal de acesso
├── 📄 register.php               → Cadastro de novo operador
├── 📄 logout.php                 → Encerramento de sessão
├── 📄 dashboard.php              → Painel de controle principal
├── 📄 database.sql               → Script de criação do banco
│
├── 📁 transacoes/
│   ├── index.php                 → Listagem com filtros
│   ├── create.php                → Registro de nova transação
│   ├── edit.php                  → Edição de transação existente
│   └── delete.php                → Remoção de transação
│
├── 📁 config/
│   └── database.php              → Conexão PDO com o MySQL
│
├── 📁 includes/
│   ├── auth.php                  → Controle de sessão e autenticação
│   ├── header.php                → Cabeçalho HTML (fontes, CSS)
│   ├── navbar.php                → Barra de navegação
│   └── footer.php                → Rodapé + scripts JS
│
└── 📁 assets/
    └── css/
        └── custom.css            → Tema EVA-01 completo
```

---

## ▸ INSTALAÇÃO — PROTOCOLO DE ATIVAÇÃO

### 01 — Clonar o repositório

```bash
git clone https://github.com/pereiramouton/projeto_dashboard_financeiro.git
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
categorias   → id, nome, tipo (receita | despesa)
transacoes   → id, usuario_id, descricao, valor, tipo, categoria_id, data, created_at
```

Categorias padrão incluídas: Salário, Freelance, Investimentos, Alimentação, Moradia, Transporte, Saúde, Educação, Lazer e outros.

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
- Todas as rotas protegidas verificam autenticação

---

## ▸ CAPTURAS DE TELA

| Login | Dashboard | Transações |
|---|---|---|
| Terminal NERV | Painel com gráfico | Tabela com filtros |

---

```
// FIM DO DOCUMENTO
// NERV MAGI SYSTEM — TODOS OS DIREITOS RESERVADOS
// ██████████████████████████████ 100%
```
