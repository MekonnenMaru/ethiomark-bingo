<?php
session_start();

if (!isset($_SESSION['loggedin']) || ($_SESSION['role'] ?? '') !== 'support_cashier') {
    header('Location: support_login.php');
    exit;
}

include_once '../config/Database.php';
require_once '../config/SupportCashierSchema.php';

$db = Database::getInstance();
$conn = $db->getConnection();
support_cashier_ensure_defaults($conn, (string) ($_SESSION['main_cashier_id'] ?? ''));
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Support Interface</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <script src="../bootstrap/js/jquery.js"></script>
    <style>
        :root { 
            --support-color: #FF5733; /* Default, will be updated via JS */
            --box-size: 55px; 
            --box-font: 0.9rem;
        }
        
        body { background: #1a3a4a; font-family: Arial; color: white; margin: 0; padding: 10px; }

        #loader {
            position: fixed;
            top: 50px;              /* distance from the top */
            left: 50%;              /* center horizontally */
            transform: translateX(-50%); /* shift back half its width */
            background: rgba(0,0,0,0.8);
            color: red;
            padding: 10px 20px;
            border-radius: 8px;
            font-weight: 900;
            font-size: 20px;
            display: none;          /* hidden by default */
            z-index: 9999;
            box-shadow: 0 4px 10px rgba(0,0,0,0.3);
        }

        
        #circledNumbers { display: grid; grid-template-columns: repeat(auto-fill, minmax(var(--box-size), 1fr)); gap: 6px; }

        .box {
            aspect-ratio: 1/1; background: #2c3e50; border-radius: 6px;
            display: flex; align-items: center; justify-content: center;
            font-weight: bold; font-size: var(--box-font); cursor: pointer;
            transition: 0.2s;
        }

        .box.mine {
            background: linear-gradient(135deg, var(--support-color), #ff9966) !important;
            box-shadow: 0 0 10px var(--support-color); border: 2px solid white; color: #1a3a4a;
        }

        .box.locked {
            background: #721c24 !important;
            border: 1px solid #f5c6cb;
            opacity: 0.7; 
            cursor: not-allowed;
            pointer-events: none;
            position: relative;
            color: rgba(255, 255, 255, 0.4);
        }

        .box.locked::after {
            content: "🔒";
            font-size: 1rem;
            position: absolute;
            top: -10px;
            color: white;
            right: 2px;
            background: rgba(0, 0, 0, 0.3);
            border-radius: 50%;
            width: 16px;
            height: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .header { background: rgba(0,0,0,0.3); padding: 12px; border-radius: 12px; margin-bottom: 10px; }
        .controls { background: rgba(255,255,255,0.1); padding: 8px; border-radius: 8px; }
        .pagination { display: flex; justify-content: center; gap: 8px; margin: 15px 0; }
        .page-btn { background: #077C6C; border: none; color: white; padding: 8px; border-radius: 4px; }
        .page-btn:disabled { background: var(--support-color); }
        .footer-actions { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .btn { padding: 14px; border: none; border-radius: 8px; font-weight: bold; color: white; cursor: pointer; }
        
        .header-top {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }

        .btn-logout {
            background: rgba(220, 53, 69, 0.2);
            border: 1px solid #dc3545;
            color: #ff6b6b;
            padding: 5px 12px;
            border-radius: 6px;
            text-decoration: none;
            font-size: 0.8rem;
            font-weight: bold;
            transition: 0.3s;
        }

        .btn-logout:hover {
            background: #dc3545;
            color: white;
        }
        
        .sync-switch {
            display: flex;
            align-items: center;
            background: rgba(0,0,0,0.2);
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.65rem;
            cursor: pointer;
            border: 1px solid rgba(255,255,255,0.1);
        }
        
        .sync-switch input { display: none; }
        .sync-switch .slider {
            width: 30px; height: 15px; background: #444;
            display: inline-block; border-radius: 15px;
            position: relative; margin-right: 5px;
        }
        
        .sync-switch .slider::before {
            content: ''; position: absolute; width: 11px; height: 11px;
            background: white; border-radius: 50%; top: 2px; left: 2px;
            transition: 0.3s;
        }
        
        .sync-switch input:checked + .slider { background: var(--support-color); }
        .sync-switch input:checked + .slider::before { left: 17px; }
        
        .toast {
            position: fixed;
            top: 10px;
            left: 50%;
            transform: translateX(-50%);
            background: green;
            color: white;
            padding: 5px 10px;
            border-radius: 10px;
            font-weight: bold;
            display: none;
            z-index: 10000;
            box-shadow: 0 5px 15px rgba(0,0,0,0.3);
            border: 2px solid white;
        }
    </style>
</head>
<body>
    <div id="loader"><span>Syncing...</span></div>
    <div id="toast" class="toast"></div>

    <div class="header">
        <div class="header-top">
            <div style="font-weight:bold; color:var(--support-color)">
                👤 <span id="supportId"></span>
                <span id="roundBadge" style="background:rgba(255,255,255,0.2); padding:2px 8px; border-radius:10px; margin-left:10px; font-size:0.8rem">
                    Rnd: <span id="currentRound">1</span>
                </span>
            </div>
            <a href="javascript:void(0)" onclick="logout()" class="btn-logout">🚪 Logout</a>
        </div>
        
        <div class="controls">
            <div style="display:flex; align-items:center; gap:10px">
                <label style="font-size:0.6rem; opacity:0.8">GRID SIZE</label>
                <input type="range" id="sizeRange" min="30" max="90" value="55" oninput="adjustSize(this.value)" style="width:100%">
            </div>
            
            <div style="display:flex; justify-content:space-between; align-items:center; margin-top:8px">
                <label class="sync-switch">
                    <input type="checkbox" id="autoSyncToggle" onchange="toggleAutoSync(this.checked)">
                    <span class="slider"></span>
                    <span id="syncModeLabel">Sync on Click</span>
                </label>

                <div style="font-size:0.75rem">
                    Mine: <b id="selCount">0</b> | <span id="syncStatus">🟢 Live</span>
                </div>
            </div>
        </div>
    </div>

    <div id="circledNumbers"></div>
    <div class="pagination" id="paginationControls"></div>

    <div class="footer-actions">
        <button class="btn" style="background:#dc3545" onclick="clearAllSelections()">🗑️ Clear Mine</button>
        <button class="btn" style="background:#28a745" onclick="refreshData()">🔄 Manual Refresh</button>
    </div>

    <script>
        const API_URL = 'supporter_interface_backend.php';
        
        let config = {
            mainId: '',
            suppId: '',
            supportColor: '#FF5733',
            round: 1,
            total: 100,
            perPage: 150
        };
        
        let mySelections = [];
        let otherSelections = [];
        let currentPage = 1;
        let syncInterval = null;
        
        // Utility functions
        function showToast(message) {
            const toast = document.getElementById('toast');
            toast.textContent = message;
            toast.style.display = 'block';
            setTimeout(() => toast.style.display = 'none', 2000);
        }
        
        function adjustSize(val) {
            localStorage.setItem('support_grid_size', val);
            document.documentElement.style.setProperty('--box-size', val + 'px');
            document.documentElement.style.setProperty('--box-font', 
                val < 40 ? '0.65rem' : (val < 55 ? '0.8rem' : '1rem'));
        }
        
        function toggleAutoSync(isAuto) {
            localStorage.setItem('support_auto_sync', isAuto);
            document.getElementById('syncModeLabel').textContent = 
                isAuto ? "Auto Sync (5s)" : "Sync on Click";
            
            if (syncInterval) clearInterval(syncInterval);
            if (isAuto) {
                syncInterval = setInterval(() => refreshData(true), 5000);
            }
        }
        
        // API Functions
        async function apiCall(action, data = {}) {
            const formData = new FormData();
            formData.append('action', action);
            
            for (const [key, value] of Object.entries(data)) {
                formData.append(key, value);
            }
            
            try {
                const response = await fetch(API_URL, {
                    method: 'POST',
                    body: formData
                });
                
                return await response.json();
            } catch (error) {
                console.error('API Error:', error);
                showToast('❌ Connection error');
                return { success: false };
            }
        }
        
        async function loadInitialData() {
            $('#loader').show();
            
            const result = await apiCall('init');
            
            if (result.success) {
                config.mainId = result.main_cashier_id;
                config.suppId = result.support_cashier_id;
                config.supportColor = result.support_color;
                config.round = result.current_round;
                config.total = result.total_cards;
                
                // Update UI
                document.getElementById('supportId').textContent = config.suppId;
                document.getElementById('currentRound').textContent = config.round;
                document.documentElement.style.setProperty('--support-color', config.supportColor);
                document.getElementById('roundBadge').style.color = config.supportColor;
                
                // Load selections
                await refreshData(true);
            } else if (result.redirect) {
                window.location.href = result.redirect;
            }
            
            $('#loader').hide();
        }
        
        async function refreshData(silent = false) {
            if (!silent) $('#loader').show();
            
            const result = await apiCall('get_data');
            
            if (result.success) {
                // Check for round change
                if (result.current_round !== config.round) {
                    config.round = result.current_round;
                    showToast("🔄 New Round Started: #" + config.round);
                    document.getElementById('currentRound').textContent = config.round;
                }
                
                mySelections = result.mine.map(Number);
                otherSelections = result.others.map(Number);
                
                renderGrid();
                document.getElementById('selCount').textContent = mySelections.length;
                document.getElementById('syncStatus').textContent = "🟢 Round " + config.round;
            }
            
            if (!silent) $('#loader').hide();
        }
        
        async function toggleSelection(number) {
            if (otherSelections.includes(number)) {
                showToast("🔒 Already taken!");
                return;
            }
            
            $('#loader').show();
            
            const result = await apiCall('toggle_selection', {
                cartela_number: number,
                round_number: config.round
            });
            
            console.log(result);
            
            if (result.success) {
                // Refresh data to get updated selections
                await refreshData(true);
                showToast(result.message || '✅ Updated');
            } else {
                if (result.game_status === "completed") {
                    showToast('⚠️ Round completed!');
                    await refreshData(true);
                } else {
                    showToast(result.message || '⚠️ Operation failed');
                }
            }
            
            $('#loader').hide();
        }
        
        async function clearAllSelections() {
            if (!confirm("Are you sure you want to clear YOUR selections?")) return;
            
            $('#loader').show();
            const result = await apiCall('clear_all', {
                round_number: config.round
            });
            
            if (result.success) {
                await refreshData(true);
                showToast(result.message || '✅ Cleared all selections');
            } else {
                showToast(result.message || '❌ Failed to clear');
            }
            
            $('#loader').hide();
        }
        
        // Render functions (same as before)
        function renderGrid() {
            const container = document.getElementById("circledNumbers");
            if (!container) return;
            
            container.innerHTML = "";
            const start = (currentPage - 1) * config.perPage + 1;
            const end = Math.min(start + config.perPage - 1, config.total);
            
            for (let i = start; i <= end; i++) {
                const box = document.createElement("div");
                let stateClass = "";
                
                if (mySelections.includes(i)) {
                    stateClass = "mine";
                } else if (otherSelections.includes(i)) {
                    stateClass = "locked";
                }
                
                box.className = "box " + stateClass;
                box.textContent = i;
                box.onclick = () => toggleSelection(i);
                container.appendChild(box);
            }
            
            renderPagination();
        }
        
        function renderPagination() {
            const controls = document.getElementById("paginationControls");
            controls.innerHTML = "";
            const totalPages = Math.ceil(config.total / config.perPage);
            
            if (totalPages <= 1) return;
            
            for (let i = 1; i <= totalPages; i++) {
                const btn = document.createElement("button");
                btn.className = "page-btn";
                btn.textContent = i;
                btn.disabled = (i === currentPage);
                btn.onclick = () => {
                    currentPage = i;
                    renderGrid();
                    window.scrollTo(0, 0);
                };
                controls.appendChild(btn);
            }
        }
        
        async function logout() {
            if (confirm('Log out now?')) {
                await apiCall('logout');
                window.location.href = 'support_login.php';
            }
        }
        
        // Initialize
        $(document).ready(() => {
            // Restore settings
            const savedSize = localStorage.getItem('support_grid_size') || 55;
            document.getElementById('sizeRange').value = savedSize;
            adjustSize(savedSize);
            
            const savedSync = localStorage.getItem('support_auto_sync') === 'true';
            document.getElementById('autoSyncToggle').checked = savedSync;
            toggleAutoSync(savedSync);
            
            // Load initial data
            loadInitialData();
        });
        
        window.refreshData = refreshData;
    </script>
</body>
</html>