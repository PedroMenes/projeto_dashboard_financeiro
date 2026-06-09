-- =============================================================
-- CONTROLE FINANCEIRO — Script de criação do banco de dados
-- Execute este arquivo no phpMyAdmin (aba SQL)
-- =============================================================

CREATE DATABASE IF NOT EXISTS financeiro CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE financeiro;

-- Tabela de usuários do sistema
CREATE TABLE IF NOT EXISTS usuarios (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    nome        VARCHAR(100)  NOT NULL,
    email       VARCHAR(150)  NOT NULL UNIQUE,
    senha       VARCHAR(255)  NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de categorias (com limite mensal opcional)
CREATE TABLE IF NOT EXISTS categorias (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    nome          VARCHAR(100)   NOT NULL,
    tipo          ENUM('receita', 'despesa') NOT NULL,
    limite_mensal DECIMAL(10,2)  DEFAULT NULL
);

-- Tabela de transações financeiras
CREATE TABLE IF NOT EXISTS transacoes (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id   INT            NOT NULL,
    descricao    VARCHAR(255)   NOT NULL,
    valor        DECIMAL(10,2)  NOT NULL,
    tipo         ENUM('receita', 'despesa') NOT NULL,
    categoria_id INT            DEFAULT NULL,
    data         DATE           NOT NULL,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id)   REFERENCES usuarios(id)   ON DELETE CASCADE,
    FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE SET NULL
);

-- Tabela de metas financeiras
CREATE TABLE IF NOT EXISTS metas (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id  INT            NOT NULL,
    nome        VARCHAR(150)   NOT NULL,
    descricao   VARCHAR(255)   DEFAULT NULL,
    valor_alvo  DECIMAL(10,2)  NOT NULL,
    valor_atual DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    prazo       DATE           DEFAULT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- Tabela de transações recorrentes
CREATE TABLE IF NOT EXISTS recorrencias (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id        INT            NOT NULL,
    descricao         VARCHAR(255)   NOT NULL,
    valor             DECIMAL(10,2)  NOT NULL,
    tipo              ENUM('receita','despesa') NOT NULL,
    categoria_id      INT            DEFAULT NULL,
    dia_vencimento    TINYINT        NOT NULL,
    ativa             TINYINT(1)     NOT NULL DEFAULT 1,
    ultimo_lancamento DATE           DEFAULT NULL,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id)   REFERENCES usuarios(id)   ON DELETE CASCADE,
    FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE SET NULL
);

-- Categorias padrão
INSERT INTO categorias (nome, tipo, limite_mensal) VALUES
    ('Salário',         'receita', NULL),
    ('Freelance',       'receita', NULL),
    ('Investimentos',   'receita', NULL),
    ('Outros (entrada)','receita', NULL),
    ('Alimentação',     'despesa', 800.00),
    ('Moradia',         'despesa', 1500.00),
    ('Transporte',      'despesa', 400.00),
    ('Saúde',           'despesa', 300.00),
    ('Educação',        'despesa', 500.00),
    ('Lazer',           'despesa', 300.00),
    ('Outros (saída)',  'despesa', NULL);

-- Usuário de demonstração (senha: 123456)
INSERT INTO usuarios (nome, email, senha) VALUES
    ('Administrador', 'admin@financeiro.com', '$2y$10$r8JndYMHqyj9bokVaV.8mOxbnEOp1ZLLUfGGbnl9E4JThsnp8ulNO');
