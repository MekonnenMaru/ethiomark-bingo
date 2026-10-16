<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Supportive cashiers should have role "support_cashier"
// if (!isset($_SESSION['loggedin']) || $_SESSION['role'] != "support_cashier") {
//     header("Location: ../config/logout.php");
//     exit();
// }

include_once '../config/Database.php';
require_once '../config/CartelaResolver.php';
require_once '../config/SupportCashierSchema.php';

$db = Database::getInstance();
$conn = $db->getConnection();

$support_cashier_id = $_SESSION['cashier_id'] ?? '';
$main_cashier_id = $_SESSION['main_cashier_id'] ?? ($_GET['main_cashier_id'] ?? '');
support_cashier_ensure_defaults($conn, (string) $main_cashier_id);
$round_number = $_GET['round_number'] ?? 1;

// Get cashier's category and color
$cashier_query = "SELECT category FROM cashier WHERE cashier_id = ?";
$stmt = $conn->prepare($cashier_query);
$stmt->bind_param("s", $support_cashier_id);
$stmt->execute();
$result = $stmt->get_result();
$cashier_data = $result->fetch_assoc();
$cashier_category = $cashier_data['category'] ?? 'general';
$cashier_color = $cashier_data['color_code'] ?? '#FF5733';

// Total cards: file when category exists in card_datas_new.json, else cartela table
$total_cards = cartela_count_for_cashier($conn, $support_cashier_id);

// Get already selected numbers by this supportive cashier
$selected_numbers = [];
if ($main_cashier_id && $round_number) {
    $selected_query = "SELECT cartela_number FROM collaborative_selections 
                       WHERE main_cashier_id = ? AND support_cashier_id = ? 
                       AND round_number = ? AND is_selected = 1";
    $stmt = $conn->prepare($selected_query);
    $stmt->bind_param("ssi", $main_cashier_id, $support_cashier_id, $round_number);
    $stmt->execute();
    $result = $stmt->get_result();
    while ($row = $result->fetch_assoc()) {
        $selected_numbers[] = $row['cartela_number'];
    }
    $stmt->close();
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Ethiomark - Supportive Cashier</title>
    <meta name="viewport" content="width=1280, user-scalable=no">
    <link rel="stylesheet" href="../bootstrap/css/style.css">
    <link rel="stylesheet" href="../bootstrap/css/register_new_game.css">
    <script src="../bootstrap/js/jquery.js"></script>
    <style>
        /* Supportive cashier specific styles */
        .support-header {
            background: linear-gradient(135deg, #077C6C, #4ECDC4);
            color: white;
            padding: 15px;
            border-radius: 10px;
            margin-bottom: 20px;
            text-align: center;
        }
        
        .support-info {
            display: flex;
            justify-content: space-around;
            margin: 10px 0;
            background: rgba(255,255,255,0.1);
            padding: 10px;
            border-radius: 5px;
        }
        
        .support-stats {
            display: flex;
            gap: 20px;
            justify-content: center;
            margin: 15px 0;
        }
        
        .stat-box {
            background: rgba(255,255,255,0.1);
            padding: 10px 20px;
            border-radius: 5px;
            font-size: 18px;
        }
        
        .support-alert {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1000;
            padding: 15px 20px;
            border-radius: 5px;
            color: white;
            display: none;
            animation: slideIn 0.3s ease;
        }
        
        @keyframes slideIn {
            from { transform: translateX(100%); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }
        
        .connected-status {
            display: inline-block;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            margin-right: 5px;
        }
        
        .connected {
            background-color: #4CAF50;
            animation: pulse 2s infinite;
        }
        
        .disconnected {
            background-color: #f44336;
        }
        
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
        
        .box {
            cursor: pointer;
            transition: all 0.2s;
        }
        
        .box.snum {
            background-color: <?php echo $cashier_color; ?> !important;
            transform: scale(1.05);
            box-shadow: 0 0 10px <?php echo $cashier_color; ?>;
        }
        
        .box:hover {
            transform: scale(1.05);
            box-shadow: 0 0 10px white;
        }
    </style>
</head>
<body>
    <div id="supportAlert" class="support-alert"></div>
    
    <div class="support-header">
        <h1 style="margin: 0; font-size: 32px;">👥 Supportive Cashier Interface</h1>
        <div class="support-info">
            <div>
                <strong>Your ID:</strong> <?php echo $support_cashier_id; ?>
                <span style="background: <?php echo $cashier_color; ?>; padding: 2px 8px; border-radius: 3px; margin-left: 10px;">Your Color</span>
            </div>
            <div>
                <strong>Main Cashier:</strong> <?php echo $main_cashier_id ?: 'Not connected'; ?>
            </div>
            <div>
                <strong>Round:</strong> <?php echo $round_number; ?>
            </div>
        </div>
        
        <div class="support-stats">
            <div class="stat-box" id="selectedCount">Selected: 0</div>
            <div class="stat-box" id="connectionStatus">
                <span class="connected-status disconnected"></span> Connection
            </div>
            <div class="stat-box" id="lastUpdate">Last: --:--</div>
        </div>
    </div>
    
    <div class="main-content" style="padding: 20px;">
        <div id="circledNumbers" class="container"></div>
        <div class="next" id="pagination">
            <button onclick="previousPage()">Previous</button>
            <div id="pageButtons"></div>
            <button onclick="nextPage()">Next</button>
        </div>
        <p style="display: none;" id="totalcard"><?php echo $total_cards ?: 200; ?></p>
        
        <div style="text-align: center; margin-top: 30px;">
            <button class="login-btn" onclick="clearAllSelections()" style="background-color: #BB191A; width: 200px;">
                Clear All Selections
            </button>
        </div>
    </div>
    
    <script>
        // Configuration
        const supportCashierId = '<?php echo $support_cashier_id; ?>';
        const mainCashierId = '<?php echo $main_cashier_id; ?>';
        const roundNumber = <?php echo $round_number; ?>;
        const cashierColor = '<?php echo $cashier_color; ?>';
        
        let selectedNumbers = <?php echo json_encode($selected_numbers); ?>;
        let eventSource = null;
        
        // Number display and pagination
        const circledNumbers = document.getElementById("circledNumbers");
        const totalNumbers = parseInt(document.getElementById("totalcard").innerText);
        const numbersPerPage = 200;
        const totalPages = Math.ceil(totalNumbers / numbersPerPage);
        
        let currentPage = 1;
        
        function generateNumbers(startIndex) {
            circledNumbers.innerHTML = "";
            for (let i = startIndex; i < startIndex + numbersPerPage && i <= totalNumbers; i++) {
                const number = document.createElement("div");
                number.classList.add("box");
                number.textContent = i;
                number.setAttribute("numb", i);
                
                if (selectedNumbers.includes(i)) {
                    number.classList.add("snum");
                }
                
                number.onclick = () => toggleSelection(i);
                circledNumbers.appendChild(number);
            }
            updateSelectedCount();
        }
        
        function showPage(page) {
            currentPage = page;
            const startIndex = (page - 1) * numbersPerPage + 1;
            generateNumbers(startIndex);
            updatePagination();
        }
        
        function updatePagination() {
            const pageButtonsContainer = document.getElementById("pageButtons");
            pageButtonsContainer.innerHTML = "";
            
            for (let i = 1; i <= totalPages; i++) {
                const button = document.createElement("button");
                button.textContent = i;
                button.onclick = () => showPage(i);
                if (i === currentPage) {
                    button.disabled = true;
                    button.style.background = "#077C6C";
                }
                pageButtonsContainer.appendChild(button);
            }
        }
        
        function previousPage() {
            if (currentPage > 1) {
                showPage(currentPage - 1);
            }
        }
        
        function nextPage() {
            if (currentPage < totalPages) {
                showPage(currentPage + 1);
            }
        }
        
        // Selection functions
        function toggleSelection(number) {
            const element = document.querySelector(`[numb="${number}"]`);
            const isSelected = selectedNumbers.includes(number);
            
            if (isSelected) {
                // Deselect
                selectedNumbers = selectedNumbers.filter(n => n !== number);
                element.classList.remove('snum');
                sendSelectionToServer(number, false);
            } else {
                // Select
                selectedNumbers.push(number);
                element.classList.add('snum');
                sendSelectionToServer(number, true);
            }
            
            updateSelectedCount();
        }
        
        function clearAllSelections() {
            if (confirm("Are you sure you want to clear all your selections?")) {
                // Send bulk deselect to server
                $.ajax({
                    type: 'POST',
                    url: '../config/support_update.php',
                    data: {
                        action: 'clear_all',
                        main_cashier_id: mainCashierId,
                        support_cashier_id: supportCashierId,
                        round_number: roundNumber
                    },
                    success: function(resp) {
                        // Clear locally
                        selectedNumbers.forEach(number => {
                            const element = document.querySelector(`[numb="${number}"]`);
                            if (element) {
                                element.classList.remove('snum');
                            }
                        });
                        selectedNumbers = [];
                        updateSelectedCount();
                        showAlert('All selections cleared', 'success');
                    }
                });
            }
        }
        
        function updateSelectedCount() {
            document.getElementById('selectedCount').textContent = `Selected: ${selectedNumbers.length}`;
        }
        
        // Server communication
        function sendSelectionToServer(number, isSelected) {
            if (!mainCashierId || !roundNumber) {
                showAlert('Not connected to main cashier', 'error');
                return;
            }
            
            $.ajax({
                type: 'POST',
                url: '../config/support_update.php',
                data: {
                    action: isSelected ? 'select' : 'deselect',
                    main_cashier_id: mainCashierId,
                    support_cashier_id: supportCashierId,
                    cartela_number: number,
                    round_number: roundNumber
                },
                dataType: 'json',
                success: function(resp) {
                    if (!resp.success) {
                        showAlert(resp.message, 'error');
                        // Revert selection on error
                        const element = document.querySelector(`[numb="${number}"]`);
                        if (isSelected) {
                            selectedNumbers = selectedNumbers.filter(n => n !== number);
                            element.classList.remove('snum');
                        } else {
                            selectedNumbers.push(number);
                            element.classList.add('snum');
                        }
                        updateSelectedCount();
                    } else {
                        updateLastUpdateTime();
                    }
                },
                error: function() {
                    showAlert('Network error. Please check connection.', 'error');
                }
            });
        }
        
        // Real-time updates from server (optional - for seeing other supportive cashiers)
        function startRealTimeUpdates() {
            if (eventSource) {
                eventSource.close();
            }
            
            eventSource = new EventSource(`../config/support_events.php?main_cashier_id=${mainCashierId}&round_number=${roundNumber}&support_cashier_id=${supportCashierId}`);
            
            eventSource.onmessage = function(event) {
                const data = JSON.parse(event.data);
                updateConnectionStatus(true);
                updateLastUpdateTime();
                
                // You could update to show other supportive cashiers' selections
                // This is optional for supportive cashiers
            };
            
            eventSource.onerror = function() {
                updateConnectionStatus(false);
                setTimeout(startRealTimeUpdates, 5000);
            };
        }
        
        function updateConnectionStatus(connected) {
            const statusElement = document.getElementById('connectionStatus');
            const dot = statusElement.querySelector('.connected-status');
            
            if (connected) {
                dot.className = 'connected-status connected';
                statusElement.innerHTML = '<span class="connected-status connected"></span> Connected';
            } else {
                dot.className = 'connected-status disconnected';
                statusElement.innerHTML = '<span class="connected-status disconnected"></span> Disconnected';
            }
        }
        
        function updateLastUpdateTime() {
            const now = new Date();
            const timeStr = now.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
            document.getElementById('lastUpdate').textContent = `Last: ${timeStr}`;
        }
        
        // Alert system
        function showAlert(message, type) {
            const alertDiv = document.getElementById('supportAlert');
            alertDiv.textContent = message;
            alertDiv.style.display = 'block';
            
            switch(type) {
                case 'success':
                    alertDiv.style.background = '#4CAF50';
                    break;
                case 'error':
                    alertDiv.style.background = '#f44336';
                    break;
                case 'warning':
                    alertDiv.style.background = '#FF9800';
                    break;
                default:
                    alertDiv.style.background = '#2196F3';
            }
            
            setTimeout(() => {
                alertDiv.style.display = 'none';
            }, 3000);
        }
        
        // Keyboard support
        let typedNumber = "";
        document.addEventListener("keydown", function(event) {
            if (event.key >= "0" && event.key <= "9") {
                typedNumber += event.key;
            } else if (event.key === "Backspace") {
                typedNumber = typedNumber.slice(0, -1);
            } else if (event.key === "Enter" || event.key === " ") {
                event.preventDefault();
                if (typedNumber !== "") {
                    const number = parseInt(typedNumber);
                    if (!isNaN(number) && number >= 1 && number <= totalNumbers) {
                        toggleSelection(number);
                    } else {
                        showAlert(`Invalid number: ${typedNumber}. Must be between 1 and ${totalNumbers}`, 'error');
                    }
                    typedNumber = "";
                }
            }
        });
        
        // Initialize
        $(document).ready(function() {
            showPage(1);
            updateSelectedCount();
            updateLastUpdateTime();
            
            if (mainCashierId) {
                startRealTimeUpdates();
                showAlert(`Connected to main cashier: ${mainCashierId}`, 'success');
            } else {
                showAlert('Not connected to main cashier. Please check the URL.', 'warning');
            }
        });
    </script>
</body>
</html>