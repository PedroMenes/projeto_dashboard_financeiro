<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../config/database.php';
requireLogin();

$pageTitle = 'Metas — Controle Financeiro';
$user = currentUser();
$db   = getDB();

$mensagem = $_GET['msg'] ?? '';

$stmt = $db->prepare("SELECT * FROM metas WHERE usuario_id = ? ORDER BY created_at DESC");
$stmt->execute([$user['id']]);
$metas = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';
?>

<main class="py-4">
<div class="container-fluid px-4">

    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h1 class="page-title mb-0">Metas Financeiras</h1>
            <p class="page-subtitle mb-0">Acompanhe seus objetivos de economia</p>
        </div>
        <a href="/projeto_dashboard_financeiro/metas/create.php" class="btn btn-primary">
            <i class="bi bi-plus me-1"></i>Nova Meta
        </a>
    </div>

    <?php if ($mensagem === 'criada'): ?>
        <div class="alert alert-success alert-dismissible fade show d-flex align-items-center gap-2">
            <i class="bi bi-check-circle-fill"></i> Meta criada com sucesso!
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php elseif ($mensagem === 'editada'): ?>
        <div class="alert alert-success alert-dismissible fade show d-flex align-items-center gap-2">
            <i class="bi bi-check-circle-fill"></i> Meta atualizada com sucesso!
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php elseif ($mensagem === 'excluida'): ?>
        <div class="alert alert-warning alert-dismissible fade show d-flex align-items-center gap-2">
            <i class="bi bi-trash-fill"></i> Meta excluída.
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php elseif ($mensagem === 'deposito'): ?>
        <div class="alert alert-success alert-dismissible fade show d-flex align-items-center gap-2">
            <i class="bi bi-piggy-bank-fill"></i> Depósito registrado com sucesso!
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php endif; ?>

    <?php if (empty($metas)): ?>
        <div class="card">
            <div class="card-body text-center py-5">
                <i class="bi bi-bullseye fs-1 opacity-25 d-block mb-3"></i>
                <p class="page-subtitle mb-3">Nenhuma meta cadastrada ainda.</p>
                <a href="/projeto_dashboard_financeiro/metas/create.php" class="btn btn-primary">
                    <i class="bi bi-plus me-1"></i>Criar primeira meta
                </a>
            </div>
        </div>
    <?php else: ?>
        <div class="row g-4">
            <?php foreach ($metas as $meta):
                $pct     = $meta['valor_alvo'] > 0 ? min(($meta['valor_atual'] / $meta['valor_alvo']) * 100, 100) : 0;
                $concluida = $pct >= 100;
                $falta   = max($meta['valor_alvo'] - $meta['valor_atual'], 0);
                $vencida = $meta['prazo'] && $meta['prazo'] < date('Y-m-d') && !$concluida;

                if ($concluida)     $cor = 'var(--eva-green)';
                elseif ($pct >= 75) $cor = 'var(--eva-yellow)';
                elseif ($vencida)   $cor = 'var(--eva-red)';
                else                $cor = 'var(--eva-purple-light)';
            ?>
            <div class="col-12 col-md-6 col-xl-4">
                <div class="card meta-card h-100" style="border-color: <?= $cor ?> !important;">
                    <div class="card-body p-4">

                        <div class="d-flex justify-content-between align-items-start mb-3">
                            <div>
                                <p class="page-title mb-0" style="font-size:0.9rem;color:<?= $cor ?>;">
                                    <?= htmlspecialchars($meta['nome']) ?>
                                </p>
                                <?php if ($meta['descricao']): ?>
                                    <p class="page-subtitle mb-0" style="font-size:0.72rem;">
                                        <?= htmlspecialchars($meta['descricao']) ?>
                                    </p>
                                <?php endif; ?>
                            </div>
                            <?php if ($concluida): ?>
                                <span class="badge" style="background:rgba(57,255,20,0.15);color:var(--eva-green);font-size:0.65rem;">
                                    <i class="bi bi-check-lg me-1"></i>CONCLUÍDA
                                </span>
                            <?php elseif ($vencida): ?>
                                <span class="badge" style="background:rgba(239,68,68,0.15);color:var(--eva-red);font-size:0.65rem;">
                                    <i class="bi bi-exclamation-triangle me-1"></i>VENCIDA
                                </span>
                            <?php endif; ?>
                        </div>

                        <!-- Barra de progresso -->
                        <div class="mb-3">
                            <div class="d-flex justify-content-between mb-1">
                                <span class="page-subtitle" style="font-size:0.68rem;">PROGRESSO</span>
                                <span style="font-family:'Share Tech Mono',monospace;font-size:0.8rem;color:<?= $cor ?>;">
                                    <?= number_format($pct, 1) ?>%
                                </span>
                            </div>
                            <div class="meta-progress-track">
                                <div class="meta-progress-fill" style="width:<?= $pct ?>%;background:<?= $cor ?>;box-shadow:0 0 8px <?= $cor ?>;"></div>
                            </div>
                        </div>

                        <!-- Valores -->
                        <div class="d-flex justify-content-between mb-3">
                            <div>
                                <p class="page-subtitle mb-0" style="font-size:0.65rem;">ACUMULADO</p>
                                <p class="mb-0" style="font-family:'Share Tech Mono',monospace;color:<?= $cor ?>;font-size:0.95rem;">
                                    R$ <?= number_format($meta['valor_atual'], 2, ',', '.') ?>
                                </p>
                            </div>
                            <div class="text-end">
                                <p class="page-subtitle mb-0" style="font-size:0.65rem;">OBJETIVO</p>
                                <p class="mb-0" style="font-family:'Share Tech Mono',monospace;color:var(--eva-text);font-size:0.95rem;">
                                    R$ <?= number_format($meta['valor_alvo'], 2, ',', '.') ?>
                                </p>
                            </div>
                        </div>

                        <?php if (!$concluida): ?>
                        <p class="page-subtitle mb-3" style="font-size:0.7rem;">
                            FALTAM <span style="color:<?= $cor ?>;">R$ <?= number_format($falta, 2, ',', '.') ?></span>
                            <?php if ($meta['prazo']): ?>
                                &nbsp;//&nbsp; PRAZO: <span style="color:var(--eva-amber, #fbbf24);"><?= date('d/m/Y', strtotime($meta['prazo'])) ?></span>
                            <?php endif; ?>
                        </p>
                        <?php else: ?>
                        <p class="page-subtitle mb-3" style="font-size:0.7rem;color:var(--eva-green);">
                            <i class="bi bi-trophy-fill me-1"></i> META ATINGIDA!
                        </p>
                        <?php endif; ?>

                        <!-- Ações -->
                        <div class="d-flex gap-2">
                            <?php if (!$concluida): ?>
                            <a href="/projeto_dashboard_financeiro/metas/depositar.php?id=<?= $meta['id'] ?>"
                               class="btn btn-sm btn-primary flex-fill">
                                <i class="bi bi-piggy-bank me-1"></i>Depositar
                            </a>
                            <?php endif; ?>
                            <a href="/projeto_dashboard_financeiro/metas/edit.php?id=<?= $meta['id'] ?>"
                               class="btn btn-sm btn-outline-secondary" title="Editar">
                                <i class="bi bi-pencil"></i>
                            </a>
                            <button type="button" class="btn btn-sm btn-outline-danger" title="Excluir"
                                    data-bs-toggle="modal" data-bs-target="#modalExcluir"
                                    data-id="<?= $meta['id'] ?>" data-nome="<?= htmlspecialchars($meta['nome']) ?>">
                                <i class="bi bi-trash"></i>
                            </button>
                        </div>

                    </div>
                </div>
            </div>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>

</div>
</main>

<!-- Modal exclusão -->
<div class="modal fade" id="modalExcluir" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header border-0">
                <h5 class="modal-title fw-bold text-danger">
                    <i class="bi bi-exclamation-triangle me-2"></i>Confirmar Exclusão
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                Excluir a meta <strong id="modalNome"></strong>? Esta ação não pode ser desfeita.
            </div>
            <div class="modal-footer border-0">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                <a id="btnConfirmar" href="#" class="btn btn-danger">
                    <i class="bi bi-trash me-2"></i>Excluir
                </a>
            </div>
        </div>
    </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>

<script>
document.getElementById('modalExcluir').addEventListener('show.bs.modal', function(e) {
    const btn = e.relatedTarget;
    document.getElementById('modalNome').textContent = btn.dataset.nome;
    document.getElementById('btnConfirmar').href =
        '/projeto_dashboard_financeiro/metas/delete.php?id=' + btn.dataset.id;
});
</script>
