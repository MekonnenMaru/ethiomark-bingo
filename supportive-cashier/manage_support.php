<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

if (!isset($_SESSION['loggedin']) || $_SESSION['role'] != "cashier") {
    header("Location: ../config/logout.php");
    exit();
}

include_once '../config/Database.php';
require_once '../config/SupportCashierSchema.php';

$db = Database::getInstance();
$conn = $db->getConnection();
$main_cashier_id = $_SESSION['cashier_id'];
support_cashier_ensure_defaults($conn, (string) $main_cashier_id);

// Handle adding supportive cashier
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['add_support'])) {
        $support_cashier_id = $_POST['support_cashier_id'] ?? '';
        
        if ($support_cashier_id) {
            // Check if cashier exists in cashier table
            $check_query = "SELECT cashier_id FROM cashier WHERE cashier_id = ?";
            $stmt = $conn->prepare($check_query);
            $stmt->bind_param("s", $support_cashier_id);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows === 1) {
                // Check if not already assigned to someone else
                $existing_query = "SELECT * FROM support_cashiers WHERE support_cashier_id = ? AND main_cashier_id != ?";
                $stmt2 = $conn->prepare($existing_query);
                $stmt2->bind_param("ss", $support_cashier_id, $main_cashier_id);
                $stmt2->execute();
                $existing_result = $stmt2->get_result();
                
                if ($existing_result->num_rows === 0) {
                    // Check if not already assigned to this main cashier
                    $check_duplicate = "SELECT * FROM support_cashiers WHERE main_cashier_id = ? AND support_cashier_id = ?";
                    $stmt3 = $conn->prepare($check_duplicate);
                    $stmt3->bind_param("ss", $main_cashier_id, $support_cashier_id);
                    $stmt3->execute();
                    $duplicate_result = $stmt3->get_result();
                    
                    if ($duplicate_result->num_rows === 0) {
                        // Add as supportive cashier
                        $insert_query = "INSERT INTO support_cashiers (main_cashier_id, support_cashier_id) VALUES (?, ?)";
                        $stmt4 = $conn->prepare($insert_query);
                        $stmt4->bind_param("ss", $main_cashier_id, $support_cashier_id);
                        
                        if ($stmt4->execute()) {
                            // Assign a random color if not exists
                            $colors = ['#FF5733', '#33FF57', '#3357FF', '#F333FF', '#33FFF3', '#FFD733', '#FF33A1', '#33FFA1'];
                            $random_color = $colors[array_rand($colors)];
                            
                            $pref_query = "INSERT IGNORE INTO support_preferences (support_cashier_id, color_code) VALUES (?, ?)";
                            $stmt5 = $conn->prepare($pref_query);
                            $stmt5->bind_param("ss", $support_cashier_id, $random_color);
                            $stmt5->execute();
                            
                            $message = "Supportive cashier added successfully!";
                            $message_type = "success";
                        } else {
                            $message = "Failed to add supportive cashier.";
                            $message_type = "error";
                        }
                    } else {
                        $message = "This cashier is already assigned to you.";
                        $message_type = "error";
                    }
                } else {
                    $message = "This cashier is already assigned to another main cashier.";
                    $message_type = "error";
                }
            } else {
                $message = "Cashier not found.";
                $message_type = "error";
            }
        }
    }
    
    // Handle color change
    if (isset($_POST['change_color'])) {
        $support_id = $_POST['support_id'] ?? '';
        $new_color = $_POST['new_color'] ?? '#FF5733';
        
        if ($support_id && $new_color) {
            // Verify this support cashier belongs to the main cashier
            $verify_query = "SELECT support_cashier_id FROM support_cashiers WHERE id = ? AND main_cashier_id = ?";
            $stmt = $conn->prepare($verify_query);
            $stmt->bind_param("is", $support_id, $main_cashier_id);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows === 1) {
                $support_data = $result->fetch_assoc();
                $support_cashier_id = $support_data['support_cashier_id'];
                
                // Update color
                $color_query = "INSERT INTO support_preferences (support_cashier_id, color_code) 
                               VALUES (?, ?) 
                               ON DUPLICATE KEY UPDATE color_code = ?";
                $stmt2 = $conn->prepare($color_query);
                $stmt2->bind_param("sss", $support_cashier_id, $new_color, $new_color);
                
                if ($stmt2->execute()) {
                    $message = "Color updated successfully!";
                    $message_type = "success";
                }
            }
        }
    }
}

// Handle removing supportive cashier
if (isset($_GET['remove'])) {
    $support_id = $_GET['remove'];
    
    $delete_query = "DELETE FROM support_cashiers WHERE id = ? AND main_cashier_id = ?";
    $stmt = $conn->prepare($delete_query);
    $stmt->bind_param("is", $support_id, $main_cashier_id);
    
    if ($stmt->execute()) {
        $message = "Supportive cashier removed.";
        $message_type = "success";
    }
}

// Get all supportive cashiers for this main cashier
$support_query = "
    SELECT sc.*, sp.color_code 
    FROM support_cashiers sc
    LEFT JOIN support_preferences sp ON sc.support_cashier_id = sp.support_cashier_id
    WHERE sc.main_cashier_id = ? AND sc.is_active = 1
    ORDER BY sc.assigned_date DESC
";
$stmt = $conn->prepare($support_query);
$stmt->bind_param("s", $main_cashier_id);
$stmt->execute();
$support_result = $stmt->get_result();
$support_cashiers = [];
while ($row = $support_result->fetch_assoc()) {
    $support_cashiers[] = $row;
}
$stmt->close();

// Get current round number
$round_query = "SELECT round_number FROM game WHERE cashier_id = ? ORDER BY round_number DESC LIMIT 1";
$stmt = $conn->prepare($round_query);
$stmt->bind_param("s", $main_cashier_id);
$stmt->execute();
$round_result = $stmt->get_result();
$current_round = 1;
if ($row = $round_result->fetch_assoc()) {
    $current_round = $row['round_number'];
}
$stmt->close();
?>

<!DOCTYPE html>
<html>
<head>
    <title>Manage Supportive Cashiers</title>
    <link rel="stylesheet" href="../bootstrap/css/style.css">
    <style>
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            background: linear-gradient(135deg, #077C6C, #4ECDC4);
            color: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        
        .message {
            padding: 10px 15px;
            border-radius: 5px;
            margin: 10px 0;
            font-weight: bold;
        }
        
        .success {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        
        .error {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        .card {
            background: white;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .form-group {
            margin-bottom: 15px;
        }
        
        .form-control {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 16px;
        }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            font-weight: bold;
        }
        
        .btn-primary {
            background-color: #077C6C;
            color: white;
        }
        
        .btn-primary:hover {
            background-color: #065c50;
        }
        
        .btn-danger {
            background-color: #dc3545;
            color: white;
        }
        
        .btn-danger:hover {
            background-color: #c82333;
        }
        
        .support-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        
        .support-card {
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 15px;
            position: relative;
        }
        
        .color-preview {
            width: 30px;
            height: 30px;
            border-radius: 50%;
            display: inline-block;
            margin-right: 10px;
            vertical-align: middle;
            cursor: pointer;
        }
        
        .color-picker {
            position: absolute;
            top: 15px;
            right: 15px;
            display: none;
            background: white;
            padding: 10px;
            border-radius: 5px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.2);
            z-index: 100;
        }
        
        .color-option {
            width: 25px;
            height: 25px;
            border-radius: 50%;
            display: inline-block;
            margin: 2px;
            cursor: pointer;
            border: 2px solid transparent;
        }
        
        .color-option:hover {
            border-color: #333;
            transform: scale(1.1);
        }
        
        .invite-link {
            background: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            margin-top: 10px;
            font-family: monospace;
            font-size: 12px;
            word-break: break-all;
        }
        
        .copy-btn {
            background: #6c757d;
            color: white;
            border: none;
            padding: 5px 10px;
            border-radius: 3px;
            cursor: pointer;
            font-size: 12px;
            margin-top: 5px;
        }
        
        .info-box {
            background: #e7f3ff;
            border-left: 4px solid #007bff;
            padding: 15px;
            margin: 15px 0;
            border-radius: 5px;
        }
        
        .round-info {
            background: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 15px;
            margin: 15px 0;
            border-radius: 5px;
        }
    </style>
</head>
<body>
    <?php include_once("side-nav.php"); ?>
    
    <div class="main-content" style="margin-left: 250px; padding: 20px;">
        <div class="container">
            <div class="header">
                <h1>👥 Manage Supportive Cashiers</h1>
                <p>Add and manage cashiers who will help you select numbers</p>
            </div>
            
            <?php if (isset($message)): ?>
                <div class="message <?php echo $message_type; ?>">
                    <?php echo $message; ?>
                </div>
            <?php endif; ?>
            
            <!-- Add Supportive Cashier Form -->
            <div class="card">
                <h3>➕ Add New Supportive Cashier</h3>
                <form method="POST">
                    <div class="form-group">
                        <label for="support_cashier_id">Cashier ID:</label>
                        <input type="text" id="support_cashier_id" name="support_cashier_id" 
                               class="form-control" required 
                               placeholder="Enter the cashier ID to add as supportive">
                        <small style="color: #666;">Must be an existing cashier in the system</small>
                    </div>
                    <button type="submit" name="add_support" class="btn btn-primary">
                        Add as Supportive Cashier
                    </button>
                </form>
            </div>
            
            <!-- Current Supportive Cashiers -->
            <div class="card">
                <h3>📋 Your Supportive Cashiers (<?php echo count($support_cashiers); ?>)</h3>
                
                <?php if (empty($support_cashiers)): ?>
                    <p>No supportive cashiers added yet. Add some using the form above.</p>
                <?php else: ?>
                    <div class="support-grid">
                        <?php foreach ($support_cashiers as $support): ?>
                            <div class="support-card">
                                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                                    <div>
                                        <span class="color-preview" 
                                              style="background-color: <?php echo $support['color_code'] ?? '#FF5733'; ?>;"
                                              onclick="toggleColorPicker(<?php echo $support['id']; ?>)">
                                        </span>
                                        <strong><?php echo $support['support_cashier_id']; ?></strong>
                                    </div>
                                    <div>
                                        <a href="?remove=<?php echo $support['id']; ?>" 
                                           class="btn btn-danger"
                                           onclick="return confirm('Remove this supportive cashier?')">
                                            Remove
                                        </a>
                                    </div>
                                </div>
                                
                                <!-- Color Picker -->
                                <div id="colorPicker-<?php echo $support['id']; ?>" class="color-picker">
                                    <strong>Change Color:</strong><br>
                                    <?php
                                    $colors = [
                                        '#FF5733', '#33FF57', '#3357FF', '#F333FF', '#33FFF3',
                                        '#FFD733', '#FF33A1', '#33FFA1', '#8E44AD', '#3498DB',
                                        '#2ECC71', '#F39C12', '#E74C3C', '#1ABC9C', '#9B59B6'
                                    ];
                                    foreach ($colors as $color):
                                    ?>
                                        <div class="color-option" 
                                             style="background-color: <?php echo $color; ?>;"
                                             onclick="changeColor(<?php echo $support['id']; ?>, '<?php echo $color; ?>')">
                                        </div>
                                    <?php endforeach; ?>
                                </div>
                                
                                <div style="font-size: 12px; color: #666; margin-bottom: 10px;">
                                    <div>Assigned: <?php echo date('M d, Y', strtotime($support['assigned_date'])); ?></div>
                                </div>
                                
                                <!-- Invitation Link -->
                                <?php
                                $invite_link = "support_login.php?main=" . urlencode($main_cashier_id);
                                ?>
                                <div class="invite-link">
                                    <strong>Invitation Link:</strong><br>
                                    <span id="link-<?php echo $support['id']; ?>">
                                        <?php echo $invite_link; ?>
                                    </span>
                                    <button class="copy-btn" onclick="copyToClipboard('<?php echo $invite_link; ?>')">
                                        Copy Link
                                    </button>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    </div>
                <?php endif; ?>
            </div>
            
            <!-- How to Use & Information -->
            <div class="card">
                <h3>📖 How to Use Supportive Cashiers</h3>
                
                <div class="info-box">
                    <h4>Step 1: Add Supportive Cashiers</h4>
                    <p>Add cashiers using their Cashier ID. They must already exist in the system.</p>
                </div>
                
                <div class="info-box">
                    <h4>Step 2: Share the Invitation Link</h4>
                    <p>Share the invitation link with your supportive cashiers. They will use it to login.</p>
                </div>
                
                <div class="info-box">
                    <h4>Step 3: They Assist in Selection</h4>
                    <p>Supportive cashiers will login and help select numbers for your current game round.</p>
                </div>
                
                <div class="info-box">
                    <h4>Step 4: You Finalize Registration</h4>
                    <p>You will see their selections in real-time on your main screen. You finalize with price and pattern.</p>
                </div>
                
                <div class="round-info">
                    <h4>🔔 Current Game Information</h4>
                    <p><strong>Your Cashier ID:</strong> <?php echo $main_cashier_id; ?></p>
                    <p><strong>Current Round Number:</strong> <?php echo $current_round; ?></p>
                    <p><strong>Share with Supportive Cashiers:</strong></p>
                    <ul>
                        <li>Your Cashier ID: <strong><?php echo $main_cashier_id; ?></strong></li>
                        <li>Current Round: <strong><?php echo $current_round; ?></strong></li>
                        <li>Invitation Link: <code><?php echo $invite_link; ?></code></li>
                    </ul>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        function toggleColorPicker(supportId) {
            const picker = document.getElementById('colorPicker-' + supportId);
            picker.style.display = picker.style.display === 'block' ? 'none' : 'block';
        }
        
        function changeColor(supportId, color) {
            // Send AJAX request to update color
            const formData = new FormData();
            formData.append('change_color', '1');
            formData.append('support_id', supportId);
            formData.append('new_color', color);
            
            fetch(window.location.href, {
                method: 'POST',
                body: formData
            })
            .then(response => {
                if (response.ok) {
                    // Update color preview
                    const preview = document.querySelector(`#colorPicker-${supportId}`).previousElementSibling.querySelector('.color-preview');
                    preview.style.backgroundColor = color;
                    
                    // Hide picker
                    toggleColorPicker(supportId);
                    
                    // Reload page to show updated color
                    setTimeout(() => location.reload(), 500);
                }
            });
        }
        
        function copyToClipboard(text) {
            navigator.clipboard.writeText(text).then(() => {
                alert('Link copied to clipboard!');
            });
        }
        
        // Close color pickers when clicking outside
        document.addEventListener('click', function(event) {
            if (!event.target.closest('.color-preview') && !event.target.closest('.color-picker')) {
                document.querySelectorAll('.color-picker').forEach(picker => {
                    picker.style.display = 'none';
                });
            }
        });
    </script>
</body>
</html>