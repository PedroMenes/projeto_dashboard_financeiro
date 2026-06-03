<?php
require_once __DIR__ . '/includes/auth.php';
session_destroy();
header('Location: /projeto_dashboard_financeiro/login.php');
exit;
