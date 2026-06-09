<?php
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../config/database.php';
requireLogin();

$pageTitle = 'Nova Meta — Controle Financeiro';
$user = currentUser();
$db   = getDB();

$erros = [];
$dados = ['nome' => '', 'descricao' => '', 'valor_alvo' => '', 'valor_atual' => '0', 'prazo' => ''];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $dados['nome']        = trim($_POST['nome']        ?? '');
    $dados['descricao']   = trim($_POST['descricao']   ?? '');
    $dados['valor_alvo']  = $_POST['valor_alvo']  ?? '';
    $dados['valor_atual'] = $_POST['valor_atual'] ?? '0';
    $dados['prazo']       = $_POST['prazo']       ?? '';

    if (strlen($dados['nome']) < 2)
        $erros[] = 'O nome deve ter pelo menos 2 caracteres.';
    if (!is_numeric($dados['valor_alvo']) || $dados['valor_alvo'] <= 0)
        $erros[] = 'Informe um valor alvo válido maior que zero.';
    if ($dados['valor_atual'] !== '' && (!is_numeric($dados['valor_atual']) || $dados['valor_atual'] < 0))
        $erros[] = 'O valor atual não pode ser negativo.';
    if (is_numeric($dados['valor_atual']) && is_numeric($dados['valor_alvo']) && $dados['valor_atual'] > $dados['valor_alvo'])
        $erros[] = 'O valor atual não pode ser maior que o valor alvo.';

    if (empty($erros)) {
        $stmt = $db->prepare("INSERT INTO metas (usuario_id, nome, descricao, valor_alvo, valor_atual, prazo) VALUES (?,?,?,?,?,?)");
        $stmt->execute([
            $user['id'],
            $dados['nome'],
            $dados['descricao'] ?: null,
            $dados['valor_alvo'],
            $dados['valor_atual'] ?: 0,
            $dados['prazo'] ?: null,
        ]);
        header('Location: /projeto_dashboard_financeiro/metas/index.php?msg=criada');
        exit;
    }
}

include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';
?>

<main class="py-4">
<div class="container" style="max-width:600px;">

    <div class="mb-4">
        <a href="/projeto_dashboard_financeiro/metas/index.php"
           class="text-decoration-none page-subtitle d-inline-flex align-items-center gap-1 mb-2">
            <i class="bi bi-arrow-left" style="font-size:0.75rem;"></i>Metas
        </a>
        <h1 class="page-title mb-0">Nova Meta</h1>
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

                <div class="mb-3">
                    <label for="nome" class="form-label fw-semibold">Nome da Meta</label>
                    <input type="text" id="nome" name="nome" class="form-control"
                           placeholder="Ex: Reserva de emergência, Viagem..."
                           value="<?= htmlspecialchars($dados['nome']) ?>" required>
                </div>

                <div class="mb-3">
                    <label for="descricao" class="form-label fw-semibold">Descrição <span class="page-subtitle">(opcional)</span></label>
                    <input type="text" id="descricao" name="descricao" class="form-control"
                           placeholder="Detalhes sobre a meta..."
                           value="<?= htmlspecialchars($dados['descricao']) ?>">
                </div>

                <div class="row g-3 mb-3">
                    <div class="col-12 col-sm-6">
                        <label for="valor_alvo" class="form-label fw-semibold">Valor Alvo (R$)</label>
                        <div class="input-group">
                            <span class="input-group-text">R$</span>
                            <input type="number" id="valor_alvo" name="valor_alvo" class="form-control"
                                   placeholder="0,00" step="0.01" min="0.01"
                                   value="<?= htmlspecialchars($dados['valor_alvo']) ?>" required>
                        </div>
                    </div>
                    <div class="col-12 col-sm-6">
                        <label for="valor_atual" class="form-label fw-semibold">Já tenho (R$) <span class="page-subtitle">(opcional)</span></label>
                        <div class="input-group">
                            <span class="input-group-text">R$</span>
                            <input type="number" id="valor_atual" name="valor_atual" class="form-control"
                                   placeholder="0,00" step="0.01" min="0"
                                   value="<?= htmlspecialchars($dados['valor_atual']) ?>">
                        </div>
                    </div>
                </div>

                <div class="mb-4">
                    <label for="prazo" class="form-label fw-semibold">Prazo <span class="page-subtitle">(opcional)</span></label>
                    <input type="date" id="prazo" name="prazo" class="form-control"
                           value="<?= htmlspecialchars($dados['prazo']) ?>">
                </div>

                <div class="d-flex gap-2">
                    <button type="submit" class="btn btn-primary px-4">
                        <i class="bi bi-check-lg me-2"></i>Salvar Meta
                    </button>
                    <a href="/projeto_dashboard_financeiro/metas/index.php" class="btn btn-outline-secondary">Cancelar</a>
                </div>

            </form>
        </div>
    </div>
</div>
</main>

<?php include __DIR__ . '/../includes/footer.php'; ?>
