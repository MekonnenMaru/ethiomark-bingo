<?php
// support_update.php - Optimized for speed (NO response changes)

session_start();
include_once '../config/Database.php';
require_once '../config/SupportCashierSchema.php';

$db   = Database::getInstance();
$conn = $db->getConnection();

// JSON response
header('Content-Type: application/json');

// Inputs
$action             = $_POST['action'] ?? '';
$main_cashier_id    = $_POST['main_cashier_id'] ?? '';
$support_cashier_id = $_POST['support_cashier_id'] ?? '';
$cartela_number     = (int)($_POST['cartela_number'] ?? 0);
$round_number       = (int)($_POST['round_number'] ?? 0);

support_cashier_ensure_defaults($conn, (string) $main_cashier_id);

// Debug log
error_log("Support Update: action=$action, main=$main_cashier_id, support=$support_cashier_id, card=$cartela_number, round=$round_number");

// Validate
if (!$main_cashier_id || !$support_cashier_id || !$round_number) {
    echo json_encode(['success' => false, 'message' => 'Invalid parameters']);
    exit;
}

try {

    /* -------------------------------------------------
       1. Check if the round is already completed
    ------------------------------------------------- */
    $stmt = $conn->prepare("
        SELECT iscompleted 
        FROM game 
        WHERE cashier_id = ? AND round_number = ? 
        LIMIT 1
    ");
    $stmt->bind_param("si", $main_cashier_id, $round_number);
    $stmt->execute();
    $res = $stmt->get_result();

    if ($row = $res->fetch_assoc()) {
        if ((int)$row['iscompleted'] === 1) {
            echo json_encode([
                'success'      => false,
                'message'      => 'Game completed - No further selections allowed',
                'game_status'  => 'completed',
                'round_number' => $round_number
            ]);
            exit;
        }
    }
    $stmt->close();

    /* -------------------------------------------------
       2. Verify support cashier assignment
    ------------------------------------------------- */
    $stmt = $conn->prepare("
        SELECT 1 
        FROM support_cashiers 
        WHERE main_cashier_id = ? 
          AND support_cashier_id = ? 
          AND is_active = 1
        LIMIT 1
    ");
    $stmt->bind_param("ss", $main_cashier_id, $support_cashier_id);
    $stmt->execute();

    if ($stmt->get_result()->num_rows === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'You are not assigned as a supportive cashier'
        ]);
        exit;
    }
    $stmt->close();

    /* -------------------------------------------------
       ACTION: SELECT
    ------------------------------------------------- */
    if ($action === 'select') {

        // Atomic insert/update (handles locking internally)
        $stmt = $conn->prepare("
            INSERT INTO collaborative_selections
            (round_number, main_cashier_id, support_cashier_id, cartela_number, is_selected)
            VALUES (?, ?, ?, ?, 1)
            ON DUPLICATE KEY UPDATE
                is_selected = IF(is_selected = 0, 1, is_selected),
                support_cashier_id = IF(is_selected = 0, VALUES(support_cashier_id), support_cashier_id)
        ");
        $stmt->bind_param(
            "issi",
            $round_number,
            $main_cashier_id,
            $support_cashier_id,
            $cartela_number
        );

        if ($stmt->execute()) {
            if ($stmt->affected_rows === 0) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Card already taken.'
                ]);
            } else {
                echo json_encode([
                    'success' => true,
                    'message' => 'Selected!'
                ]);
            }
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Sync error.'
            ]);
        }

        $stmt->close();
        exit;
    }

    /* -------------------------------------------------
       ACTION: DESELECT
    ------------------------------------------------- */
    if ($action === 'deselect') {

        if ($cartela_number <= 0) {
            echo json_encode([
                'success' => false,
                'message' => 'Invalid card number'
            ]);
            exit;
        }

        $stmt = $conn->prepare("
            UPDATE collaborative_selections
            SET is_selected = 0,
                selected_time = CURRENT_TIMESTAMP
            WHERE round_number = ?
              AND main_cashier_id = ?
              AND support_cashier_id = ?
              AND cartela_number = ?
        ");
        $stmt->bind_param(
            "issi",
            $round_number,
            $main_cashier_id,
            $support_cashier_id,
            $cartela_number
        );

        $stmt->execute();

        if ($stmt->affected_rows > 0) {
            echo json_encode([
                'success' => true,
                'message' => 'Number deselected successfully'
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Number was not selected'
            ]);
        }

        $stmt->close();
        exit;
    }

    /* -------------------------------------------------
       ACTION: CLEAR ALL
    ------------------------------------------------- */
    if ($action === 'clear_all') {

        $stmt = $conn->prepare("
            DELETE FROM collaborative_selections
            WHERE round_number = ?
              AND main_cashier_id = ?
              AND support_cashier_id = ?
        ");
        $stmt->bind_param(
            "iss",
            $round_number,
            $main_cashier_id,
            $support_cashier_id
        );

        if ($stmt->execute()) {
            echo json_encode([
                'success'        => true,
                'message'        => "All {$stmt->affected_rows} selections cleared successfully",
                'deleted_count'  => $stmt->affected_rows
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Failed to clear selections'
            ]);
        }

        $stmt->close();
        exit;
    }

    // Invalid action
    echo json_encode([
        'success' => false,
        'message' => 'Invalid action'
    ]);
    exit;

} catch (Throwable $e) {

    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
    exit;

} finally {
    $conn->close();
}
