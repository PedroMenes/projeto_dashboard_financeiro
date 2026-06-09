<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../config/database.php';
requireLogin();

$id   = (int)($_GET['id'] ?? 0);
$user = currentUser();
$db   = getDB();

$db->prepare("DELETE FROM recorrencias WHERE id = ? AND usuario_id = ?")->execute([$id, $user['id']]);

header('Location: /projeto_dashboard_financeiro/recorrencias/index.php?msg=excluida');
exit;
