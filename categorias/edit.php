<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../config/database.php';
requireLogin();

$pageTitle = 'Editar Categoria — Controle Financeiro';
$db = getDB();

$id = (int)($_GET['id'] ?? 0);

$stmt = $db->prepare("SELECT * FROM categorias WHERE id = ?");
$stmt->execute([$id]);
$categoria = $stmt->fetch();

if (!$categoria) {
    header('Location: /projeto_dashboard_financeiro/categorias/index.php');
    exit;
}

$erros = [];
$dados = $categoria;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $dados['nome'] = trim($_POST['nome'] ?? '');
    $dados['tipo'] = $_POST['tipo'] ?? '';

    if (strlen($dados['nome']) < 2)
        $erros[] = 'O nome deve ter pelo menos 2 caracteres.';

    if (!in_array($dados['tipo'], ['receita', 'despesa']))
        $erros[] = 'Selecione o tipo (Receita ou Despesa).';

    if (empty($erros)) {
        $chk = $db->prepare("SELECT id FROM categorias WHERE nome = ? AND tipo = ? AND id != ? LIMIT 1");
        $chk->execute([$dados['nome'], $dados['tipo'], $id]);
        if ($chk->fetch())
            $erros[] = 'Já existe outra categoria com este nome e tipo.';
    }

    $dados['limite_mensal'] = $_POST['limite_mensal'] ?? '';

    if (empty($erros)) {
        $stmt = $db->prepare("UPDATE categorias SET nome = ?, tipo = ?, limite_mensal = ? WHERE id = ?");
        $stmt->execute([$dados['nome'], $dados['tipo'], $dados['limite_mensal'] ?: null, $id]);
        header('Location: /projeto_dashboard_financeiro/categorias/index.php?msg=editada');
        exit;
    }
}

include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';
?>

<main class="py-4">
<div class="container" style="max-width: 560px;">

    <div class="mb-4">
        <a href="/projeto_dashboard_financeiro/categorias/index.php"
           class="text-decoration-none page-subtitle d-inline-flex align-items-center gap-1 mb-2">
            <i class="bi bi-arrow-left" style="font-size:0.75rem;"></i>Categorias
        </a>
        <h1 class="page-title mb-0">Editar Categoria</h1>
    </div>

    <?php if (!empty($erros)): ?>
        <div class="alert alert-danger">
            <ul class="mb-0 ps-3">
                <?php foreach ($erros as $e): ?>
                    <li><?= htmlspecialchars($e) ?></li>
                <?php endforeach; ?>
            </ul>
        </div>
    <?php endif; ?>

    <div class="card form-card shadow-sm">
        <div class="card-body p-4">
            <form method="POST" novalidate>

                <div class="mb-4">
                    <label class="form-label fw-semibold">Tipo</label>
                    <div class="d-flex gap-3">
                        <div class="form-check tipo-check flex-fill text-center p-0">
                            <input class="form-check-input d-none" type="radio" name="tipo"
                                   id="tipoReceita" value="receita"
                                   <?= $dados['tipo'] === 'receita' ? 'checked' : '' ?>>
                            <label class="form-check-label btn btn-outline-success w-100 py-3" for="tipoReceita">
                                <i class="bi bi-arrow-down-circle fs-5 d-block mb-1"></i>
                                <strong>Receita</strong>
                            </label>
                        </div>
                        <div class="form-check tipo-check flex-fill text-center p-0">
                            <input class="form-check-input d-none" type="radio" name="tipo"
                                   id="tipoDespesa" value="despesa"
                                   <?= $dados['tipo'] === 'despesa' ? 'checked' : '' ?>>
                            <label class="form-check-label btn btn-outline-danger w-100 py-3" for="tipoDespesa">
                                <i class="bi bi-arrow-up-circle fs-5 d-block mb-1"></i>
                                <strong>Despesa</strong>
                            </label>
                        </div>
                    </div>
                </div>

                <div class="mb-3">
                    <label for="nome" class="form-label fw-semibold">Nome da Categoria</label>
                    <input type="text" id="nome" name="nome" class="form-control"
                           value="<?= htmlspecialchars($dados['nome']) ?>" required>
                </div>

                <div class="mb-4">
                    <label for="limite_mensal" class="form-label fw-semibold">
                        Limite Mensal (R$) <span class="page-subtitle">(opcional — somente despesas)</span>
                    </label>
                    <div class="input-group">
                        <span class="input-group-text">R$</span>
                        <input type="number" id="limite_mensal" name="limite_mensal" class="form-control"
                               placeholder="Sem limite" step="0.01" min="0"
                               value="<?= htmlspecialchars($dados['limite_mensal'] ?? '') ?>">
                    </div>
                </div>

                <div class="d-flex gap-2">
                    <button type="submit" class="btn btn-primary px-4">
                        <i class="bi bi-check-lg me-2"></i>Salvar Alterações
                    </button>
                    <a href="/projeto_dashboard_financeiro/categorias/index.php" class="btn btn-outline-secondary">
                        Cancelar
                    </a>
                </div>

            </form>
        </div>
    </div>
</div>
</main>

<?php include __DIR__ . '/../includes/footer.php'; ?>

<script>
document.querySelectorAll('input[name="tipo"]').forEach(radio => {
    radio.addEventListener('change', () => {
        document.querySelectorAll('.tipo-check label').forEach(l => l.classList.remove('active'));
        if (radio.checked) radio.closest('.tipo-check').querySelector('label').classList.add('active');
    });
    if (radio.checked) radio.closest('.tipo-check').querySelector('label').classList.add('active');
});
</script>
