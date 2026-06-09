<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../config/database.php';
requireLogin();

$id   = (int)($_GET['id'] ?? 0);
$user = currentUser();
$db   = getDB();

$stmt = $db->prepare("SELECT * FROM recorrencias WHERE id = ? AND usuario_id = ? AND ativa = 1");
$stmt->execute([$id, $user['id']]);
$rec = $stmt->fetch();

if (!$rec) { header('Location: /projeto_dashboard_financeiro/recorrencias/index.php'); exit; }

// Monta a data usando o dia de vencimento no mês atual
$dia = $rec['dia_vencimento'];
$ultimoDia = (int)date('t'); // último dia do mês atual
$dia = min($dia, $ultimoDia);
$data = date('Y-m-') . str_pad($dia, 2, '0', STR_PAD_LEFT);

// Cria a transação
$db->prepare("INSERT INTO transacoes (usuario_id, descricao, valor, tipo, categoria_id, data) VALUES (?,?,?,?,?,?)")
   ->execute([$user['id'], $rec['descricao'], $rec['valor'], $rec['tipo'], $rec['categoria_id'], $data]);

// Atualiza o último lançamento
$db->prepare("UPDATE recorrencias SET ultimo_lancamento = ? WHERE id = ?")
   ->execute([date('Y-m-d'), $id]);

header('Location: /projeto_dashboard_financeiro/recorrencias/index.php?msg=lancada');
exit;
