<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../config/database.php';
requireLogin();

$pageTitle = 'Depositar — Controle Financeiro';
$user = currentUser();
$db   = getDB();

$id = (int)($_GET['id'] ?? 0);
$stmt = $db->prepare("SELECT * FROM metas WHERE id = ? AND usuario_id = ?");
$stmt->execute([$id, $user['id']]);
$meta = $stmt->fetch();

if (!$meta) { header('Location: /projeto_dashboard_financeiro/metas/index.php'); exit; }

$falta = max($meta['valor_alvo'] - $meta['valor_atual'], 0);
$erros = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $valor = $_POST['valor'] ?? '';

    if (!is_numeric($valor) || $valor <= 0)
        $erros[] = 'Informe um valor válido maior que zero.';
    elseif ($meta['valor_atual'] + $valor > $meta['valor_alvo'])
        $erros[] = 'O depósito ultrapassa o valor alvo. Máximo permitido: R$ ' . number_format($falta, 2, ',', '.');

    if (empty($erros)) {
        $novo = $meta['valor_atual'] + $valor;
        $db->prepare("UPDATE metas SET valor_atual = ? WHERE id = ? AND usuario_id = ?")
           ->execute([$novo, $id, $user['id']]);
        header('Location: /projeto_dashboard_financeiro/metas/index.php?msg=deposito');
        exit;
    }
}

include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';

$pct = $meta['valor_alvo'] > 0 ? min(($meta['valor_atual'] / $meta['valor_alvo']) * 100, 100) : 0;
?>

<main class="py-4">
<div class="container" style="max-width:520px;">

    <div class="mb-4">
        <a href="/projeto_dashboard_financeiro/metas/index.php"
           class="text-decoration-none page-subtitle d-inline-flex align-items-center gap-1 mb-2">
            <i class="bi bi-arrow-left" style="font-size:0.75rem;"></i>Metas
        </a>
        <h1 class="page-title mb-0">Depositar na Meta</h1>
    </div>

    <!-- Card resumo da meta -->
    <div class="card mb-4">
        <div class="card-body p-4">
            <p class="page-title mb-1" style="font-size:0.9rem;color:var(--eva-purple-light);">
                <?= htmlspecialchars($meta['nome']) ?>
            </p>
            <div class="d-flex justify-content-between mb-2">
                <span class="page-subtitle" style="font-size:0.7rem;">
                    R$ <?= number_format($meta['valor_atual'], 2, ',', '.') ?> acumulado
                </span>
                <span class="page-subtitle" style="font-size:0.7rem;">
                    Meta: R$ <?= number_format($meta['valor_alvo'], 2, ',', '.') ?>
                </span>
            </div>
            <div class="meta-progress-track">
                <div class="meta-progress-fill" style="width:<?= $pct ?>%;"></div>
            </div>
            <p class="page-subtitle mt-2 mb-0" style="font-size:0.7rem;">
                Faltam <strong style="color:var(--eva-green);">R$ <?= number_format($falta, 2, ',', '.') ?></strong> para atingir a meta
            </p>
        </div>
    </div>

    <?php if (!empty($erros)): ?>
        <div class="alert alert-danger">
            <ul class="mb-0 ps-3">
                <?php foreach ($erros as $e): ?><li><?= htmlspecialchars($e) ?></li><?php endforeach; ?>
            </ul>
        </div>
    <?php endif; ?>

    <div class="card form-card shadow-sm">
        <div class="card-body p-4">
            <form method="POST" novalidate>
                <div class="mb-4">
                    <label for="valor" class="form-label fw-semibold">Valor do Depósito (R$)</label>
                    <div class="input-group">
                        <span class="input-group-text">R$</span>
                        <input type="number" id="valor" name="valor" class="form-control"
                               placeholder="0,00" step="0.01" min="0.01"
                               max="<?= $falta ?>" required autofocus>
                    </div>
                    <small class="page-subtitle" style="font-size:0.68rem;">
                        Máximo: R$ <?= number_format($falta, 2, ',', '.') ?>
                    </small>
                </div>

                <div class="d-flex gap-2">
                    <button type="submit" class="btn btn-primary px-4">
                        <i class="bi bi-piggy-bank me-2"></i>Confirmar Depósito
                    </button>
                    <a href="/projeto_dashboard_financeiro/metas/index.php" class="btn btn-outline-secondary">Cancelar</a>
                </div>
            </form>
        </div>
    </div>
</div>
</main>

<?php include __DIR__ . '/../includes/footer.php'; ?>
