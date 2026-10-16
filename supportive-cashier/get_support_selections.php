<?php
session_start();
include_once '../config/Database.php';
require_once '../config/SupportCashierSchema.php';

$db = Database::getInstance();
$conn = $db->getConnection();

$main_cashier_id = $_GET['main_cashier_id'] ?? '';
support_cashier_ensure_defaults($conn, (string) $main_cashier_id);
$round_number = $_GET['round_number'] ?? 0;

if (empty($main_cashier_id) || empty($round_number)) {
    echo json_encode(['success' => false, 'message' => 'Invalid parameters']);
    exit();
}

try {
    // Get all active support selections
    $query = "
        SELECT 
            cs.cartela_number,
            cs.support_cashier_id,
            COALESCE(sp.color_code, '#FF5733') as color_code
        FROM collaborative_selections cs
        LEFT JOIN support_preferences sp ON cs.support_cashier_id = sp.support_cashier_id
        WHERE cs.main_cashier_id = ? 
        AND cs.round_number = ?
        AND cs.is_selected = 1
        ORDER BY cs.selected_time DESC
    ";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("si", $main_cashier_id, $round_number);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $selections = [];
    while ($row = $result->fetch_assoc()) {
        $selections[] = $row;
    }
    
    echo json_encode([
        'success' => true,
        'selections' => $selections,
        'count' => count($selections)
    ]);
    
    $stmt->close();
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}

$conn->close();
?>