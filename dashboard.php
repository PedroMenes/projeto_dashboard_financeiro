<?php
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/config/database.php';
requireLogin();

$pageTitle = 'Dashboard — Controle Financeiro';
$user = currentUser();
$db   = getDB();

// Totais do mês atual
$mesAtual = date('Y-m');
$stmt = $db->prepare("
    SELECT
        COALESCE(SUM(CASE WHEN tipo = 'receita' THEN valor END), 0) AS total_receitas,
        COALESCE(SUM(CASE WHEN tipo = 'despesa' THEN valor END), 0) AS total_despesas
    FROM transacoes
    WHERE usuario_id = ? AND DATE_FORMAT(data, '%Y-%m') = ?
");
$stmt->execute([$user['id'], $mesAtual]);
$totais = $stmt->fetch();

$saldo         = $totais['total_receitas'] - $totais['total_despesas'];
$totalReceitas = $totais['total_receitas'];
$totalDespesas = $totais['total_despesas'];

// Últimas 5 transações
$stmt = $db->prepare("
    SELECT t.descricao, t.valor, t.tipo, t.data, c.nome AS categoria
    FROM transacoes t
    LEFT JOIN categorias c ON c.id = t.categoria_id
    WHERE t.usuario_id = ?
    ORDER BY t.data DESC, t.id DESC
    LIMIT 5
");
$stmt->execute([$user['id']]);
$ultimas = $stmt->fetchAll();

// Despesas por categoria (para o gráfico)
$stmt = $db->prepare("
    SELECT c.nome AS categoria, SUM(t.valor) AS total
    FROM transacoes t
    LEFT JOIN categorias c ON c.id = t.categoria_id
    WHERE t.usuario_id = ? AND t.tipo = 'despesa' AND DATE_FORMAT(t.data, '%Y-%m') = ?
    GROUP BY c.nome
    ORDER BY total DESC
    LIMIT 6
");
$stmt->execute([$user['id'], $mesAtual]);
$despesasPorCategoria = $stmt->fetchAll();

$graficoCategorias = array_column($despesasPorCategoria, 'categoria');
$graficoValores    = array_column($despesasPorCategoria, 'total');

include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/navbar.php';
?>

<main class="py-4">
<div class="container-fluid px-4">

    <!-- Cabeçalho -->
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <p class="page-subtitle mb-1">OPERADOR: <?= htmlspecialchars(strtoupper($user['nome'])) ?></p>
            <h1 class="page-title mb-0" style="font-size:1.3rem;">PAINEL DE CONTROLE</h1>
        </div>
        <a href="/projeto_dashboard_financeiro/transacoes/create.php" class="btn btn-primary">
            <i class="bi bi-plus me-1"></i>Registrar
        </a>
    </div>

    <!-- Cards de resumo -->
    <div class="row g-3 mb-4">
        <!-- Saldo -->
        <div class="col-12 col-sm-6 col-xl-4">
            <div class="card summary-card h-100">
                <div class="card-body d-flex align-items-center gap-3 py-3">
                    <div class="summary-icon">
                        <i class="bi bi-hexagon text-primary"></i>
                    </div>
                    <div>
                        <p class="page-subtitle mb-1">// Saldo Mensal</p>
                        <p class="fw-semibold mb-0 fs-5 <?= $saldo >= 0 ? 'text-success' : 'text-danger' ?>"
                           style="font-family:'Share Tech Mono',monospace;">
                            R$ <?= number_format($saldo, 2, ',', '.') ?>
                        </p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Receitas -->
        <div class="col-12 col-sm-6 col-xl-4">
            <div class="card summary-card h-100">
                <div class="card-body d-flex align-items-center gap-3 py-3">
                    <div class="summary-icon">
                        <i class="bi bi-arrow-down text-success"></i>
                    </div>
                    <div>
                        <p class="page-subtitle mb-1">// Entradas</p>
                        <p class="fw-semibold mb-0 fs-5 text-success"
                           style="font-family:'Share Tech Mono',monospace;">
                            R$ <?= number_format($totalReceitas, 2, ',', '.') ?>
                        </p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Despesas -->
        <div class="col-12 col-sm-6 col-xl-4">
            <div class="card summary-card h-100">
                <div class="card-body d-flex align-items-center gap-3 py-3">
                    <div class="summary-icon">
                        <i class="bi bi-arrow-up text-danger"></i>
                    </div>
                    <div>
                        <p class="page-subtitle mb-1">// Saídas</p>
                        <p class="fw-semibold mb-0 fs-5 text-danger"
                           style="font-family:'Share Tech Mono',monospace;">
                            R$ <?= number_format($totalDespesas, 2, ',', '.') ?>
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Gráfico + Últimas transações -->
    <div class="row g-3">
        <!-- Gráfico de pizza -->
        <div class="col-12 col-lg-5">
            <div class="card h-100">
                <div class="card-header px-3 py-3">
                    <p class="page-title mb-0" style="font-size:0.9rem;">Despesas por Categoria</p>
                    <p class="page-subtitle mb-0">Mês atual</p>
                </div>
                <div class="card-body d-flex align-items-center justify-content-center">
                    <?php if (empty($despesasPorCategoria)): ?>
                        <div class="text-center text-muted py-5">
                            <i class="bi bi-pie-chart fs-1 opacity-25"></i>
                            <p class="mt-2">Nenhuma despesa registrada este mês</p>
                        </div>
                    <?php else: ?>
                        <canvas id="graficoDespesas" style="max-height:280px;"></canvas>
                    <?php endif; ?>
                </div>
            </div>
        </div>

        <!-- Últimas transações -->
        <div class="col-12 col-lg-7">
            <div class="card h-100">
                <div class="card-header px-3 py-3 d-flex justify-content-between align-items-center">
                    <div>
                        <p class="page-title mb-0" style="font-size:0.9rem;">Últimas Transações</p>
                        <p class="page-subtitle mb-0">5 mais recentes</p>
                    </div>
                    <a href="/projeto_dashboard_financeiro/transacoes/index.php" class="btn btn-sm btn-outline-secondary">
                        Ver todas
                    </a>
                </div>
                <div class="card-body p-0">
                    <?php if (empty($ultimas)): ?>
                        <div class="text-center py-5" style="color:#9ca3af;">
                            <i class="bi bi-inbox fs-1 opacity-25 d-block mb-2"></i>
                            <p class="page-subtitle mb-3">Nenhuma transação registrada ainda</p>
                            <a href="/projeto_dashboard_financeiro/transacoes/create.php" class="btn btn-primary btn-sm">
                                Adicionar primeira transação
                            </a>
                        </div>
                    <?php else: ?>
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0">
                                <thead>
                                    <tr>
                                        <th class="ps-3">Descrição</th>
                                        <th>Categoria</th>
                                        <th>Data</th>
                                        <th class="text-end pe-3">Valor</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($ultimas as $t): ?>
                                        <tr>
                                            <td class="ps-3 d-flex align-items-center gap-2">
                                                <i class="bi bi-<?= $t['tipo'] === 'receita' ? 'arrow-down text-success' : 'arrow-up text-danger' ?>" style="font-size:0.75rem;"></i>
                                                <?= htmlspecialchars($t['descricao']) ?>
                                            </td>
                                            <td class="col-categoria"><?= htmlspecialchars($t['categoria'] ?? '—') ?></td>
                                            <td class="col-data"><?= date('d/m/Y', strtotime($t['data'])) ?></td>
                                            <td class="text-end pe-3 fw-semibold <?= $t['tipo'] === 'receita' ? 'text-success' : 'text-danger' ?>">
                                                <?= $t['tipo'] === 'receita' ? '+' : '−' ?>
                                                R$ <?= number_format($t['valor'], 2, ',', '.') ?>
                                            </td>
                                        </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
    </div>

</div>
</main>

<?php include __DIR__ . '/includes/footer.php'; ?>

<?php if (!empty($despesasPorCategoria)): ?>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.3/dist/chart.umd.min.js"></script>
<script>
const ctx = document.getElementById('graficoDespesas');
new Chart(ctx, {
    type: 'doughnut',
    data: {
        labels: <?= json_encode($graficoCategorias, JSON_UNESCAPED_UNICODE) ?>,
        datasets: [{
            data: <?= json_encode(array_map('floatval', $graficoValores)) ?>,
            backgroundColor: [
                'rgba(124,58,237,0.7)',
                'rgba(57,255,20,0.6)',
                'rgba(249,115,22,0.7)',
                'rgba(167,139,250,0.6)',
                'rgba(251,191,36,0.6)',
                'rgba(239,68,68,0.6)'
            ],
            borderWidth: 1,
            borderColor: '#2d1254',
        }]
    },
    options: {
        responsive: true,
        plugins: {
            legend: {
                position: 'bottom',
                labels: {
                    font: { size: 10, family: 'Orbitron' },
                    color: '#a78bfa',
                    padding: 16,
                    boxWidth: 12,
                }
            },
            tooltip: {
                backgroundColor: '#07000f',
                borderColor: '#2d1254',
                borderWidth: 1,
                titleColor: '#a78bfa',
                bodyColor: '#39ff14',
                titleFont: { family: 'Orbitron', size: 10 },
                bodyFont: { family: 'Share Tech Mono', size: 12 },
                callbacks: {
                    label: (ctx) => '  R$ ' + ctx.parsed.toLocaleString('pt-BR', {minimumFractionDigits:2})
                }
            }
        }
    }
});
</script>
<?php endif; ?>
