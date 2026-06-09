<?php
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/config/database.php';
requireLogin();

$pageTitle = 'Relatórios — Controle Financeiro';
$user = currentUser();
$db   = getDB();

// Período selecionado (padrão: últimos 6 meses)
$periodo = (int)($_GET['periodo'] ?? 6);
if (!in_array($periodo, [3, 6, 12])) $periodo = 6;

// Evolução mensal
$stmt = $db->prepare("
    SELECT
        DATE_FORMAT(data, '%Y-%m')   AS mes,
        DATE_FORMAT(data, '%m/%Y')   AS mes_label,
        SUM(CASE WHEN tipo='receita' THEN valor ELSE 0 END) AS receitas,
        SUM(CASE WHEN tipo='despesa' THEN valor ELSE 0 END) AS despesas
    FROM transacoes
    WHERE usuario_id = ?
      AND data >= DATE_FORMAT(DATE_SUB(NOW(), INTERVAL ? MONTH), '%Y-%m-01')
    GROUP BY DATE_FORMAT(data, '%Y-%m')
    ORDER BY mes ASC
");
$stmt->execute([$user['id'], $periodo - 1]);
$evolucao = $stmt->fetchAll();

// Top categorias de despesa no período
$stmt = $db->prepare("
    SELECT COALESCE(c.nome, 'Sem categoria') AS categoria, SUM(t.valor) AS total
    FROM transacoes t
    LEFT JOIN categorias c ON c.id = t.categoria_id
    WHERE t.usuario_id = ? AND t.tipo = 'despesa'
      AND t.data >= DATE_FORMAT(DATE_SUB(NOW(), INTERVAL ? MONTH), '%Y-%m-01')
    GROUP BY c.id, c.nome
    ORDER BY total DESC
    LIMIT 6
");
$stmt->execute([$user['id'], $periodo - 1]);
$topCategorias = $stmt->fetchAll();

// Totais do período
$stmt = $db->prepare("
    SELECT
        COALESCE(SUM(CASE WHEN tipo='receita' THEN valor END), 0) AS total_receitas,
        COALESCE(SUM(CASE WHEN tipo='despesa' THEN valor END), 0) AS total_despesas
    FROM transacoes
    WHERE usuario_id = ?
      AND data >= DATE_FORMAT(DATE_SUB(NOW(), INTERVAL ? MONTH), '%Y-%m-01')
");
$stmt->execute([$user['id'], $periodo - 1]);
$totaisPeriodo = $stmt->fetch();
$saldoPeriodo  = $totaisPeriodo['total_receitas'] - $totaisPeriodo['total_despesas'];

$meses      = array_column($evolucao, 'mes_label');
$valReceitas = array_map('floatval', array_column($evolucao, 'receitas'));
$valDespesas = array_map('floatval', array_column($evolucao, 'despesas'));
$catNomes    = array_column($topCategorias, 'categoria');
$catValores  = array_map('floatval', array_column($topCategorias, 'total'));

include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/navbar.php';
?>

<main class="py-4">
<div class="container-fluid px-4">

    <!-- Cabeçalho + filtro de período -->
    <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
        <div>
            <h1 class="page-title mb-0">Relatórios</h1>
            <p class="page-subtitle mb-0">Análise do período selecionado</p>
        </div>
        <div class="d-flex gap-2">
            <?php foreach ([3 => '3 meses', 6 => '6 meses', 12 => '12 meses'] as $v => $l): ?>
                <a href="?periodo=<?= $v ?>"
                   class="btn btn-sm <?= $periodo === $v ? 'btn-primary' : 'btn-outline-secondary' ?>">
                    <?= $l ?>
                </a>
            <?php endforeach; ?>
        </div>
    </div>

    <!-- Cards resumo do período -->
    <div class="row g-3 mb-4">
        <div class="col-12 col-sm-4">
            <div class="card summary-card">
                <div class="card-body d-flex align-items-center gap-3 py-3">
                    <div class="summary-icon"><i class="bi bi-arrow-down text-success"></i></div>
                    <div>
                        <p class="page-subtitle mb-1">// Total Entradas</p>
                        <p class="fw-semibold mb-0 fs-6 text-success" style="font-family:'Share Tech Mono',monospace;">
                            R$ <?= number_format($totaisPeriodo['total_receitas'], 2, ',', '.') ?>
                        </p>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-12 col-sm-4">
            <div class="card summary-card">
                <div class="card-body d-flex align-items-center gap-3 py-3">
                    <div class="summary-icon"><i class="bi bi-arrow-up text-danger"></i></div>
                    <div>
                        <p class="page-subtitle mb-1">// Total Saídas</p>
                        <p class="fw-semibold mb-0 fs-6 text-danger" style="font-family:'Share Tech Mono',monospace;">
                            R$ <?= number_format($totaisPeriodo['total_despesas'], 2, ',', '.') ?>
                        </p>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-12 col-sm-4">
            <div class="card summary-card">
                <div class="card-body d-flex align-items-center gap-3 py-3">
                    <div class="summary-icon"><i class="bi bi-wallet2 <?= $saldoPeriodo >= 0 ? 'text-primary' : 'text-danger' ?>"></i></div>
                    <div>
                        <p class="page-subtitle mb-1">// Saldo do Período</p>
                        <p class="fw-semibold mb-0 fs-6 <?= $saldoPeriodo >= 0 ? 'text-primary' : 'text-danger' ?>" style="font-family:'Share Tech Mono',monospace;">
                            R$ <?= number_format($saldoPeriodo, 2, ',', '.') ?>
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Gráficos -->
    <div class="row g-3 mb-4">

        <!-- Evolução mensal (barras) -->
        <div class="col-12 col-lg-7">
            <div class="card h-100">
                <div class="card-header px-3 py-3">
                    <p class="page-title mb-0" style="font-size:0.9rem;">Evolução Mensal</p>
                    <p class="page-subtitle mb-0">Receitas × Despesas</p>
                </div>
                <div class="card-body d-flex align-items-center justify-content-center" style="min-height:280px;">
                    <?php if (empty($evolucao)): ?>
                        <div class="text-center text-muted">
                            <i class="bi bi-bar-chart fs-1 opacity-25 d-block mb-2"></i>
                            <p>Nenhum dado no período</p>
                        </div>
                    <?php else: ?>
                        <canvas id="graficoEvolucao" style="max-height:280px;width:100%;"></canvas>
                    <?php endif; ?>
                </div>
            </div>
        </div>

        <!-- Top categorias (rosca) -->
        <div class="col-12 col-lg-5">
            <div class="card h-100">
                <div class="card-header px-3 py-3">
                    <p class="page-title mb-0" style="font-size:0.9rem;">Top Despesas por Categoria</p>
                    <p class="page-subtitle mb-0">Últimos <?= $periodo ?> meses</p>
                </div>
                <div class="card-body d-flex align-items-center justify-content-center" style="min-height:280px;">
                    <?php if (empty($topCategorias)): ?>
                        <div class="text-center text-muted">
                            <i class="bi bi-pie-chart fs-1 opacity-25 d-block mb-2"></i>
                            <p>Nenhum dado no período</p>
                        </div>
                    <?php else: ?>
                        <canvas id="graficoCategorias" style="max-height:280px;"></canvas>
                    <?php endif; ?>
                </div>
            </div>
        </div>
    </div>

    <!-- Tabela de evolução mensal -->
    <?php if (!empty($evolucao)): ?>
    <div class="card">
        <div class="card-header px-3 py-3">
            <p class="page-title mb-0" style="font-size:0.9rem;">Detalhamento Mensal</p>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead>
                        <tr>
                            <th class="ps-3">Mês</th>
                            <th class="text-end">Entradas</th>
                            <th class="text-end">Saídas</th>
                            <th class="text-end pe-3">Saldo</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($evolucao as $linha):
                            $saldoMes = $linha['receitas'] - $linha['despesas'];
                        ?>
                        <tr>
                            <td class="ps-3 col-data"><?= $linha['mes_label'] ?></td>
                            <td class="text-end text-success fw-semibold">
                                + R$ <?= number_format($linha['receitas'], 2, ',', '.') ?>
                            </td>
                            <td class="text-end text-danger fw-semibold">
                                - R$ <?= number_format($linha['despesas'], 2, ',', '.') ?>
                            </td>
                            <td class="text-end pe-3 fw-bold <?= $saldoMes >= 0 ? 'text-primary' : 'text-danger' ?>">
                                R$ <?= number_format($saldoMes, 2, ',', '.') ?>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                    <tfoot>
                        <tr style="border-top:1px solid var(--eva-border);">
                            <td class="ps-3 fw-semibold" style="font-family:'Orbitron',sans-serif;font-size:0.75rem;">TOTAL</td>
                            <td class="text-end text-success fw-bold">+ R$ <?= number_format($totaisPeriodo['total_receitas'], 2, ',', '.') ?></td>
                            <td class="text-end text-danger fw-bold">- R$ <?= number_format($totaisPeriodo['total_despesas'], 2, ',', '.') ?></td>
                            <td class="text-end pe-3 fw-bold <?= $saldoPeriodo >= 0 ? 'text-primary' : 'text-danger' ?>">
                                R$ <?= number_format($saldoPeriodo, 2, ',', '.') ?>
                            </td>
                        </tr>
                    </tfoot>
                </table>
            </div>
        </div>
    </div>
    <?php endif; ?>

</div>
</main>

<?php include __DIR__ . '/includes/footer.php'; ?>

<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.3/dist/chart.umd.min.js"></script>
<script>
const chartDefaults = {
    color: '#a78bfa',
    borderColor: '#2d1254',
    backgroundColor: 'transparent',
};
Chart.defaults.color = '#6b5f8a';
Chart.defaults.borderColor = 'rgba(45,18,84,0.4)';
Chart.defaults.font.family = "'Share Tech Mono', monospace";

<?php if (!empty($evolucao)): ?>
new Chart(document.getElementById('graficoEvolucao'), {
    type: 'bar',
    data: {
        labels: <?= json_encode($meses, JSON_UNESCAPED_UNICODE) ?>,
        datasets: [
            {
                label: 'Entradas',
                data: <?= json_encode($valReceitas) ?>,
                backgroundColor: 'rgba(57,255,20,0.25)',
                borderColor: 'rgba(57,255,20,0.8)',
                borderWidth: 1,
                borderRadius: 3,
            },
            {
                label: 'Saídas',
                data: <?= json_encode($valDespesas) ?>,
                backgroundColor: 'rgba(249,115,22,0.25)',
                borderColor: 'rgba(249,115,22,0.8)',
                borderWidth: 1,
                borderRadius: 3,
            }
        ]
    },
    options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
            legend: {
                labels: { font: { size: 10, family: 'Orbitron' }, color: '#a78bfa', boxWidth: 12 }
            },
            tooltip: {
                backgroundColor: '#07000f', borderColor: '#2d1254', borderWidth: 1,
                titleColor: '#a78bfa', bodyColor: '#39ff14',
                titleFont: { family: 'Orbitron', size: 10 },
                callbacks: { label: ctx => '  R$ ' + ctx.parsed.y.toLocaleString('pt-BR', {minimumFractionDigits:2}) }
            }
        },
        scales: {
            x: { grid: { color: 'rgba(45,18,84,0.3)' }, ticks: { color: '#6b5f8a', font: { size: 10 } } },
            y: {
                grid: { color: 'rgba(45,18,84,0.3)' },
                ticks: {
                    color: '#6b5f8a', font: { size: 10 },
                    callback: v => 'R$ ' + v.toLocaleString('pt-BR')
                }
            }
        }
    }
});
<?php endif; ?>

<?php if (!empty($topCategorias)): ?>
new Chart(document.getElementById('graficoCategorias'), {
    type: 'doughnut',
    data: {
        labels: <?= json_encode($catNomes, JSON_UNESCAPED_UNICODE) ?>,
        datasets: [{
            data: <?= json_encode($catValores) ?>,
            backgroundColor: [
                'rgba(124,58,237,0.7)','rgba(57,255,20,0.6)','rgba(249,115,22,0.7)',
                'rgba(167,139,250,0.6)','rgba(251,191,36,0.6)','rgba(239,68,68,0.6)'
            ],
            borderWidth: 1, borderColor: '#2d1254',
        }]
    },
    options: {
        responsive: true,
        plugins: {
            legend: { position: 'bottom', labels: { font: { size: 10, family: 'Orbitron' }, color: '#a78bfa', padding: 12, boxWidth: 12 } },
            tooltip: {
                backgroundColor: '#07000f', borderColor: '#2d1254', borderWidth: 1,
                titleColor: '#a78bfa', bodyColor: '#39ff14',
                titleFont: { family: 'Orbitron', size: 10 },
                callbacks: { label: ctx => '  R$ ' + ctx.parsed.toLocaleString('pt-BR', {minimumFractionDigits:2}) }
            }
        }
    }
});
<?php endif; ?>
</script>
