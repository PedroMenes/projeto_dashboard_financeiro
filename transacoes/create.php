<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../config/database.php';
requireLogin();

$pageTitle = 'Nova Transação — Controle Financeiro';
$user = currentUser();
$db   = getDB();

$erros = [];
$dados = ['descricao' => '', 'valor' => '', 'tipo' => 'despesa', 'categoria_id' => '', 'data' => date('Y-m-d')];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $dados['descricao']    = trim($_POST['descricao'] ?? '');
    $dados['valor']        = $_POST['valor'] ?? '';
    $dados['tipo']         = $_POST['tipo'] ?? '';
    $dados['categoria_id'] = $_POST['categoria_id'] ?? '';
    $dados['data']         = $_POST['data'] ?? '';

    if (!$dados['descricao'])              $erros[] = 'A descrição é obrigatória.';
    if (!is_numeric($dados['valor']) || $dados['valor'] <= 0)
                                           $erros[] = 'Informe um valor válido maior que zero.';
    if (!in_array($dados['tipo'], ['receita', 'despesa']))
                                           $erros[] = 'Selecione o tipo (Receita ou Despesa).';
    if (!$dados['data'])                   $erros[] = 'A data é obrigatória.';

    if (empty($erros)) {
        $stmt = $db->prepare("
            INSERT INTO transacoes (usuario_id, descricao, valor, tipo, categoria_id, data)
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $user['id'],
            $dados['descricao'],
            $dados['valor'],
            $dados['tipo'],
            $dados['categoria_id'] ?: null,
            $dados['data'],
        ]);
        header('Location: /projeto_dashboard_financeiro/transacoes/index.php?msg=criada');
        exit;
    }
}

// Categorias separadas por tipo (para o JS filtrar dinamicamente)
$stmt = $db->query("SELECT * FROM categorias ORDER BY tipo, nome");
$categorias = $stmt->fetchAll();

include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';
?>

<main class="py-4">
<div class="container" style="max-width: 680px;">

    <div class="mb-4">
        <a href="/projeto_dashboard_financeiro/transacoes/index.php" class="text-decoration-none page-subtitle d-inline-flex align-items-center gap-1 mb-2">
            <i class="bi bi-arrow-left" style="font-size:0.75rem;"></i>Transações
        </a>
        <h1 class="page-title mb-0">Nova Transação</h1>
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

                <!-- Tipo: Receita ou Despesa (destaque visual) -->
                <div class="mb-4">
                    <label class="form-label fw-semibold">Tipo de Transação</label>
                    <div class="d-flex gap-3">
                        <div class="form-check tipo-check flex-fill text-center p-0">
                            <input class="form-check-input d-none" type="radio" name="tipo" id="tipoReceita"
                                   value="receita" <?= $dados['tipo'] === 'receita' ? 'checked' : '' ?>>
                            <label class="form-check-label btn btn-outline-success w-100 py-3" for="tipoReceita">
                                <i class="bi bi-arrow-down-circle fs-5 d-block mb-1"></i>
                                <strong>Receita</strong>
                            </label>
                        </div>
                        <div class="form-check tipo-check flex-fill text-center p-0">
                            <input class="form-check-input d-none" type="radio" name="tipo" id="tipoDespesa"
                                   value="despesa" <?= $dados['tipo'] === 'despesa' ? 'checked' : '' ?>>
                            <label class="form-check-label btn btn-outline-danger w-100 py-3" for="tipoDespesa">
                                <i class="bi bi-arrow-up-circle fs-5 d-block mb-1"></i>
                                <strong>Despesa</strong>
                            </label>
                        </div>
                    </div>
                </div>

                <div class="mb-3">
                    <label for="descricao" class="form-label fw-semibold">Descrição</label>
                    <input type="text" id="descricao" name="descricao" class="form-control"
                           placeholder="Ex: Supermercado, Salário do mês..."
                           value="<?= htmlspecialchars($dados['descricao']) ?>" required>
                </div>

                <div class="row g-3 mb-3">
                    <div class="col-6">
                        <label for="valor" class="form-label fw-semibold">Valor (R$)</label>
                        <div class="input-group">
                            <span class="input-group-text">R$</span>
                            <input type="number" id="valor" name="valor" class="form-control"
                                   placeholder="0,00" step="0.01" min="0.01"
                                   value="<?= htmlspecialchars($dados['valor']) ?>" required>
                        </div>
                    </div>
                    <div class="col-6">
                        <label for="data" class="form-label fw-semibold">Data</label>
                        <input type="date" id="data" name="data" class="form-control"
                               value="<?= htmlspecialchars($dados['data']) ?>" required>
                    </div>
                </div>

                <div class="mb-4">
                    <label for="categoria_id" class="form-label fw-semibold">Categoria</label>
                    <select id="categoria_id" name="categoria_id" class="form-select">
                        <option value="">— Sem categoria —</option>
                        <?php foreach ($categorias as $cat): ?>
                            <option value="<?= $cat['id'] ?>"
                                    data-tipo="<?= $cat['tipo'] ?>"
                                    <?= (string)$dados['categoria_id'] === (string)$cat['id'] ? 'selected' : '' ?>>
                                <?= htmlspecialchars($cat['nome']) ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>

                <div class="d-flex gap-2">
                    <button type="submit" class="btn btn-primary px-4">
                        <i class="bi bi-check-lg me-2"></i>Salvar Transação
                    </button>
                    <a href="/projeto_dashboard_financeiro/transacoes/index.php" class="btn btn-outline-secondary">
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
// Filtra categorias conforme o tipo selecionado
function filtrarCategorias() {
    const tipoSelecionado = document.querySelector('input[name="tipo"]:checked')?.value;
    const select = document.getElementById('categoria_id');
    select.value = '';
    Array.from(select.options).forEach(opt => {
        if (!opt.value) return;
        opt.hidden = opt.dataset.tipo !== tipoSelecionado;
    });
}

document.querySelectorAll('input[name="tipo"]').forEach(r => r.addEventListener('change', filtrarCategorias));
filtrarCategorias();

// Destaca visualmente o tipo selecionado
document.querySelectorAll('input[name="tipo"]').forEach(radio => {
    radio.addEventListener('change', () => {
        document.querySelectorAll('.tipo-check label').forEach(l => l.classList.remove('active'));
        if (radio.checked) radio.closest('.tipo-check').querySelector('label').classList.add('active');
    });
    if (radio.checked) radio.closest('.tipo-check').querySelector('label').classList.add('active');
});
</script>
