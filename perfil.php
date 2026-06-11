<?php
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/tema.php';
require_once __DIR__ . '/config/database.php';
requireLogin();

$pageTitle = 'Meu Perfil — Controle Financeiro';
$user = currentUser();
$db   = getDB();

// Busca dados atuais do usuário no banco
$stmt = $db->prepare("SELECT id, nome, email, created_at FROM usuarios WHERE id = ?");
$stmt->execute([$user['id']]);
$usuario = $stmt->fetch();

if (!$usuario) {
    session_destroy();
    header('Location: /projeto_dashboard_financeiro/login.php');
    exit;
}

$erros   = [];
$sucesso = '';
$aba     = $_POST['aba'] ?? $_GET['aba'] ?? 'dados';

// --- ATUALIZAR DADOS ---
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['salvar_dados'])) {
    $aba  = 'dados';
    $nome = trim($_POST['nome'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $senhaAtual  = $_POST['senha_atual']  ?? '';
    $novaSenha   = $_POST['nova_senha']   ?? '';
    $confirmSenha = $_POST['confirm_senha'] ?? '';

    if (strlen($nome) < 2)
        $erros[] = 'O nome deve ter pelo menos 2 caracteres.';

    if (!filter_var($email, FILTER_VALIDATE_EMAIL))
        $erros[] = 'Informe um e-mail válido.';

    // Verifica se o e-mail já pertence a outro usuário
    if (empty($erros) && $email !== $usuario['email']) {
        $chk = $db->prepare("SELECT id FROM usuarios WHERE email = ? AND id != ? LIMIT 1");
        $chk->execute([$email, $usuario['id']]);
        if ($chk->fetch())
            $erros[] = 'Este e-mail já está em uso por outro operador.';
    }

    // Troca de senha (opcional): só valida se o usuário preencheu algum campo de senha
    $trocarSenha = $senhaAtual || $novaSenha || $confirmSenha;
    if ($trocarSenha) {
        // Verifica senha atual
        $chkSenha = $db->prepare("SELECT senha FROM usuarios WHERE id = ?");
        $chkSenha->execute([$usuario['id']]);
        $hashAtual = $chkSenha->fetchColumn();

        if (!password_verify($senhaAtual, $hashAtual))
            $erros[] = 'Senha atual incorreta.';

        if (strlen($novaSenha) < 6)
            $erros[] = 'A nova senha deve ter pelo menos 6 caracteres.';

        if ($novaSenha !== $confirmSenha)
            $erros[] = 'A confirmação da nova senha não confere.';
    }

    if (empty($erros)) {
        if ($trocarSenha) {
            $stmt = $db->prepare("UPDATE usuarios SET nome = ?, email = ?, senha = ? WHERE id = ?");
            $stmt->execute([$nome, $email, password_hash($novaSenha, PASSWORD_DEFAULT), $usuario['id']]);
        } else {
            $stmt = $db->prepare("UPDATE usuarios SET nome = ?, email = ? WHERE id = ?");
            $stmt->execute([$nome, $email, $usuario['id']]);
        }

        // Atualiza a sessão com o novo nome
        $_SESSION['usuario_nome'] = $nome;
        $usuario['nome']  = $nome;
        $usuario['email'] = $email;

        $sucesso = 'Dados atualizados com sucesso!';
    }
}

// --- ATUALIZAR TEMA ---
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['salvar_tema'])) {
    $aba = 'aparencia';
    setTema($_POST['tema'] ?? 'normal');
    $sucesso = 'Tema atualizado com sucesso!';
}

// --- EXCLUIR CONTA ---
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['excluir_conta'])) {
    $senhaConfirm = $_POST['senha_excluir'] ?? '';

    $chkSenha = $db->prepare("SELECT senha FROM usuarios WHERE id = ?");
    $chkSenha->execute([$usuario['id']]);
    $hash = $chkSenha->fetchColumn();

    if (!password_verify($senhaConfirm, $hash)) {
        $aba    = 'excluir';
        $erros[] = 'Senha incorreta. A exclusão foi cancelada.';
    } else {
        $db->prepare("DELETE FROM usuarios WHERE id = ?")->execute([$usuario['id']]);
        session_destroy();
        header('Location: /projeto_dashboard_financeiro/login.php?msg=conta_excluida');
        exit;
    }
}

include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/navbar.php';
?>

<main class="py-4">
<div class="container" style="max-width: 760px;">

    <!-- Cabeçalho -->
    <div class="mb-4">
        <p class="page-subtitle mb-1">OPERADOR // GERENCIAMENTO</p>
        <h1 class="page-title mb-0">Meu Perfil</h1>
    </div>

    <!-- Card de identificação -->
    <div class="card mb-4">
        <div class="card-body d-flex align-items-center gap-4 py-4 px-4">
            <div class="avatar-lg d-flex align-items-center justify-content-center"
                 style="width:64px;height:64px;border-radius:50%;background:var(--eva-purple);font-size:1.6rem;font-family:'Orbitron',sans-serif;font-weight:700;color:#fff;flex-shrink:0;box-shadow:0 0 16px rgba(124,58,237,0.5);">
                <?= htmlspecialchars(strtoupper(substr($usuario['nome'], 0, 1))) ?>
            </div>
            <div>
                <p class="page-title mb-0" style="font-size:1rem;"><?= htmlspecialchars(strtoupper($usuario['nome'])) ?></p>
                <p class="page-subtitle mb-0"><?= htmlspecialchars($usuario['email']) ?></p>
                <p class="page-subtitle mb-0" style="font-size:0.65rem;margin-top:4px;">
                    OPERADOR DESDE <?= date('d/m/Y', strtotime($usuario['created_at'])) ?>
                </p>
            </div>
        </div>
    </div>

    <!-- Abas -->
    <ul class="nav nav-tabs mb-4" style="border-bottom-color:var(--eva-border);">
        <li class="nav-item">
            <a class="nav-link <?= $aba === 'dados' ? 'active' : '' ?>"
               href="/projeto_dashboard_financeiro/perfil.php?aba=dados">
                <i class="bi bi-person-gear me-1"></i>Editar Dados
            </a>
        </li>
        <li class="nav-item">
            <a class="nav-link <?= $aba === 'aparencia' ? 'active' : '' ?>"
               href="/projeto_dashboard_financeiro/perfil.php?aba=aparencia">
                <i class="bi bi-palette me-1"></i>Aparência
            </a>
        </li>
        <li class="nav-item">
            <a class="nav-link text-danger <?= $aba === 'excluir' ? 'active' : '' ?>"
               href="/projeto_dashboard_financeiro/perfil.php?aba=excluir">
                <i class="bi bi-trash me-1"></i>Excluir Conta
            </a>
        </li>
    </ul>

    <?php if (!empty($erros)): ?>
        <div class="alert alert-danger d-flex align-items-start gap-2 mb-3">
            <i class="bi bi-exclamation-triangle-fill mt-1"></i>
            <ul class="mb-0 ps-2">
                <?php foreach ($erros as $e): ?>
                    <li><?= htmlspecialchars($e) ?></li>
                <?php endforeach; ?>
            </ul>
        </div>
    <?php endif; ?>

    <?php if ($sucesso): ?>
        <div class="alert alert-success d-flex align-items-center gap-2 mb-3">
            <i class="bi bi-check-circle-fill"></i><?= htmlspecialchars($sucesso) ?>
        </div>
    <?php endif; ?>

    <!-- ABA: Editar Dados -->
    <?php if ($aba === 'dados'): ?>
    <div class="card form-card shadow-sm">
        <div class="card-body p-4">
            <form method="POST" novalidate>
                <input type="hidden" name="aba" value="dados">

                <h6 class="page-subtitle mb-3">// INFORMAÇÕES DO OPERADOR</h6>

                <div class="mb-3">
                    <label for="nome" class="form-label fw-semibold">Nome</label>
                    <input type="text" id="nome" name="nome" class="form-control"
                           value="<?= htmlspecialchars($usuario['nome']) ?>" required>
                </div>

                <div class="mb-4">
                    <label for="email" class="form-label fw-semibold">E-mail</label>
                    <input type="email" id="email" name="email" class="form-control"
                           value="<?= htmlspecialchars($usuario['email']) ?>" required>
                </div>

                <h6 class="page-subtitle mb-3">// ALTERAR SENHA <span style="font-size:0.65rem;">(deixe em branco para manter a atual)</span></h6>

                <div class="mb-3">
                    <label for="senha_atual" class="form-label fw-semibold">Senha Atual</label>
                    <input type="password" id="senha_atual" name="senha_atual" class="form-control"
                           placeholder="Necessária apenas para trocar a senha">
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-12 col-sm-6">
                        <label for="nova_senha" class="form-label fw-semibold">Nova Senha</label>
                        <input type="password" id="nova_senha" name="nova_senha" class="form-control"
                               placeholder="Mínimo 6 caracteres">
                    </div>
                    <div class="col-12 col-sm-6">
                        <label for="confirm_senha" class="form-label fw-semibold">Confirmar Nova Senha</label>
                        <input type="password" id="confirm_senha" name="confirm_senha" class="form-control"
                               placeholder="Repita a nova senha">
                    </div>
                </div>

                <button type="submit" name="salvar_dados" class="btn btn-primary px-4">
                    <i class="bi bi-check-lg me-2"></i>Salvar Alterações
                </button>
            </form>
        </div>
    </div>

    <!-- ABA: Aparência -->
    <?php elseif ($aba === 'aparencia'): ?>
    <div class="card form-card shadow-sm">
        <div class="card-body p-4">
            <form method="POST" novalidate>
                <input type="hidden" name="aba" value="aparencia">

                <h6 class="page-subtitle mb-1">// TEMA DO SISTEMA</h6>
                <p class="page-subtitle mb-3" style="font-size:0.75rem;">
                    Escolha a aparência visual do sistema. A alteração é aplicada imediatamente em todas as telas.
                </p>

                <div class="row g-3 mb-4">
                    <div class="col-12 col-sm-4">
                        <input type="radio" class="btn-check" name="tema" id="temaNormal" value="normal" autocomplete="off"
                               <?= getTema() === 'normal' ? 'checked' : '' ?>>
                        <label class="btn btn-outline-secondary w-100 h-100 text-start p-3" for="temaNormal">
                            <i class="bi bi-sun fs-4 d-block mb-2"></i>
                            <strong>Normal</strong>
                            <div class="page-subtitle mt-1" style="font-size:0.7rem;">Visual clássico e claro</div>
                        </label>
                    </div>
                    <div class="col-12 col-sm-4">
                        <input type="radio" class="btn-check" name="tema" id="temaEscuro" value="escuro" autocomplete="off"
                               <?= getTema() === 'escuro' ? 'checked' : '' ?>>
                        <label class="btn btn-outline-secondary w-100 h-100 text-start p-3" for="temaEscuro">
                            <i class="bi bi-moon-stars fs-4 d-block mb-2"></i>
                            <strong>Escuro</strong>
                            <div class="page-subtitle mt-1" style="font-size:0.7rem;">Visual clássico em tons escuros</div>
                        </label>
                    </div>
                    <div class="col-12 col-sm-4">
                        <input type="radio" class="btn-check" name="tema" id="temaEva" value="eva" autocomplete="off"
                               <?= getTema() === 'eva' ? 'checked' : '' ?>>
                        <label class="btn btn-outline-secondary w-100 h-100 text-start p-3" for="temaEva">
                            <i class="bi bi-hexagon fs-4 d-block mb-2"></i>
                            <strong>EVA // NERV System</strong>
                            <div class="page-subtitle mt-1" style="font-size:0.7rem;">Visual sci-fi inspirado em Evangelion</div>
                        </label>
                    </div>
                </div>

                <button type="submit" name="salvar_tema" class="btn btn-primary px-4">
                    <i class="bi bi-check-lg me-2"></i>Aplicar Tema
                </button>
            </form>
        </div>
    </div>

    <!-- ABA: Excluir Conta -->
    <?php else: ?>
    <div class="card form-card shadow-sm" style="border-color:rgba(239,68,68,0.3);">
        <div class="card-body p-4">
            <div class="alert alert-danger d-flex gap-2 mb-4">
                <i class="bi bi-exclamation-triangle-fill fs-5 flex-shrink-0"></i>
                <div>
                    <strong>ATENÇÃO:</strong> Esta ação é permanente e não pode ser desfeita.
                    Ao excluir sua conta, <strong>todas as suas transações</strong> também serão removidas definitivamente.
                </div>
            </div>

            <form method="POST" novalidate>
                <input type="hidden" name="aba" value="excluir">

                <div class="mb-4">
                    <label for="senha_excluir" class="form-label fw-semibold">Confirme sua senha para continuar</label>
                    <input type="password" id="senha_excluir" name="senha_excluir" class="form-control"
                           placeholder="Digite sua senha atual" required>
                </div>

                <button type="button" class="btn btn-danger px-4"
                        data-bs-toggle="modal" data-bs-target="#modalExcluirConta">
                    <i class="bi bi-trash me-2"></i>Excluir Minha Conta
                </button>
                <a href="/projeto_dashboard_financeiro/dashboard.php" class="btn btn-outline-secondary ms-2">
                    Cancelar
                </a>

                <!-- Modal de confirmação final -->
                <div class="modal fade" id="modalExcluirConta" tabindex="-1">
                    <div class="modal-dialog modal-dialog-centered">
                        <div class="modal-content">
                            <div class="modal-header border-0">
                                <h5 class="modal-title fw-bold text-danger">
                                    <i class="bi bi-exclamation-triangle me-2"></i>Confirmar Exclusão
                                </h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                            </div>
                            <div class="modal-body">
                                Tem certeza absoluta? Sua conta e <strong>todos os seus dados financeiros</strong>
                                serão apagados permanentemente.
                            </div>
                            <div class="modal-footer border-0">
                                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                                <button type="submit" name="excluir_conta" class="btn btn-danger">
                                    <i class="bi bi-trash me-2"></i>Sim, excluir minha conta
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </form>
        </div>
    </div>
    <?php endif; ?>

</div>
</main>

<?php include __DIR__ . '/includes/footer.php'; ?>
