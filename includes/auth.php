<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

function isLoggedIn(): bool {
    return isset($_SESSION['usuario_id']);
}

function requireLogin(): void {
    if (!isLoggedIn()) {
        header('Location: /projeto_dashboard_financeiro/login.php');
        exit;
    }
}

function currentUser(): array {
    return [
        'id'   => $_SESSION['usuario_id'] ?? null,
        'nome' => $_SESSION['usuario_nome'] ?? '',
    ];
}
