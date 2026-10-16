<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

if (!isset($_SESSION['loggedin']) || ($_SESSION['role'] ?? '') !== 'admin') {
    header('Location: ../config/logout.php');
    exit;
}

require_once __DIR__ . '/../config/AdminSqlCrypto.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    header('Content-Type: application/json');

    $action = $_POST['action'] ?? 'encrypt';

    if ($action === 'encrypt') {
        $serial   = trim($_POST['serial'] ?? '');
        $plainSql = trim($_POST['plain_sql'] ?? '');
        $package  = trim($_POST['package'] ?? '');

        if ($serial === '') {
            echo json_encode(['ok' => false, 'message' => 'Target machine serial is required.']);
            exit;
        }

        if ($plainSql === '' && $package === '') {
            echo json_encode(['ok' => false, 'message' => 'Enter plain SQL and/or package amount.']);
            exit;
        }

        $encSql     = $plainSql !== '' ? admin_sql_encrypt($plainSql, $serial) : '';
        $encPackage = $package !== '' ? admin_sql_encrypt_package($package, $serial) : '';

        $roundtrip = $plainSql !== '' ? admin_sql_decrypt_debug($encSql, $serial) : '';

        echo json_encode([
            'ok'           => true,
            'enc_sql'      => $encSql,
            'enc_package'  => $encPackage,
            'debug'        => [
                'serial_input'          => $serial,
                'serial_trimmed'        => admin_sql_serial_trimmed($serial),
                'key_preview'           => substr(admin_sql_build_key($serial), 0, 8) . '...',
                'plain_sql'             => $plainSql,
                'encrypted_sql'         => $encSql,
                'decrypted_roundtrip'   => $roundtrip,
                'roundtrip_match'       => $plainSql === '' || $roundtrip === $plainSql,
                'encrypted_package_only'=> $encPackage,
            ],
        ]);
        exit;
    }

    echo json_encode(['ok' => false, 'message' => 'Unknown action.']);
    exit;
}

$sqlTemplates = [
    [
        'label' => 'Deposit to package (adds to current balance)',
        'sql'   => "UPDATE cashier SET cashier_package = '10000' WHERE cashier_id = 'CASHIER_ID';",
    ],
    [
        'label' => 'Withdraw from package (subtracts from current balance)',
        'sql'   => "UPDATE cashier SET cashier_package = '-500' WHERE cashier_id = 'CASHIER_ID';",
    ],
    [
        'label' => 'Change cashier ID',
        'sql'   => "UPDATE cashier SET cashier_id = 'NEW_ID' WHERE cashier_id = 'OLD_ID';",
    ],
    [
        'label' => 'Set partner ID on cashier',
        'sql'   => "UPDATE cashier SET partner_id = 'PARTNER_ID' WHERE cashier_id = 'CASHIER_ID';",
    ],
    [
        'label' => 'Set category',
        'sql'   => "UPDATE cashier SET category = 'CATEGORY' WHERE cashier_id = 'CASHIER_ID';",
    ],
    [
        'label' => 'Reset login attempts / unlock',
        'sql'   => "UPDATE cashier SET login_attempts = '0', is_locked = '0' WHERE cashier_id = 'CASHIER_ID';",
    ],
    [
        'label' => 'Shift ALL transaction dates back 1 day',
        'sql'   => "UPDATE transaction SET date = CURDATE() - INTERVAL 1 DAY WHERE date >= CURDATE();",
    ],
    [
        'label' => 'Shift one cashier transaction dates back 1 day',
        'sql'   => "UPDATE transaction SET date = CURDATE() - INTERVAL 1 DAY WHERE cashier_id = 'CASHIER_ID' AND date >= CURDATE();",
    ],
    [
        'label' => 'Set transaction bonus for round (today)',
        'sql'   => "UPDATE transaction SET bonus = '50' WHERE cashier_id = 'CASHIER_ID' AND game_round = '1' AND DATE(date) = CURDATE();",
    ],
    [
        'label' => 'Mark game round incomplete',
        'sql'   => "UPDATE game SET iscompleted = '0' WHERE cashier_id = 'CASHIER_ID' AND round_number = '1';",
    ],
    [
        'label' => 'Clear locked cartelas for round',
        'sql'   => "UPDATE game SET locked_cartela_number = '' WHERE cashier_id = 'CASHIER_ID' AND round_number = '1';",
    ],
];
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Encrypt SQL — Admin</title>
    <link rel="stylesheet" href="../bootstrap/css/style.css">
    <script src="../bootstrap/js/jquery.js"></script>
    <style>
        body { background: #1a1f2e; color: #e2e8f0; margin: 0; font-family:Segoe UI, sans-serif; }
        .wrap { max-width: 1100px; margin: 0 auto; padding: 24px; }
        h1 { margin: 0 0 6px; font-size: 26px; }
        .sub { color: #94a3b8; margin-bottom: 24px; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .panel {
            background: #111827; border: 1px solid #334155; border-radius: 10px; padding: 18px;
        }
        .panel h2 { margin: 0 0 14px; font-size: 16px; color: #38bdf8; }
        label { display: block; font-size: 13px; color: #94a3b8; margin: 12px 0 6px; }
        input, textarea, select {
            width: 100%; box-sizing: border-box; background: #0b1220; border: 1px solid #475569;
            border-radius: 6px; color: #f1f5f9; padding: 10px 12px; font-size: 14px;
        }
        textarea { min-height: 140px; font-family: Consolas, Monaco, monospace; resize: vertical; }
        .btn-row { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 16px; }
        .btn {
            border: none; border-radius: 6px; padding: 10px 16px; font-weight: 600;
            cursor: pointer; font-size: 14px;
        }
        .btn-primary { background: #2563eb; color: #fff; }
        .btn-success { background: #166534; color: #bbf7d0; }
        .btn-secondary { background: #334155; color: #e2e8f0; }
        .hint { font-size: 12px; color: #64748b; margin-top: 6px; }
        .quick-list { max-height: 320px; overflow: auto; display: flex; flex-direction: column; gap: 8px; }
        .quick-item {
            display: flex; justify-content: space-between; align-items: center; gap: 10px;
            background: #0b1220; border: 1px solid #1e293b; border-radius: 6px; padding: 8px 10px;
        }
        .quick-item span { font-size: 12px; color: #cbd5e1; flex: 1; }
        .quick-item button { flex-shrink: 0; padding: 4px 10px; font-size: 11px; }
        .debug-log {
            margin-top: 16px; background: #000; border: 1px solid #334155; border-radius: 6px;
            padding: 12px; font-family: Consolas, monospace; font-size: 12px; color: #94a3b8;
            max-height: 200px; overflow: auto; white-space: pre-wrap;
        }
        .flow {
            background: #0f172a; border-left: 3px solid #38bdf8; padding: 12px 14px;
            border-radius: 0 6px 6px 0; margin-bottom: 20px; font-size: 13px; color: #cbd5e1;
        }
        @media (max-width: 900px) { .grid { grid-template-columns: 1fr; } }
    </style>
</head>
<body>
    <div class="wrap">
        <h1>Encrypt SQL for Cashier</h1>
        <p class="sub">Admin tool — same key as partner Encr modal (BIOS serial + Youman base key). Cashier pastes result in Settings console.</p>

        <div class="flow">
            <strong>Flow:</strong> Enter target PC BIOS serial → write plain SQL → Encrypt → copy encrypted string →
            cashier opens Settings → paste → Run encrypted SQL.
            <br>Plain <code>cashier_package</code> amounts are <strong>added</strong> to the current balance on the cashier machine (positive = deposit, negative = withdrawal). Use <code>=10000</code> only to force an exact total.
        </div>

        <div class="grid">
            <div class="panel">
                <h2>Encrypt</h2>

                <label for="serial">Target machine BIOS serial (full serial from cashier PC)</label>
                <input type="text" id="serial" placeholder="e.g. PF3ABC12 or use first 2 chars only">

                <label for="plainSql">Plain SQL command</label>
                <textarea id="plainSql" spellcheck="false" placeholder="UPDATE cashier SET cashier_package = '10000' WHERE cashier_id = 'xxx';"></textarea>

                <label for="packageOnly">Package only (optional — encrypted blob without SQL)</label>
                <input type="text" id="packageOnly" placeholder="e.g. 10000">

                <div class="btn-row">
                    <button type="button" class="btn btn-primary" id="encryptBtn">Encrypt</button>
                    <button type="button" class="btn btn-success" id="copySqlBtn">Copy encrypted SQL</button>
                    <button type="button" class="btn btn-secondary" id="copyPkgBtn">Copy encrypted package</button>
                </div>

                <label for="encSql">Encrypted SQL (give to cashier)</label>
                <textarea id="encSql" readonly rows="4" placeholder="Encrypted output..."></textarea>

                <label for="encPackage">Encrypted package only</label>
                <textarea id="encPackage" readonly rows="2" placeholder="Optional package blob..."></textarea>

                <div class="debug-log" id="debugLog">Debug output appears here...</div>
            </div>

            <div class="panel">
                <h2>Quick SQL templates</h2>
                <p class="hint">Click Use → edit CASHIER_ID / values → Encrypt</p>
                <div class="quick-list">
                    <?php foreach ($sqlTemplates as $tpl): ?>
                    <div class="quick-item">
                        <span><?php echo htmlspecialchars($tpl['label'], ENT_QUOTES, 'UTF-8'); ?></span>
                        <button type="button" class="btn btn-secondary quick-use" data-sql="<?php echo htmlspecialchars($tpl['sql'], ENT_QUOTES, 'UTF-8'); ?>">Use</button>
                    </div>
                    <?php endforeach; ?>
                </div>

                <div class="btn-row">
                    <a href="view-partner.php" class="btn btn-secondary" style="text-decoration:none;display:inline-block;">← Back to Partners</a>
                </div>
            </div>
        </div>
    </div>

    <script>
        function logDebug(obj) {
            document.getElementById('debugLog').textContent = JSON.stringify(obj, null, 2);
        }

        document.getElementById('encryptBtn').addEventListener('click', async () => {
            const serial = document.getElementById('serial').value.trim();
            const plainSql = document.getElementById('plainSql').value.trim();
            const pkg = document.getElementById('packageOnly').value.trim();

            if (!serial) {
                alert('Enter target machine BIOS serial.');
                return;
            }
            if (!plainSql && !pkg) {
                alert('Enter plain SQL and/or package amount.');
                return;
            }

            const fd = new FormData();
            fd.append('action', 'encrypt');
            fd.append('serial', serial);
            fd.append('plain_sql', plainSql);
            fd.append('package', pkg);

            const res = await fetch('encrypt-sql.php', { method: 'POST', body: fd });
            const data = await res.json();

            if (!data.ok) {
                alert(data.message || 'Encrypt failed');
                return;
            }

            document.getElementById('encSql').value = data.enc_sql || '';
            document.getElementById('encPackage').value = data.enc_package || '';
            logDebug(data.debug);
        });

        document.getElementById('copySqlBtn').addEventListener('click', () => {
            const v = document.getElementById('encSql').value;
            if (!v) { alert('Nothing to copy'); return; }
            navigator.clipboard.writeText(v);
        });

        document.getElementById('copyPkgBtn').addEventListener('click', () => {
            const v = document.getElementById('encPackage').value;
            if (!v) { alert('Nothing to copy'); return; }
            navigator.clipboard.writeText(v);
        });

        document.querySelectorAll('.quick-use').forEach(btn => {
            btn.addEventListener('click', () => {
                document.getElementById('plainSql').value = btn.getAttribute('data-sql') || '';
                document.getElementById('plainSql').focus();
            });
        });
    </script>
</body>
</html>
