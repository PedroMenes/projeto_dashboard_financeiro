<?php
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/config/database.php';

if (isLoggedIn()) {
    header('Location: /projeto_dashboard_financeiro/dashboard.php');
    exit;
}

$erro = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = trim($_POST['email'] ?? '');
    $senha = $_POST['senha'] ?? '';

    if ($email && $senha) {
        $stmt = getDB()->prepare('SELECT id, nome, senha FROM usuarios WHERE email = ? LIMIT 1');
        $stmt->execute([$email]);
        $usuario = $stmt->fetch();

        if ($usuario && password_verify($senha, $usuario['senha'])) {
            session_regenerate_id(true);
            $_SESSION['usuario_id']   = $usuario['id'];
            $_SESSION['usuario_nome'] = $usuario['nome'];
            header('Location: /projeto_dashboard_financeiro/dashboard.php');
            exit;
        }
    }
    $erro = 'E-mail ou senha incorretos.';
}
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Login — Controle Financeiro</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;500;600;700;900&family=Share+Tech+Mono&display=swap" rel="stylesheet">
    <link href="/projeto_dashboard_financeiro/assets/css/custom.css" rel="stylesheet">
</head>
<body class="bg-login d-flex align-items-center justify-content-center min-vh-100">

<div class="card login-card">
    <div class="eva-status-bar"></div>
    <div class="card-body p-4 p-sm-5">

        <!-- Cabeçalho NERV -->
        <div class="text-center mb-4">
            <div class="login-tag">NERV // MAGI SYSTEM ACCESS</div>
            <i class="bi bi-hexagon-fill fs-1 d-block mb-2" style="color:#7c3aed;filter:drop-shadow(0 0 10px rgba(124,58,237,0.7));"></i>
            <h1 class="page-title mb-1" style="font-size:1rem;letter-spacing:0.15em;">CONTROLE FINANCEIRO</h1>
            <p class="page-subtitle mb-0">TERMINAL DE ACESSO AUTORIZADO</p>
        </div>

        <!-- Linha separadora estilo sci-fi -->
        <div class="d-flex align-items-center gap-2 mb-4" style="opacity:0.4;">
            <div style="flex:1;height:1px;background:var(--eva-border);"></div>
            <span style="font-size:0.55rem;font-family:'Orbitron',sans-serif;color:var(--eva-purple-light);letter-spacing:0.2em;">IDENTIFICAÇÃO</span>
            <div style="flex:1;height:1px;background:var(--eva-border);"></div>
        </div>

        <?php if ($_GET['msg'] ?? '' === 'cadastro_ok'): ?>
            <div class="alert alert-success d-flex align-items-center gap-2 mb-3">
                <i class="bi bi-check-circle"></i>
                <span>OPERADOR REGISTRADO — Faça login para continuar.</span>
            </div>
        <?php elseif ($_GET['msg'] ?? '' === 'conta_excluida'): ?>
            <div class="alert alert-warning d-flex align-items-center gap-2 mb-3">
                <i class="bi bi-trash"></i>
                <span>CONTA ENCERRADA — Seus dados foram removidos do sistema.</span>
            </div>
        <?php endif; ?>

        <?php if ($erro): ?>
            <div class="alert alert-danger d-flex align-items-center gap-2 mb-3">
                <i class="bi bi-exclamation-triangle"></i>
                <span>ACESSO NEGADO — <?= htmlspecialchars($erro) ?></span>
            </div>
        <?php endif; ?>

        <form method="POST" novalidate>
            <div class="mb-3">
                <label for="email" class="form-label">ID do Operador</label>
                <input type="email" id="email" name="email" class="form-control"
                       placeholder="operador@nerv.gov" required
                       value="<?= htmlspecialchars($_POST['email'] ?? '') ?>">
            </div>

            <div class="mb-4">
                <label for="senha" class="form-label">Código de Autorização</label>
                <input type="password" id="senha" name="senha" class="form-control"
                       placeholder="••••••••" required>
            </div>

            <button type="submit" class="btn btn-primary w-100 py-2">
                <i class="bi bi-shield-lock me-2"></i>CONFIRMAR ACESSO
            </button>
        </form>

        <!-- Link para cadastro -->
        <div class="text-center mt-3">
            <a href="/projeto_dashboard_financeiro/register.php"
               class="text-decoration-none"
               style="font-family:'Orbitron',sans-serif;font-size:0.68rem;letter-spacing:0.08em;color:var(--eva-text-muted);">
                NOVO OPERADOR? &nbsp;<span style="color:var(--eva-purple-light);">REGISTRAR ACESSO</span>
            </a>
        </div>

        <div class="text-center mt-3">
            <span class="page-subtitle" style="font-size:0.65rem;">
                DEMO &nbsp;|&nbsp; admin@financeiro.com &nbsp;/&nbsp; 123456 <span class="blink">_</span>
            </span>
        </div>

    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
