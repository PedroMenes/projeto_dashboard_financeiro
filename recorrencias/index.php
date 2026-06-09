<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../config/database.php';
requireLogin();

$pageTitle = 'Recorrências — Controle Financeiro';
$user = currentUser();
$db   = getDB();

$mensagem = $_GET['msg'] ?? '';
$mesAtual = date('Y-m');

$stmt = $db->prepare("
    SELECT r.*, c.nome AS categoria
    FROM recorrencias r
    LEFT JOIN categorias c ON c.id = r.categoria_id
    WHERE r.usuario_id = ?
    ORDER BY r.dia_vencimento ASC, r.descricao ASC
");
$stmt->execute([$user['id']]);
$todas = $stmt->fetchAll();

// Separa pendentes (não lançadas este mês) das já lançadas
$pendentes = array_filter($todas, fn($r) =>
    $r['ativa'] && (
        !$r['ultimo_lancamento'] ||
        date('Y-m', strtotime($r['ultimo_lancamento'])) !== $mesAtual
    )
);
$lancadas = array_filter($todas, fn($r) =>
    $r['ultimo_lancamento'] &&
    date('Y-m', strtotime($r['ultimo_lancamento'])) === $mesAtual
);
$inativas = array_filter($todas, fn($r) => !$r['ativa']);

include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';
?>

<main class="py-4">
<div class="container-fluid px-4">

    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h1 class="page-title mb-0">Transações Recorrentes</h1>
            <p class="page-subtitle mb-0">Contas fixas — <?= date('m/Y') ?></p>
        </div>
        <a href="/projeto_dashboard_financeiro/recorrencias/create.php" class="btn btn-primary">
            <i class="bi bi-plus me-1"></i>Nova Recorrência
        </a>
    </div>

    <?php if ($mensagem === 'criada'): ?>
        <div class="alert alert-success alert-dismissible fade show d-flex align-items-center gap-2">
            <i class="bi bi-check-circle-fill"></i> Recorrência criada!
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php elseif ($mensagem === 'lancada'): ?>
        <div class="alert alert-success alert-dismissible fade show d-flex align-items-center gap-2">
            <i class="bi bi-check-circle-fill"></i> Transação lançada com sucesso!
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php elseif ($mensagem === 'excluida'): ?>
        <div class="alert alert-warning alert-dismissible fade show d-flex align-items-center gap-2">
            <i class="bi bi-trash-fill"></i> Recorrência excluída.
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php endif; ?>

    <!-- Pendentes -->
    <?php if (!empty($pendentes)): ?>
    <div class="alert d-flex align-items-center gap-2 mb-4"
         style="background:rgba(251,191,36,0.08);border-color:rgba(251,191,36,0.3);color:var(--eva-yellow);">
        <i class="bi bi-exclamation-triangle-fill fs-5"></i>
        <span><?= count($pendentes) ?> recorrência(s) pendente(s) para <?= date('m/Y') ?> — clique em <strong>Lançar</strong> para registrar.</span>
    </div>
    <?php endif; ?>

    <?php
    $secoes = [
        ['titulo' => 'Pendentes este mês',  'icone' => 'clock-history',  'cor' => 'var(--eva-yellow)',       'dados' => $pendentes],
        ['titulo' => 'Lançadas este mês',   'icone' => 'check-circle',   'cor' => 'var(--eva-green)',        'dados' => $lancadas],
        ['titulo' => 'Inativas',            'icone' => 'pause-circle',   'cor' => 'var(--eva-text-muted)',   'dados' => $inativas],
    ];
    foreach ($secoes as $secao):
        if (empty($secao['dados'])) continue;
    ?>
    <div class="card mb-4">
        <div class="card-header px-3 py-3">
            <p class="page-title mb-0" style="font-size:0.9rem;color:<?= $secao['cor'] ?>;">
                <i class="bi bi-<?= $secao['icone'] ?> me-2"></i><?= $secao['titulo'] ?>
                <span class="page-subtitle ms-2">(<?= count($secao['dados']) ?>)</span>
            </p>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead>
                        <tr>
                            <th class="ps-3">Descrição</th>
                            <th>Categoria</th>
                            <th>Tipo</th>
                            <th>Vencimento</th>
                            <th class="text-end">Valor</th>
                            <th class="text-center pe-3">Ações</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($secao['dados'] as $r): ?>
                        <tr>
                            <td class="ps-3 fw-semibold"><?= htmlspecialchars($r['descricao']) ?></td>
                            <td class="col-categoria"><?= htmlspecialchars($r['categoria'] ?? '—') ?></td>
                            <td>
                                <span class="tipo-tag <?= $r['tipo'] ?>">
                                    <?= $r['tipo'] === 'receita' ? '↓ ENTRADA' : '↑ SAÍDA' ?>
                                </span>
                            </td>
                            <td class="col-data">DIA <?= str_pad($r['dia_vencimento'], 2, '0', STR_PAD_LEFT) ?></td>
                            <td class="text-end fw-bold <?= $r['tipo'] === 'receita' ? 'text-success' : 'text-danger' ?>">
                                <?= $r['tipo'] === 'receita' ? '+' : '-' ?>
                                R$ <?= number_format($r['valor'], 2, ',', '.') ?>
                            </td>
                            <td class="text-center pe-3">
                                <div class="d-flex gap-1 justify-content-center">
                                    <?php if ($r['ativa'] && (
                                        !$r['ultimo_lancamento'] ||
                                        date('Y-m', strtotime($r['ultimo_lancamento'])) !== $mesAtual
                                    )): ?>
                                    <a href="/projeto_dashboard_financeiro/recorrencias/lancar.php?id=<?= $r['id'] ?>"
                                       class="btn btn-sm btn-primary" title="Lançar este mês">
                                        <i class="bi bi-send"></i>
                                    </a>
                                    <?php endif; ?>
                                    <a href="/projeto_dashboard_financeiro/recorrencias/edit.php?id=<?= $r['id'] ?>"
                                       class="btn btn-sm btn-outline-secondary" title="Editar">
                                        <i class="bi bi-pencil"></i>
                                    </a>
                                    <button class="btn btn-sm btn-outline-danger" title="Excluir"
                                            data-bs-toggle="modal" data-bs-target="#modalExcluir"
                                            data-id="<?= $r['id'] ?>" data-desc="<?= htmlspecialchars($r['descricao']) ?>">
                                        <i class="bi bi-trash"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    <?php endforeach; ?>

    <?php if (empty($todas)): ?>
    <div class="card">
        <div class="card-body text-center py-5">
            <i class="bi bi-arrow-repeat fs-1 opacity-25 d-block mb-3"></i>
            <p class="page-subtitle mb-3">Nenhuma recorrência cadastrada ainda.</p>
            <a href="/projeto_dashboard_financeiro/recorrencias/create.php" class="btn btn-primary">
                <i class="bi bi-plus me-1"></i>Criar primeira recorrência
            </a>
        </div>
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
                Excluir a recorrência <strong id="modalDesc"></strong>?
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
    document.getElementById('modalDesc').textContent = btn.dataset.desc;
    document.getElementById('btnConfirmar').href =
        '/projeto_dashboard_financeiro/recorrencias/delete.php?id=' + btn.dataset.id;
});
</script>
