<?php
$currentPage = basename($_SERVER['PHP_SELF']);
$user = currentUser();
?>
<nav class="navbar navbar-expand-lg">
    <div class="container-fluid px-4">

        <a class="navbar-brand d-flex align-items-center gap-2" href="/projeto_dashboard_financeiro/dashboard.php">
            <i class="bi bi-hexagon-fill fs-6"></i>
            <span>NERV // Sistema Financeiro</span>
        </a>

        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navMenu">
            <span class="navbar-toggler-icon"></span>
        </button>

        <div class="collapse navbar-collapse" id="navMenu">
            <ul class="navbar-nav me-auto mb-2 mb-lg-0 gap-1">
                <li class="nav-item">
                    <a class="nav-link <?= $currentPage === 'dashboard.php' ? 'active' : '' ?>"
                       href="/projeto_dashboard_financeiro/dashboard.php">
                        <i class="bi bi-speedometer2 me-1"></i>Dashboard
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= ($currentPage === 'index.php' && strpos($_SERVER['PHP_SELF'], 'transacoes') !== false) ? 'active' : '' ?>"
                       href="/projeto_dashboard_financeiro/transacoes/index.php">
                        <i class="bi bi-arrow-left-right me-1"></i>Transações
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $currentPage === 'create.php' ? 'active' : '' ?>"
                       href="/projeto_dashboard_financeiro/transacoes/create.php">
                        <i class="bi bi-plus me-1"></i>Registrar
                    </a>
                </li>
            </ul>

            <ul class="navbar-nav align-items-center">
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle d-flex align-items-center gap-2" href="#"
                       data-bs-toggle="dropdown">
                        <div class="avatar-sm">
                            <?= strtoupper(substr($user['nome'], 0, 1)) ?>
                        </div>
                        <span><?= htmlspecialchars(strtoupper(explode(' ', $user['nome'])[0])) ?></span>
                    </a>
                    <ul class="dropdown-menu dropdown-menu-end">
                        <li>
                            <a class="dropdown-item" href="/projeto_dashboard_financeiro/logout.php">
                                <i class="bi bi-power me-2"></i>DESCONECTAR
                            </a>
                        </li>
                    </ul>
                </li>
            </ul>
        </div>
    </div>
</nav>
