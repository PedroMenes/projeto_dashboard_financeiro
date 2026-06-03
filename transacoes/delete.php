<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../config/database.php';
requireLogin();

$user = currentUser();
$id   = (int)($_GET['id'] ?? 0);

$stmt = getDB()->prepare("DELETE FROM transacoes WHERE id = ? AND usuario_id = ?");
$stmt->execute([$id, $user['id']]);

header('Location: /projeto_dashboard_financeiro/transacoes/index.php?msg=excluida');
exit;
