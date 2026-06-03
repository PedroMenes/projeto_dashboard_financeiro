<?php
require_once __DIR__ . '/includes/auth.php';

if (isLoggedIn()) {
    header('Location: /projeto_dashboard_financeiro/dashboard.php');
} else {
    header('Location: /projeto_dashboard_financeiro/login.php');
}
exit;
