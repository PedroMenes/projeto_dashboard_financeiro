<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../config/database.php';
requireLogin();

$pageTitle = 'Editar Recorrência — Controle Financeiro';
$user = currentUser();
$db   = getDB();

$id = (int)($_GET['id'] ?? 0);
$stmt = $db->prepare("SELECT * FROM recorrencias WHERE id = ? AND usuario_id = ?");
$stmt->execute([$id, $user['id']]);
$rec = $stmt->fetch();

if (!$rec) { header('Location: /projeto_dashboard_financeiro/recorrencias/index.php'); exit; }

$erros = [];
$dados = $rec;

$categorias = $db->query("SELECT * FROM categorias ORDER BY tipo, nome")->fetchAll();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $dados['descricao']      = trim($_POST['descricao']      ?? '');
    $dados['valor']          = $_POST['valor']          ?? '';
    $dados['tipo']           = $_POST['tipo']           ?? '';
    $dados['categoria_id']   = $_POST['categoria_id']   ?? '';
    $dados['dia_vencimento'] = (int)($_POST['dia_vencimento'] ?? 0);
    $dados['ativa']          = isset($_POST['ativa']) ? 1 : 0;

    if (!$dados['descricao'])                               $erros[] = 'A descrição é obrigatória.';
    if (!is_numeric($dados['valor']) || $dados['valor'] <= 0) $erros[] = 'Informe um valor válido.';
    if ($dados['dia_vencimento'] < 1 || $dados['dia_vencimento'] > 31) $erros[] = 'Dia deve ser entre 1 e 31.';

    if (empty($erros)) {
        $db->prepare("UPDATE recorrencias SET descricao=?, valor=?, tipo=?, categoria_id=?, dia_vencimento=?, ativa=? WHERE id=? AND usuario_id=?")
           ->execute([$dados['descricao'], $dados['valor'], $dados['tipo'], $dados['categoria_id'] ?: null, $dados['dia_vencimento'], $dados['ativa'], $id, $user['id']]);
        header('Location: /projeto_dashboard_financeiro/recorrencias/index.php?msg=editada');
        exit;
    }
}

include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';
?>

<main class="py-4">
<div class="container" style="max-width:620px;">

    <div class="mb-4">
        <a href="/projeto_dashboard_financeiro/recorrencias/index.php"
           class="text-decoration-none page-subtitle d-inline-flex align-items-center gap-1 mb-2">
            <i class="bi bi-arrow-left" style="font-size:0.75rem;"></i>Recorrências
        </a>
        <h1 class="page-title mb-0">Editar Recorrência</h1>
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
                    <label class="form-label fw-semibold">Tipo</label>
                    <div class="d-flex gap-3">
                        <div class="form-check tipo-check flex-fill text-center p-0">
                            <input class="form-check-input d-none" type="radio" name="tipo" id="tipoReceita" value="receita"
                                   <?= $dados['tipo'] === 'receita' ? 'checked' : '' ?>>
                            <label class="form-check-label btn btn-outline-success w-100 py-3" for="tipoReceita">
                                <i class="bi bi-arrow-down-circle fs-5 d-block mb-1"></i><strong>Receita</strong>
                            </label>
                        </div>
                        <div class="form-check tipo-check flex-fill text-center p-0">
                            <input class="form-check-input d-none" type="radio" name="tipo" id="tipoDespesa" value="despesa"
                                   <?= $dados['tipo'] === 'despesa' ? 'checked' : '' ?>>
                            <label class="form-check-label btn btn-outline-danger w-100 py-3" for="tipoDespesa">
                                <i class="bi bi-arrow-up-circle fs-5 d-block mb-1"></i><strong>Despesa</strong>
                            </label>
                        </div>
                    </div>
                </div>

                <div class="mb-3">
                    <label for="descricao" class="form-label fw-semibold">Descrição</label>
                    <input type="text" id="descricao" name="descricao" class="form-control"
                           value="<?= htmlspecialchars($dados['descricao']) ?>" required>
                </div>

                <div class="row g-3 mb-3">
                    <div class="col-6">
                        <label for="valor" class="form-label fw-semibold">Valor (R$)</label>
                        <div class="input-group">
                            <span class="input-group-text">R$</span>
                            <input type="number" id="valor" name="valor" class="form-control"
                                   step="0.01" min="0.01" value="<?= htmlspecialchars($dados['valor']) ?>">
                        </div>
                    </div>
                    <div class="col-6">
                        <label for="dia_vencimento" class="form-label fw-semibold">Dia do Mês</label>
                        <input type="number" id="dia_vencimento" name="dia_vencimento" class="form-control"
                               min="1" max="31" value="<?= htmlspecialchars($dados['dia_vencimento']) ?>">
                    </div>
                </div>

                <div class="mb-3">
                    <label for="categoria_id" class="form-label fw-semibold">Categoria</label>
                    <select id="categoria_id" name="categoria_id" class="form-select">
                        <option value="">— Sem categoria —</option>
                        <?php foreach ($categorias as $cat): ?>
                            <option value="<?= $cat['id'] ?>" data-tipo="<?= $cat['tipo'] ?>"
                                    <?= (string)$dados['categoria_id'] === (string)$cat['id'] ? 'selected' : '' ?>>
                                <?= htmlspecialchars($cat['nome']) ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>

                <div class="mb-4">
                    <div class="form-check form-switch">
                        <input class="form-check-input" type="checkbox" id="ativa" name="ativa"
                               <?= $dados['ativa'] ? 'checked' : '' ?>>
                        <label class="form-check-label form-label" for="ativa">Recorrência ativa</label>
                    </div>
                </div>

                <div class="d-flex gap-2">
                    <button type="submit" class="btn btn-primary px-4">
                        <i class="bi bi-check-lg me-2"></i>Salvar Alterações
                    </button>
                    <a href="/projeto_dashboard_financeiro/recorrencias/index.php" class="btn btn-outline-secondary">Cancelar</a>
                </div>

            </form>
        </div>
    </div>
</div>
</main>

<?php include __DIR__ . '/../includes/footer.php'; ?>

<script>
document.querySelectorAll('input[name="tipo"]').forEach(r => {
    r.addEventListener('change', () => {
        document.querySelectorAll('.tipo-check label').forEach(l => l.classList.remove('active'));
        r.closest('.tipo-check').querySelector('label').classList.add('active');
    });
    if (r.checked) r.closest('.tipo-check').querySelector('label').classList.add('active');
});
</script>
