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

-- Tabela de categorias (ex: Alimentação, Salário, Transporte...)
CREATE TABLE IF NOT EXISTS categorias (
    id    INT AUTO_INCREMENT PRIMARY KEY,
    nome  VARCHAR(100) NOT NULL,
    tipo  ENUM('receita', 'despesa') NOT NULL
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

-- Categorias padrão
INSERT INTO categorias (nome, tipo) VALUES
    ('Salário',        'receita'),
    ('Freelance',      'receita'),
    ('Investimentos',  'receita'),
    ('Outros (entrada)','receita'),
    ('Alimentação',    'despesa'),
    ('Moradia',        'despesa'),
    ('Transporte',     'despesa'),
    ('Saúde',          'despesa'),
    ('Educação',       'despesa'),
    ('Lazer',          'despesa'),
    ('Outros (saída)', 'despesa');

-- Usuário de demonstração (senha: 123456)
INSERT INTO usuarios (nome, email, senha) VALUES
    ('Administrador', 'admin@financeiro.com', '$2y$10$r8JndYMHqyj9bokVaV.8mOxbnEOp1ZLLUfGGbnl9E4JThsnp8ulNO');
