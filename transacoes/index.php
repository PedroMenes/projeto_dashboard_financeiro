<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../config/database.php';
requireLogin();

$pageTitle = 'Transações — Controle Financeiro';
$user = currentUser();
$db   = getDB();

// Filtros
$filtroTipo = $_GET['tipo'] ?? '';
$filtroMes  = $_GET['mes']  ?? date('Y-m');

$condicoes = ['t.usuario_id = ?'];
$params    = [$user['id']];

if ($filtroTipo) {
    $condicoes[] = 't.tipo = ?';
    $params[]    = $filtroTipo;
}
if ($filtroMes) {
    $condicoes[] = "DATE_FORMAT(t.data, '%Y-%m') = ?";
    $params[]    = $filtroMes;
}

$where = implode(' AND ', $condicoes);

$stmt = $db->prepare("
    SELECT t.id, t.descricao, t.valor, t.tipo, t.data, c.nome AS categoria
    FROM transacoes t
    LEFT JOIN categorias c ON c.id = t.categoria_id
    WHERE {$where}
    ORDER BY t.data DESC, t.id DESC
");
$stmt->execute($params);
$transacoes = $stmt->fetchAll();

// Totais filtrados
$stmtTot = $db->prepare("
    SELECT
        COALESCE(SUM(CASE WHEN tipo = 'receita' THEN valor END), 0) AS receitas,
        COALESCE(SUM(CASE WHEN tipo = 'despesa' THEN valor END), 0) AS despesas
    FROM transacoes t
    WHERE {$where}
");
$stmtTot->execute($params);
$totais = $stmtTot->fetch();

$mensagem = $_GET['msg'] ?? '';

include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';
?>

<main class="py-4">
<div class="container-fluid px-4">

    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h1 class="page-title mb-0">Transações</h1>
            <p class="page-subtitle mb-0">Gerencie suas entradas e saídas</p>
        </div>
        <a href="/projeto_dashboard_financeiro/transacoes/create.php" class="btn btn-primary">
            <i class="bi bi-plus me-1"></i>Nova Transação
        </a>
    </div>

    <?php if ($mensagem === 'criada'): ?>
        <div class="alert alert-success alert-dismissible fade show d-flex align-items-center gap-2">
            <i class="bi bi-check-circle-fill"></i> Transação criada com sucesso!
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php elseif ($mensagem === 'editada'): ?>
        <div class="alert alert-success alert-dismissible fade show d-flex align-items-center gap-2">
            <i class="bi bi-check-circle-fill"></i> Transação atualizada com sucesso!
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php elseif ($mensagem === 'excluida'): ?>
        <div class="alert alert-warning alert-dismissible fade show d-flex align-items-center gap-2">
            <i class="bi bi-trash-fill"></i> Transação excluída.
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php endif; ?>

    <!-- Filtros -->
    <div class="card mb-4">
        <div class="card-body">
            <form method="GET" class="row g-2 align-items-end">
                <div class="col-12 col-sm-4 col-md-3">
                    <label class="form-label">Período</label>
                    <input type="month" name="mes" class="form-control" value="<?= htmlspecialchars($filtroMes) ?>">
                </div>
                <div class="col-12 col-sm-4 col-md-3">
                    <label class="form-label">Tipo</label>
                    <select name="tipo" class="form-select">
                        <option value="">Todos</option>
                        <option value="receita" <?= $filtroTipo === 'receita' ? 'selected' : '' ?>>Receitas</option>
                        <option value="despesa" <?= $filtroTipo === 'despesa' ? 'selected' : '' ?>>Despesas</option>
                    </select>
                </div>
                <div class="col-auto">
                    <button type="submit" class="btn btn-outline-primary">
                        <i class="bi bi-funnel me-1"></i>Filtrar
                    </button>
                    <a href="/projeto_dashboard_financeiro/transacoes/index.php" class="btn btn-outline-secondary ms-1">
                        Limpar
                    </a>
                </div>
            </form>
        </div>
    </div>

    <!-- Totais do filtro -->
    <?php $saldo = $totais['receitas'] - $totais['despesas']; ?>
    <div class="d-flex flex-wrap gap-2 mb-3">
        <div class="stat-box receita">
            <i class="bi bi-arrow-down stat-box-icon"></i>
            <div>
                <span class="stat-box-label">Entradas</span>
                <span class="stat-box-value">R$ <?= number_format($totais['receitas'], 2, ',', '.') ?></span>
            </div>
        </div>
        <div class="stat-box despesa">
            <i class="bi bi-arrow-up stat-box-icon"></i>
            <div>
                <span class="stat-box-label">Saídas</span>
                <span class="stat-box-value">R$ <?= number_format($totais['despesas'], 2, ',', '.') ?></span>
            </div>
        </div>
        <div class="stat-box <?= $saldo >= 0 ? 'saldo-pos' : 'saldo-neg' ?>">
            <i class="bi bi-wallet2 stat-box-icon"></i>
            <div>
                <span class="stat-box-label">Saldo</span>
                <span class="stat-box-value">R$ <?= number_format($saldo, 2, ',', '.') ?></span>
            </div>
        </div>
    </div>

    <!-- Tabela -->
    <div class="card">
        <div class="card-body p-0">
            <?php if (empty($transacoes)): ?>
                <div class="text-center text-muted py-5">
                    <i class="bi bi-inbox fs-1 opacity-25"></i>
                    <p class="mt-2">Nenhuma transação encontrada com os filtros aplicados.</p>
                </div>
            <?php else: ?>
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="ps-3">Descrição</th>
                                <th>Categoria</th>
                                <th>Tipo</th>
                                <th>Data</th>
                                <th class="text-end">Valor</th>
                                <th class="text-center pe-3">Ações</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($transacoes as $t): ?>
                                <tr>
                                    <td class="ps-3 fw-semibold"><?= htmlspecialchars($t['descricao']) ?></td>
                                    <td class="text-muted small"><?= htmlspecialchars($t['categoria'] ?? '—') ?></td>
                                    <td>
                                        <span class="tipo-tag <?= $t['tipo'] ?>">
                                            <?= $t['tipo'] === 'receita' ? '↓ ENTRADA' : '↑ SAÍDA' ?>
                                        </span>
                                    </td>
                                    <td class="text-muted small"><?= date('d/m/Y', strtotime($t['data'])) ?></td>
                                    <td class="text-end fw-bold <?= $t['tipo'] === 'receita' ? 'text-success' : 'text-danger' ?>">
                                        <?= $t['tipo'] === 'receita' ? '+' : '-' ?>
                                        R$ <?= number_format($t['valor'], 2, ',', '.') ?>
                                    </td>
                                    <td class="text-center pe-3">
                                        <a href="/projeto_dashboard_financeiro/transacoes/edit.php?id=<?= $t['id'] ?>"
                                           class="btn btn-sm btn-outline-secondary me-1" title="Editar">
                                            <i class="bi bi-pencil"></i>
                                        </a>
                                        <button type="button" class="btn btn-sm btn-outline-danger"
                                                title="Excluir"
                                                data-bs-toggle="modal"
                                                data-bs-target="#modalExcluir"
                                                data-id="<?= $t['id'] ?>"
                                                data-desc="<?= htmlspecialchars($t['descricao']) ?>">
                                            <i class="bi bi-trash"></i>
                                        </button>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
        </div>
    </div>

</div>
</main>

<!-- Modal de confirmação de exclusão -->
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
                Tem certeza que deseja excluir a transação <strong id="modalDescricao"></strong>?
                Esta ação não pode ser desfeita.
            </div>
            <div class="modal-footer border-0">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                <a id="btnConfirmarExclusao" href="#" class="btn btn-danger">
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
    document.getElementById('modalDescricao').textContent = btn.dataset.desc;
    document.getElementById('btnConfirmarExclusao').href =
        '/projeto_dashboard_financeiro/transacoes/delete.php?id=' + btn.dataset.id;
});
</script>
