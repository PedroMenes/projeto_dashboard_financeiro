<?php
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/tema.php';
require_once __DIR__ . '/config/database.php';

$tema = getTema();

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
<html lang="pt-BR" data-bs-theme="<?= htmlspecialchars(getBsTheme()) ?>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Login — Controle Financeiro</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;500;600;700;900&family=Share+Tech+Mono&display=swap" rel="stylesheet">
    <link href="/projeto_dashboard_financeiro/assets/css/custom.css" rel="stylesheet">
</head>
<body class="tema-<?= htmlspecialchars($tema) ?> bg-login d-flex align-items-center justify-content-center min-vh-100">

<?php if ($tema === 'eva'): ?>
<canvas id="mechaBg" style="position:fixed;inset:0;width:100%;height:100%;z-index:0;pointer-events:none;"></canvas>
<?php endif; ?>

<div class="card login-card" style="position:relative;z-index:1;">
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
            <span class="page-subtitle" style="font-size:0.82rem;">
                DEMO &nbsp;|&nbsp; admin@financeiro.com &nbsp;/&nbsp; 123456 <span class="blink">_</span>
            </span>
        </div>

    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<?php if ($tema === 'eva'): ?>
<script>
(function () {
    const canvas = document.getElementById('mechaBg');
    const ctx    = canvas.getContext('2d');

    const C = {
        bg:        '#05000d',
        grid:      'rgba(45,18,84,0.35)',
        gridBright:'rgba(91,33,182,0.18)',
        purple:    'rgba(124,58,237,',
        green:     'rgba(57,255,20,',
        amber:     'rgba(251,191,36,',
        scan:      'rgba(57,255,20,0.06)',
        scanLine:  'rgba(57,255,20,0.55)',
        node:      'rgba(124,58,237,0.7)',
        text:      'rgba(57,255,20,',
    };

    const GRID = 48;

    // Linha de scan
    let scanY = 0;

    // Nós pulsantes nas interseções da grade
    let nodes = [];

    // Fragmentos de dados flutuantes
    let dataFrags = [];
    const HEX_CHARS = '0123456789ABCDEF';
    const DATA_STRINGS = [
        'MAGI-01','MAGI-02','MAGI-03','NERV//SYS',
        'EVA-01','UNIT-00','UNIT-02','SEELE//OK',
        'AT FIELD','SYNC 98%','CORE TEMP','PILOT OK',
        'LCL NORM','PWR 100%','ANGEL DET','ALERT LVL',
    ];

    function resize() {
        canvas.width  = window.innerWidth;
        canvas.height = window.innerHeight;
        buildNodes();
    }

    function buildNodes() {
        nodes = [];
        const cols = Math.ceil(canvas.width  / GRID) + 1;
        const rows = Math.ceil(canvas.height / GRID) + 1;
        for (let r = 0; r < rows; r++) {
            for (let c = 0; c < cols; c++) {
                if (Math.random() < 0.18) {
                    nodes.push({
                        x:     c * GRID,
                        y:     r * GRID,
                        phase: Math.random() * Math.PI * 2,
                        speed: 0.4 + Math.random() * 0.8,
                        size:  1 + Math.random() * 2,
                        color: Math.random() < 0.7 ? 'purple' : 'green',
                    });
                }
            }
        }
    }

    function spawnFrag() {
        const isHex = Math.random() < 0.5;
        let text = '';
        if (isHex) {
            const len = 4 + Math.floor(Math.random() * 8);
            for (let i = 0; i < len; i++) text += HEX_CHARS[Math.floor(Math.random() * 16)];
        } else {
            text = DATA_STRINGS[Math.floor(Math.random() * DATA_STRINGS.length)];
        }
        dataFrags.push({
            x:      Math.random() * canvas.width,
            y:      Math.random() * canvas.height,
            text,
            alpha:  0,
            life:   0,
            maxLife: 90 + Math.random() * 120,
            size:   9 + Math.random() * 5,
            color:  Math.random() < 0.6 ? 'green' : 'amber',
        });
    }

    // Linhas de circuito
    let circuits = [];
    function buildCircuits() {
        circuits = [];
        const count = Math.floor((canvas.width * canvas.height) / 60000) + 6;
        for (let i = 0; i < count; i++) {
            const startX = Math.round(Math.random() * (canvas.width  / GRID)) * GRID;
            const startY = Math.round(Math.random() * (canvas.height / GRID)) * GRID;
            const segs   = 3 + Math.floor(Math.random() * 5);
            const pts    = [{ x: startX, y: startY }];
            let cx = startX, cy = startY;
            for (let s = 0; s < segs; s++) {
                const dir = Math.floor(Math.random() * 4);
                const len = (1 + Math.floor(Math.random() * 4)) * GRID;
                if      (dir === 0) cx += len;
                else if (dir === 1) cx -= len;
                else if (dir === 2) cy += len;
                else                cy -= len;
                pts.push({ x: cx, y: cy });
            }
            circuits.push({
                pts,
                progress: 0,
                speed: 0.003 + Math.random() * 0.005,
                alpha: 0.15 + Math.random() * 0.25,
                color: Math.random() < 0.5 ? 'purple' : 'green',
                width: Math.random() < 0.3 ? 1.5 : 0.8,
            });
        }
    }

    // Radar
    const radar = {
        x: 0, y: 0, r: 0,
        angle: 0, speed: 0.008,
        blips: [],
    };
    function initRadar() {
        radar.x = canvas.width  * 0.08;
        radar.y = canvas.height * 0.88;
        radar.r = Math.min(canvas.width, canvas.height) * 0.09;
        radar.blips = [];
        for (let i = 0; i < 4; i++) {
            const a = Math.random() * Math.PI * 2;
            const d = Math.random() * radar.r * 0.85;
            radar.blips.push({ a, d, alpha: Math.random() });
        }
    }

    let frame = 0;

    function draw(ts) {
        requestAnimationFrame(draw);
        const W = canvas.width, H = canvas.height;
        try {
        ctx.clearRect(0, 0, W, H);

        // Fundo
        ctx.fillStyle = C.bg;
        ctx.fillRect(0, 0, W, H);

        // Grade
        ctx.strokeStyle = C.grid;
        ctx.lineWidth   = 0.5;
        ctx.beginPath();
        for (let x = 0; x <= W; x += GRID) { ctx.moveTo(x, 0); ctx.lineTo(x, H); }
        for (let y = 0; y <= H; y += GRID) { ctx.moveTo(0, y); ctx.lineTo(W, y); }
        ctx.stroke();

        // Grade maior (destaque a cada 4 células)
        ctx.strokeStyle = C.gridBright;
        ctx.lineWidth   = 0.8;
        ctx.beginPath();
        for (let x = 0; x <= W; x += GRID * 4) { ctx.moveTo(x, 0); ctx.lineTo(x, H); }
        for (let y = 0; y <= H; y += GRID * 4) { ctx.moveTo(0, y); ctx.lineTo(W, y); }
        ctx.stroke();

        // Linhas de circuito animadas
        circuits.forEach(c => {
            c.progress += c.speed;
            if (c.progress > 1.3) c.progress = 0;

            const total = c.pts.length - 1;
            const drawn = Math.min(Math.max(c.progress * total, 0), total);
            const fullSegs = Math.floor(drawn);

            const col = c.color === 'purple' ? C.purple : C.green;
            ctx.strokeStyle = col + c.alpha + ')';
            ctx.lineWidth   = c.width;
            ctx.shadowColor = col + '0.8)';
            ctx.shadowBlur  = 4;
            ctx.beginPath();
            ctx.moveTo(c.pts[0].x, c.pts[0].y);
            for (let s = 0; s < fullSegs; s++) ctx.lineTo(c.pts[s + 1].x, c.pts[s + 1].y);
            if (fullSegs < total) {
                const frac = drawn - fullSegs;
                const a = c.pts[fullSegs], b = c.pts[fullSegs + 1];
                ctx.lineTo(a.x + (b.x - a.x) * frac, a.y + (b.y - a.y) * frac);
            }
            ctx.stroke();
            ctx.shadowBlur = 0;

            // Ponto de extremidade
            const last = fullSegs < total
                ? { x: c.pts[fullSegs].x + (c.pts[fullSegs+1].x - c.pts[fullSegs].x) * (drawn - fullSegs),
                    y: c.pts[fullSegs].y + (c.pts[fullSegs+1].y - c.pts[fullSegs].y) * (drawn - fullSegs) }
                : c.pts[total];
            ctx.fillStyle   = col + '0.9)';
            ctx.shadowColor = col + '1)';
            ctx.shadowBlur  = 8;
            ctx.beginPath();
            ctx.arc(last.x, last.y, 2.5, 0, Math.PI * 2);
            ctx.fill();
            ctx.shadowBlur = 0;
        });

        // Nós pulsantes
        nodes.forEach(n => {
            const pulse = (Math.sin(frame * n.speed * 0.05 + n.phase) + 1) / 2;
            const a     = 0.15 + pulse * 0.65;
            const col   = n.color === 'purple' ? C.purple : C.green;
            ctx.fillStyle   = col + a + ')';
            ctx.shadowColor = col + '0.8)';
            ctx.shadowBlur  = pulse * 8;
            ctx.beginPath();
            ctx.arc(n.x, n.y, n.size * (0.7 + pulse * 0.5), 0, Math.PI * 2);
            ctx.fill();
            ctx.shadowBlur = 0;
        });

        // Scan line
        scanY += 1.2;
        if (scanY > H) scanY = 0;
        const grad = ctx.createLinearGradient(0, scanY - 60, 0, scanY + 12);
        grad.addColorStop(0,   'rgba(57,255,20,0)');
        grad.addColorStop(0.7, C.scan);
        grad.addColorStop(1,   C.scan);
        ctx.fillStyle = grad;
        ctx.fillRect(0, scanY - 60, W, 72);
        ctx.strokeStyle = C.scanLine;
        ctx.lineWidth   = 1;
        ctx.shadowColor = 'rgba(57,255,20,0.9)';
        ctx.shadowBlur  = 10;
        ctx.beginPath();
        ctx.moveTo(0, scanY); ctx.lineTo(W, scanY);
        ctx.stroke();
        ctx.shadowBlur = 0;

        // Dados flutuantes
        if (frame % 18 === 0 && dataFrags.length < 22) spawnFrag();
        dataFrags = dataFrags.filter(d => d.life < d.maxLife);
        dataFrags.forEach(d => {
            d.life++;
            const prog = d.life / d.maxLife;
            d.alpha = prog < 0.15 ? prog / 0.15 : prog > 0.75 ? (1 - prog) / 0.25 : 1;
            const col = d.color === 'green' ? C.green : C.amber;
            ctx.font        = `${d.size}px "Share Tech Mono", monospace`;
            ctx.fillStyle   = col + (d.alpha * 0.55) + ')';
            ctx.shadowColor = col + d.alpha + ')';
            ctx.shadowBlur  = 4;
            ctx.fillText(d.text, d.x, d.y);
            ctx.shadowBlur  = 0;
        });

        // Radar (canto inferior esquerdo)
        radar.angle = (radar.angle + radar.speed) % (Math.PI * 2);
        const { x: rx, y: ry, r: rr } = radar;

        // Círculos do radar
        ctx.strokeStyle = 'rgba(57,255,20,0.15)';
        ctx.lineWidth   = 0.8;
        [1, 0.66, 0.33].forEach(scale => {
            ctx.beginPath();
            ctx.arc(rx, ry, rr * scale, 0, Math.PI * 2);
            ctx.stroke();
        });
        // Cruzeta
        ctx.strokeStyle = 'rgba(57,255,20,0.12)';
        ctx.beginPath();
        ctx.moveTo(rx - rr, ry); ctx.lineTo(rx + rr, ry);
        ctx.moveTo(rx, ry - rr); ctx.lineTo(rx, ry + rr);
        ctx.stroke();
        // Sweep
        const sweepGrad = ctx.createConicalGradient
            ? null  // fallback abaixo
            : null;
        // Sweep manual (arco + degradê)
        ctx.save();
        ctx.translate(rx, ry);
        ctx.rotate(radar.angle);
        const sg = ctx.createLinearGradient(0, 0, rr, 0);
        sg.addColorStop(0,   'rgba(57,255,20,0.35)');
        sg.addColorStop(1,   'rgba(57,255,20,0)');
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.arc(0, 0, rr, -0.6, 0);
        ctx.closePath();
        ctx.fillStyle = sg;
        ctx.fill();
        ctx.restore();
        // Contorno
        ctx.strokeStyle = 'rgba(57,255,20,0.3)';
        ctx.lineWidth   = 1;
        ctx.shadowColor = 'rgba(57,255,20,0.5)';
        ctx.shadowBlur  = 6;
        ctx.beginPath();
        ctx.arc(rx, ry, rr, 0, Math.PI * 2);
        ctx.stroke();
        ctx.shadowBlur  = 0;
        // Blips
        radar.blips.forEach(b => {
            b.alpha = Math.max(0, b.alpha - 0.008);
            const diff = ((b.a - radar.angle) % (Math.PI * 2) + Math.PI * 2) % (Math.PI * 2);
            if (diff < 0.15) b.alpha = 1;
            if (b.alpha > 0.05) {
                const bx = rx + Math.cos(b.a) * b.d;
                const by = ry + Math.sin(b.a) * b.d;
                ctx.fillStyle   = `rgba(57,255,20,${b.alpha})`;
                ctx.shadowColor = 'rgba(57,255,20,1)';
                ctx.shadowBlur  = 6;
                ctx.beginPath();
                ctx.arc(bx, by, 2.5, 0, Math.PI * 2);
                ctx.fill();
                ctx.shadowBlur = 0;
            }
        });
        // Label
        ctx.font      = '8px "Orbitron", sans-serif';
        ctx.fillStyle = 'rgba(57,255,20,0.35)';
        ctx.fillText('RADAR // NERV', rx - rr * 0.55, ry + rr + 14);

        // Decorações de canto (HUD brackets)
        drawCorner(ctx, 0,         0,          30, 30, 1, 1);
        drawCorner(ctx, W,         0,          30, 30, -1, 1);
        drawCorner(ctx, 0,         H,          30, 30, 1, -1);
        drawCorner(ctx, W,         H,          30, 30, -1, -1);

        // Barra de status (topo direito)
        drawStatusBar(ctx, W, H, frame);

        frame++;
        } catch(e) { console.warn('mechaBg:', e); }
    }

    function drawCorner(ctx, x, y, w, h, sx, sy) {
        const m = 12;
        ctx.strokeStyle = 'rgba(124,58,237,0.6)';
        ctx.lineWidth   = 1.5;
        ctx.shadowColor = 'rgba(124,58,237,0.8)';
        ctx.shadowBlur  = 6;
        ctx.beginPath();
        ctx.moveTo(x + sx * m,   y);
        ctx.lineTo(x + sx * w,   y);
        ctx.moveTo(x,            y + sy * m);
        ctx.lineTo(x,            y + sy * h);
        ctx.stroke();
        ctx.shadowBlur = 0;
        // Pequeno quadrado no canto
        ctx.fillStyle = 'rgba(124,58,237,0.5)';
        ctx.fillRect(x + (sx > 0 ? 0 : -4), y + (sy > 0 ? 0 : -4), 4, 4);
    }

    function drawStatusBar(ctx, W, H, frame) {
        const labels = ['SYNC','POWER','CORE','AT-FLD'];
        const vals   = [98, 100, 87, 73];
        const bw = 90, bh = 6, gap = 22, startX = W - 160, startY = 18;

        ctx.font = '7px "Orbitron", sans-serif';
        labels.forEach((lbl, i) => {
            const y   = startY + i * gap;
            const val = vals[i];
            const col = val > 90 ? 'rgba(57,255,20,' : val > 70 ? 'rgba(251,191,36,' : 'rgba(239,68,68,';

            ctx.fillStyle = 'rgba(124,58,237,0.3)';
            ctx.fillText(lbl, startX, y + 5);

            ctx.fillStyle = 'rgba(45,18,84,0.6)';
            ctx.fillRect(startX + 40, y, bw, bh);

            ctx.fillStyle   = col + '0.8)';
            ctx.shadowColor = col + '1)';
            ctx.shadowBlur  = 4;
            ctx.fillRect(startX + 40, y, bw * (val / 100), bh);
            ctx.shadowBlur = 0;

            ctx.fillStyle = col + '0.6)';
            ctx.fillText(val + '%', startX + 40 + bw + 4, y + 5);
        });
    }

    window.addEventListener('resize', () => { resize(); buildCircuits(); initRadar(); });
    resize();
    buildCircuits();
    initRadar();
    requestAnimationFrame(draw);
})();
</script>
<?php endif; ?>
</body>
</html>
