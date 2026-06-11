<?php
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/tema.php';
require_once __DIR__ . '/config/database.php';

$tema = getTema();

if (isLoggedIn()) {
    header('Location: /projeto_dashboard_financeiro/dashboard.php');
    exit;
}

$erros = [];
$dados = ['nome' => '', 'email' => ''];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $dados['nome']  = trim($_POST['nome']  ?? '');
    $dados['email'] = trim($_POST['email'] ?? '');
    $senha          = $_POST['senha']          ?? '';
    $senhaConfirm   = $_POST['senha_confirm']  ?? '';

    if (strlen($dados['nome']) < 2)
        $erros[] = 'O nome deve ter pelo menos 2 caracteres.';

    if (!filter_var($dados['email'], FILTER_VALIDATE_EMAIL))
        $erros[] = 'Informe um e-mail válido.';

    if (strlen($senha) < 6)
        $erros[] = 'A senha deve ter pelo menos 6 caracteres.';

    if ($senha !== $senhaConfirm)
        $erros[] = 'As senhas não coincidem.';

    if (empty($erros)) {
        $stmt = getDB()->prepare('SELECT id FROM usuarios WHERE email = ? LIMIT 1');
        $stmt->execute([$dados['email']]);
        if ($stmt->fetch()) {
            $erros[] = 'Este e-mail já está cadastrado.';
        }
    }

    if (empty($erros)) {
        $stmt = getDB()->prepare('INSERT INTO usuarios (nome, email, senha) VALUES (?, ?, ?)');
        $stmt->execute([$dados['nome'], $dados['email'], password_hash($senha, PASSWORD_DEFAULT)]);
        header('Location: /projeto_dashboard_financeiro/login.php?msg=cadastro_ok');
        exit;
    }
}
?>
<!DOCTYPE html>
<html lang="pt-BR" data-bs-theme="<?= htmlspecialchars(getBsTheme()) ?>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Novo Operador — Controle Financeiro</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;500;600;700;900&family=Share+Tech+Mono&display=swap" rel="stylesheet">
    <link href="/projeto_dashboard_financeiro/assets/css/custom.css" rel="stylesheet">
</head>
<body class="tema-<?= htmlspecialchars($tema) ?> bg-login d-flex align-items-center justify-content-center min-vh-100">

<div class="card login-card">
    <div class="eva-status-bar"></div>
    <div class="card-body p-4 p-sm-5">

        <!-- Cabeçalho NERV -->
        <div class="text-center mb-4">
            <div class="login-tag">NERV // REGISTRO DE OPERADOR</div>
            <i class="bi bi-hexagon-fill fs-1 d-block mb-2" style="color:#7c3aed;filter:drop-shadow(0 0 10px rgba(124,58,237,0.7));"></i>
            <h1 class="page-title mb-1" style="font-size:1rem;letter-spacing:0.15em;">NOVO ACESSO</h1>
            <p class="page-subtitle mb-0">CADASTRO DE NOVO OPERADOR</p>
        </div>

        <!-- Divisor -->
        <div class="d-flex align-items-center gap-2 mb-4" style="opacity:0.4;">
            <div style="flex:1;height:1px;background:var(--eva-border);"></div>
            <span style="font-size:0.55rem;font-family:'Orbitron',sans-serif;color:var(--eva-purple-light);letter-spacing:0.2em;">CREDENCIAIS</span>
            <div style="flex:1;height:1px;background:var(--eva-border);"></div>
        </div>

        <?php if (!empty($erros)): ?>
            <div class="alert alert-danger mb-3">
                <i class="bi bi-exclamation-triangle me-2"></i>
                <?php foreach ($erros as $e): ?>
                    <div><?= htmlspecialchars($e) ?></div>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>

        <form method="POST" novalidate>
            <div class="mb-3">
                <label for="nome" class="form-label">Nome do Operador</label>
                <input type="text" id="nome" name="nome" class="form-control"
                       placeholder="Nome completo" required
                       value="<?= htmlspecialchars($dados['nome']) ?>">
            </div>

            <div class="mb-3">
                <label for="email" class="form-label">ID do Operador (E-mail)</label>
                <input type="email" id="email" name="email" class="form-control"
                       placeholder="operador@nerv.gov" required
                       value="<?= htmlspecialchars($dados['email']) ?>">
            </div>

            <div class="mb-3">
                <label for="senha" class="form-label">Código de Autorização</label>
                <input type="password" id="senha" name="senha" class="form-control"
                       placeholder="Mínimo 6 caracteres" required>
            </div>

            <div class="mb-4">
                <label for="senha_confirm" class="form-label">Confirmar Código</label>
                <input type="password" id="senha_confirm" name="senha_confirm" class="form-control"
                       placeholder="Repita a senha" required>
            </div>

            <button type="submit" class="btn btn-primary w-100 py-2">
                <i class="bi bi-person-plus me-2"></i>REGISTRAR OPERADOR
            </button>
        </form>

        <!-- Link para login -->
        <div class="text-center mt-4">
            <a href="/projeto_dashboard_financeiro/login.php"
               class="page-subtitle text-decoration-none"
               style="font-size:0.72rem;color:var(--eva-text-muted);">
                <i class="bi bi-arrow-left me-1"></i>JÁ TENHO ACESSO <span class="blink">_</span>
            </a>
        </div>

    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
