<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

if (!isset($_SESSION['loggedin']) || $_SESSION['role'] != "cashier") {
    header("Location: ../config/logout.php");
    exit;
}

include_once '../config/Database.php';

// Initialize database connection
$db = Database::getInstance();
$conn = $db->getConnection(); // Get the connection object

$cashier_id = $_SESSION['cashier_id'] ?? ''; // Using null coalescing operator to avoid undefined index errors

// Function to update the last heartbeat and set the cashier as online
function updateOnlineStatus($conn, $cashier_id, $status = 1) {
    $query = "UPDATE cashier SET last_heartbeat = NOW(), is_online = ? WHERE cashier_id = ?";
    $stmt = $conn->prepare($query);
    
    // Check for statement preparation errors
    if (!$stmt) {
        echo json_encode(['status' => 'error', 'message' => 'Failed to prepare statement.']);
        exit;
    }

    // Bind parameters and execute
    $stmt->bind_param('is', $status, $cashier_id);
    $stmt->execute();
    
    // Check for execution errors
    if ($stmt->affected_rows === 0) {
        echo json_encode(['status' => 'error', 'message' => 'Failed to update online status.']);
        exit;
    }

    $stmt->close();
}

// If heartbeat is received (cashier is active)
if (isset($_POST['heartbeat'])) {
    updateOnlineStatus($conn, $cashier_id, 1); // Mark cashier as online
    echo json_encode(['status' => 'success']);
    exit;
}

// If the cashier's status should be updated to offline due to inactivity
if (isset($_POST['is_online'])) {
    if ($_POST['is_online'] == 0) {
        updateOnlineStatus($conn, $cashier_id, 0); // Mark cashier as offline
        echo json_encode(['status' => 'offline']);
        exit;
    }
}

// Function to check for inactivity and automatically mark as offline
function checkInactivity($conn, $cashier_id) {
    // Get the current time and last heartbeat time for the cashier
    $query = "SELECT last_heartbeat FROM cashier WHERE cashier_id = ?";
    $stmt = $conn->prepare($query);
    
    // Check for statement preparation errors
    if (!$stmt) {
        echo json_encode(['status' => 'error', 'message' => 'Failed to prepare statement for inactivity check.']);
        exit;
    }

    $stmt->bind_param('s', $cashier_id);
    $stmt->execute();
    $stmt->bind_result($last_heartbeat);
    $stmt->fetch();
    $stmt->close();

    if (!$last_heartbeat) {
        echo json_encode(['status' => 'error', 'message' => 'No last heartbeat found.']);
        exit;
    }

    // If no heartbeat was received for more than 30 seconds, mark as offline
    $last_heartbeat_time = strtotime($last_heartbeat);
    $current_time = time();
    $time_diff = $current_time - $last_heartbeat_time;

    // If last_heartbeat is older than 30 seconds, mark as offline
    if ($time_diff > 30) {
        updateOnlineStatus($conn, $cashier_id, 0); // Mark as offline
        echo json_encode(['status' => 'offline']);
    } else {
        echo json_encode(['status' => 'online']);
    }
}

// Periodic check for inactivity (can be triggered every 30 seconds)
checkInactivity($conn, $cashier_id);
?>
