<?php
require_once __DIR__ . '/tema.php';
$tema = getTema();
?>
<!DOCTYPE html>
<html lang="pt-BR" data-bs-theme="<?= htmlspecialchars(getBsTheme()) ?>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= htmlspecialchars($pageTitle ?? 'NERV — Controle Financeiro') ?></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;500;600;700;900&family=Share+Tech+Mono&display=swap" rel="stylesheet">
    <link href="/projeto_dashboard_financeiro/assets/css/custom.css" rel="stylesheet">
</head>
<body class="tema-<?= htmlspecialchars($tema) ?>">
