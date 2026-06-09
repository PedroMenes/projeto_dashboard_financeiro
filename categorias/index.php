<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../config/database.php';
requireLogin();

$pageTitle = 'Categorias — Controle Financeiro';
$db = getDB();

$mensagem = $_GET['msg'] ?? '';

$stmt = $db->query("SELECT * FROM categorias ORDER BY tipo, nome");
$categorias = $stmt->fetchAll();

$receitas = array_filter($categorias, fn($c) => $c['tipo'] === 'receita');
$despesas = array_filter($categorias, fn($c) => $c['tipo'] === 'despesa');

include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';
?>

<main class="py-4">
<div class="container-fluid px-4">

    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h1 class="page-title mb-0">Categorias</h1>
            <p class="page-subtitle mb-0">Gerencie os tipos de receitas e despesas</p>
        </div>
        <a href="/projeto_dashboard_financeiro/categorias/create.php" class="btn btn-primary">
            <i class="bi bi-plus me-1"></i>Nova Categoria
        </a>
    </div>

    <?php if ($mensagem === 'criada'): ?>
        <div class="alert alert-success alert-dismissible fade show d-flex align-items-center gap-2">
            <i class="bi bi-check-circle-fill"></i> Categoria criada com sucesso!
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php elseif ($mensagem === 'editada'): ?>
        <div class="alert alert-success alert-dismissible fade show d-flex align-items-center gap-2">
            <i class="bi bi-check-circle-fill"></i> Categoria atualizada com sucesso!
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php elseif ($mensagem === 'excluida'): ?>
        <div class="alert alert-warning alert-dismissible fade show d-flex align-items-center gap-2">
            <i class="bi bi-trash-fill"></i> Categoria excluída.
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php elseif ($mensagem === 'em_uso'): ?>
        <div class="alert alert-warning alert-dismissible fade show d-flex align-items-center gap-2">
            <i class="bi bi-exclamation-triangle-fill"></i> Não é possível excluir: esta categoria está vinculada a transações.
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php endif; ?>

    <div class="row g-4">

        <!-- Receitas -->
        <div class="col-12 col-lg-6">
            <div class="card h-100">
                <div class="card-header px-3 py-3 d-flex justify-content-between align-items-center">
                    <div>
                        <p class="page-title mb-0" style="font-size:0.9rem;color:var(--eva-green);">
                            <i class="bi bi-arrow-down-circle me-2"></i>Receitas
                        </p>
                        <p class="page-subtitle mb-0"><?= count($receitas) ?> categoria(s)</p>
                    </div>
                </div>
                <div class="card-body p-0">
                    <?php if (empty($receitas)): ?>
                        <div class="text-center text-muted py-5">
                            <i class="bi bi-inbox fs-1 opacity-25"></i>
                            <p class="mt-2">Nenhuma categoria de receita</p>
                        </div>
                    <?php else: ?>
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0">
                                <thead>
                                    <tr>
                                        <th class="ps-3">Nome</th>
                                        <th class="text-center pe-3">Ações</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($receitas as $cat): ?>
                                        <tr>
                                            <td class="ps-3">
                                                <span class="tipo-tag receita">↓ RECEITA</span>
                                                <span class="ms-2"><?= htmlspecialchars($cat['nome']) ?></span>
                                            </td>
                                            <td class="text-center pe-3">
                                                <a href="/projeto_dashboard_financeiro/categorias/edit.php?id=<?= $cat['id'] ?>"
                                                   class="btn btn-sm btn-outline-secondary me-1" title="Editar">
                                                    <i class="bi bi-pencil"></i>
                                                </a>
                                                <button type="button" class="btn btn-sm btn-outline-danger"
                                                        title="Excluir"
                                                        data-bs-toggle="modal"
                                                        data-bs-target="#modalExcluir"
                                                        data-id="<?= $cat['id'] ?>"
                                                        data-nome="<?= htmlspecialchars($cat['nome']) ?>">
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

        <!-- Despesas -->
        <div class="col-12 col-lg-6">
            <div class="card h-100">
                <div class="card-header px-3 py-3 d-flex justify-content-between align-items-center">
                    <div>
                        <p class="page-title mb-0" style="font-size:0.9rem;color:var(--eva-orange);">
                            <i class="bi bi-arrow-up-circle me-2"></i>Despesas
                        </p>
                        <p class="page-subtitle mb-0"><?= count($despesas) ?> categoria(s)</p>
                    </div>
                </div>
                <div class="card-body p-0">
                    <?php if (empty($despesas)): ?>
                        <div class="text-center text-muted py-5">
                            <i class="bi bi-inbox fs-1 opacity-25"></i>
                            <p class="mt-2">Nenhuma categoria de despesa</p>
                        </div>
                    <?php else: ?>
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0">
                                <thead>
                                    <tr>
                                        <th class="ps-3">Nome</th>
                                        <th class="text-center pe-3">Ações</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($despesas as $cat): ?>
                                        <tr>
                                            <td class="ps-3">
                                                <span class="tipo-tag despesa">↑ DESPESA</span>
                                                <span class="ms-2"><?= htmlspecialchars($cat['nome']) ?></span>
                                            </td>
                                            <td class="text-center pe-3">
                                                <a href="/projeto_dashboard_financeiro/categorias/edit.php?id=<?= $cat['id'] ?>"
                                                   class="btn btn-sm btn-outline-secondary me-1" title="Editar">
                                                    <i class="bi bi-pencil"></i>
                                                </a>
                                                <button type="button" class="btn btn-sm btn-outline-danger"
                                                        title="Excluir"
                                                        data-bs-toggle="modal"
                                                        data-bs-target="#modalExcluir"
                                                        data-id="<?= $cat['id'] ?>"
                                                        data-nome="<?= htmlspecialchars($cat['nome']) ?>">
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
                Tem certeza que deseja excluir a categoria <strong id="modalNome"></strong>?
                Transações vinculadas a ela ficarão sem categoria.
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
    document.getElementById('modalNome').textContent = btn.dataset.nome;
    document.getElementById('btnConfirmarExclusao').href =
        '/projeto_dashboard_financeiro/categorias/delete.php?id=' + btn.dataset.id;
});
</script>
