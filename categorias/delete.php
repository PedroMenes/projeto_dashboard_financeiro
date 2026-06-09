<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../config/database.php';
requireLogin();

$id = (int)($_GET['id'] ?? 0);
$db = getDB();

// Verifica se a categoria está vinculada a alguma transação
$chk = $db->prepare("SELECT COUNT(*) FROM transacoes WHERE categoria_id = ?");
$chk->execute([$id]);
$emUso = (int)$chk->fetchColumn();

if ($emUso > 0) {
    header('Location: /projeto_dashboard_financeiro/categorias/index.php?msg=em_uso');
    exit;
}

$db->prepare("DELETE FROM categorias WHERE id = ?")->execute([$id]);

header('Location: /projeto_dashboard_financeiro/categorias/index.php?msg=excluida');
exit;
