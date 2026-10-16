<?php
// supporter_interface_backend.php - Single backend file for support interface
session_start();
header('Content-Type: application/json');

// Start session if not started
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Include database config
include_once '../config/Database.php';
require_once '../config/CartelaResolver.php';
require_once '../config/SupportCashierSchema.php';
$db = Database::getInstance();
$conn = $db->getConnection();
support_cashier_ensure_defaults($conn, (string) ($_SESSION['main_cashier_id'] ?? ''));

// Check authentication for most actions
function isAuthenticated() {
    return isset($_SESSION['loggedin']) && $_SESSION['role'] == 'support_cashier';
}

// Redirect if not authenticated (except for logout)
$action = $_POST['action'] ?? '';
if (!isAuthenticated() && !in_array($action, ['logout', 'login'])) {
    echo json_encode(['success' => false, 'redirect' => 'support_login.php']);
    exit;
}

// Get session variables
$support_cashier_id = $_SESSION['cashier_id'] ?? '';
$main_cashier_id = $_SESSION['main_cashier_id'] ?? '';
$support_color = $_SESSION['support_color'] ?? '#FF5733';

// Handle different actions
switch ($action) {
    case 'init':
        // Get initial data for the frontend
        $category_query = "SELECT category FROM cashier WHERE cashier_id = ?";
        $stmt = $conn->prepare($category_query);
        $stmt->bind_param("s", $main_cashier_id);
        $stmt->execute();
        $category_result = $stmt->get_result()->fetch_assoc();
        $category = $category_result['category'] ?? '';
        
        // Get total cards (file first when category exists in card_datas_new.json, else cartela table)
        $total_cards = cartela_count_by_category($conn, $category) ?: 100;
        
        // Get current round
        $round_check = "SELECT round_number, iscompleted FROM game 
                       WHERE cashier_id = ? 
                       ORDER BY round_number DESC LIMIT 1";
        $stmt = $conn->prepare($round_check);
        $stmt->bind_param("s", $main_cashier_id);
        $stmt->execute();
        $game_data = $stmt->get_result()->fetch_assoc();
        
        $current_round = $game_data ? (int)$game_data['round_number'] : 1;
        if ($game_data && $game_data['iscompleted'] == 1) {
            $current_round++;
        }
        
        echo json_encode([
            'success' => true,
            'main_cashier_id' => $main_cashier_id,
            'support_cashier_id' => $support_cashier_id,
            'support_color' => $support_color,
            'current_round' => $current_round,
            'total_cards' => $total_cards
        ]);
        break;
        
    case 'get_data':
        // Get all data (selections + current round)
        $round_check = "SELECT round_number, iscompleted FROM game 
                       WHERE cashier_id = ? 
                       ORDER BY round_number DESC LIMIT 1";
        $stmt = $conn->prepare($round_check);
        $stmt->bind_param("s", $main_cashier_id);
        $stmt->execute();
        $game_data = $stmt->get_result()->fetch_assoc();
        
        $current_round = $game_data ? (int)$game_data['round_number'] : 1;
        if ($game_data && $game_data['iscompleted'] == 1) {
            $current_round++;
        }
        
        // Get selections for this round
        $query = "SELECT cartela_number, support_cashier_id FROM collaborative_selections 
                 WHERE main_cashier_id = ? AND round_number = ? AND is_selected = 1";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("si", $main_cashier_id, $current_round);
        $stmt->execute();
        $res = $stmt->get_result();
        
        $mine = [];
        $others = [];
        
        while ($row = $res->fetch_assoc()) {
            if ($row['support_cashier_id'] == $support_cashier_id) {
                $mine[] = (int)$row['cartela_number'];
            } else {
                $others[] = (int)$row['cartela_number'];
            }
        }
        
        echo json_encode([
            'success' => true,
            'current_round' => $current_round,
            'mine' => $mine,
            'others' => $others
        ]);
        break;
        
    case 'select':
    case 'deselect':
        // Handle select/deselect actions (same as your support_update.php)
        $cartela_number = (int)($_POST['cartela_number'] ?? 0);
        $round_number = (int)($_POST['round_number'] ?? 0);
        
        if ($cartela_number <= 0 || $round_number <= 0) {
            echo json_encode(['success' => false, 'message' => 'Invalid parameters']);
            exit;
        }
        
        // Log for debugging
        error_log("Support Update: action=$action, main=$main_cashier_id, support=$support_cashier_id, card=$cartela_number, round=$round_number");
        
        // Check if tables exist
        $check_table = $conn->query("SHOW TABLES LIKE 'collaborative_selections'");
        if ($check_table->num_rows === 0) {
            echo json_encode(['success' => false, 'message' => 'Database table not found']);
            exit;
        }
        
        // Check game completion status for the SPECIFIC round
        $round_check = "SELECT round_number, iscompleted FROM game 
                        WHERE cashier_id = ? AND round_number = ? 
                        LIMIT 1";
        $stmt_rc = $conn->prepare($round_check);
        $stmt_rc->bind_param("si", $main_cashier_id, $round_number);
        $stmt_rc->execute();
        $result = $stmt_rc->get_result();
        
        // If the round exists in game table
        if ($result->num_rows > 0) {
            $game_data = $result->fetch_assoc();
            $iscompleted = (int)$game_data['iscompleted'];
            
            // If game is completed, return status immediately
            if ($iscompleted === 1) {
                echo json_encode([
                    'success' => false, 
                    'message' => 'Game completed - No further selections allowed',
                    'game_status' => 'completed',
                    'round_number' => $round_number
                ]);
                $stmt_rc->close();
                exit();
            }
        }
        $stmt_rc->close();
        
        // Check if support cashier is assigned
        $check_assignment = "SELECT * FROM support_cashiers 
                            WHERE main_cashier_id = ? AND support_cashier_id = ? AND is_active = 1";
        $stmt_check = $conn->prepare($check_assignment);
        $stmt_check->bind_param("ss", $main_cashier_id, $support_cashier_id);
        $stmt_check->execute();
        $assignment_result = $stmt_check->get_result();
        
        if ($assignment_result->num_rows === 0) {
            echo json_encode(['success' => false, 'message' => 'You are not assigned as a supportive cashier']);
            exit();
        }
        $stmt_check->close();
        
        if ($action === 'select') {
            // 1. First, check if someone else ALREADY has it
            $check = $conn->prepare("SELECT support_cashier_id FROM collaborative_selections 
                                     WHERE round_number = ? AND main_cashier_id = ? 
                                     AND cartela_number = ? AND is_selected = 1");
            $check->bind_param("isi", $round_number, $main_cashier_id, $cartela_number);
            $check->execute();
            $res = $check->get_result();
            
            if ($row = $res->fetch_assoc()) {
                if ($row['support_cashier_id'] != $support_cashier_id) {
                    echo json_encode([
                        'success' => false, 
                        'message' => 'Locked by: ' . $row['support_cashier_id']
                    ]);
                    exit();
                }
            }
        
            // 2. Try to insert/update your selection
            $query = "INSERT INTO collaborative_selections 
                      (round_number, main_cashier_id, support_cashier_id, cartela_number, is_selected) 
                      VALUES (?, ?, ?, ?, 1)
                      ON DUPLICATE KEY UPDATE 
                      is_selected = IF(is_selected = 0, 1, is_selected),
                      support_cashier_id = IF(is_selected = 0, VALUES(support_cashier_id), support_cashier_id)";
            
            $stmt = $conn->prepare($query);
            $stmt->bind_param("issi", $round_number, $main_cashier_id, $support_cashier_id, $cartela_number);
            
            if ($stmt->execute()) {
                if ($stmt->affected_rows == 0) {
                     echo json_encode(['success' => false, 'message' => 'Card already taken.']);
                } else {
                     echo json_encode(['success' => true, 'message' => 'Selected!']);
                }
            } else {
                echo json_encode(['success' => false, 'message' => 'Sync error.']);
            }
            $stmt->close();
            
        } elseif ($action === 'deselect') {
            // Mark as deselected
            $query = "UPDATE collaborative_selections 
                      SET is_selected = 0, selected_time = CURRENT_TIMESTAMP
                      WHERE round_number = ? AND main_cashier_id = ? 
                      AND support_cashier_id = ? AND cartela_number = ?";
            
            $stmt = $conn->prepare($query);
            $stmt->bind_param("issi", $round_number, $main_cashier_id, $support_cashier_id, $cartela_number);
            
            if ($stmt->execute()) {
                if ($stmt->affected_rows > 0) {
                    echo json_encode([
                        'success' => true, 
                        'message' => 'Number deselected successfully'
                    ]);
                } else {
                    echo json_encode(['success' => false, 'message' => 'Number was not selected']);
                }
            } else {
                echo json_encode(['success' => false, 'message' => 'Failed to deselect number']);
            }
            
            $stmt->close();
        }
        break;
        
    case 'clear_all':
        // Clear all selections for this supportive cashier
        $round_number = (int)($_POST['round_number'] ?? 0);
        
        if ($round_number <= 0) {
            // Get current round
            $round_check = "SELECT round_number FROM game 
                           WHERE cashier_id = ? 
                           ORDER BY round_number DESC LIMIT 1";
            $stmt = $conn->prepare($round_check);
            $stmt->bind_param("s", $main_cashier_id);
            $stmt->execute();
            $game_data = $stmt->get_result()->fetch_assoc();
            $round_number = $game_data ? (int)$game_data['round_number'] : 1;
        }
        
        $query = "DELETE FROM collaborative_selections 
                  WHERE round_number = ? AND main_cashier_id = ? AND support_cashier_id = ?";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("iss", $round_number, $main_cashier_id, $support_cashier_id);
        
        if ($stmt->execute()) {
            $deleted_count = $stmt->affected_rows;
            echo json_encode([
                'success' => true, 
                'message' => "All $deleted_count selections cleared successfully",
                'deleted_count' => $deleted_count
            ]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Failed to clear selections']);
        }
        
        $stmt->close();
        break;
        
    case 'toggle_selection':
        // Combined select/deselect toggle action
        $cartela_number = (int)($_POST['cartela_number'] ?? 0);
        $round_number = (int)($_POST['round_number'] ?? 0);
        
        if ($cartela_number < 1) {
            echo json_encode(['success' => false, 'message' => 'Invalid cartela number']);
            exit;
        }
        
        // Get current round
        $round_check = "SELECT round_number, iscompleted FROM game 
                       WHERE cashier_id = ? 
                       ORDER BY round_number DESC LIMIT 1";
        $stmt = $conn->prepare($round_check);
        $stmt->bind_param("s", $main_cashier_id);
        $stmt->execute();
        $game_data = $stmt->get_result()->fetch_assoc();
        
        // if there is recoreded data
        $current_round = $game_data ? (int)$game_data['round_number'] : 1;
        $iscompleted = $game_data ? (int)$game_data['iscompleted'] : 0;
        
        // Check if round is completed
        if ($iscompleted === 1 && $current_round === $round_number ) {
            echo json_encode([
                'success' => false,
                'game_status' => 'completed',
                'message' => 'This round is already completed!'
            ]);
            exit;
        }
        
        if($iscompleted === 1 && $current_round <= $round_number)
        {
            $current_round = $round_number;
        }
        
        // Check if already selected by this user
        $check_query = "SELECT is_selected FROM collaborative_selections 
                       WHERE main_cashier_id = ? AND support_cashier_id = ? 
                       AND cartela_number = ? AND round_number = ?";
        $stmt = $conn->prepare($check_query);
        $stmt->bind_param("ssii", $main_cashier_id, $support_cashier_id, $cartela_number, $current_round);
        $stmt->execute();
        $check_result = $stmt->get_result()->fetch_assoc();
        
        if ($check_result) {
            // Toggle selection
            $new_status = $check_result['is_selected'] ? 0 : 1;
            
            if ($new_status == 1) {
                // Check if taken by someone else
                $taken_check = "SELECT support_cashier_id FROM collaborative_selections 
                               WHERE main_cashier_id = ? AND cartela_number = ? 
                               AND round_number = ? AND is_selected = 1";
                $stmt = $conn->prepare($taken_check);
                $stmt->bind_param("sii", $main_cashier_id, $cartela_number, $current_round);
                $stmt->execute();
                $taken_result = $stmt->get_result()->fetch_assoc();
                
                if ($taken_result) {
                    echo json_encode([
                        'success' => false,
                        'message' => 'Already taken by another cashier!'
                    ]);
                    exit;
                }
            }
            
            $update_query = "UPDATE collaborative_selections 
                           SET is_selected = ? 
                           WHERE main_cashier_id = ? AND support_cashier_id = ? 
                           AND cartela_number = ? AND round_number = ?";
            $stmt = $conn->prepare($update_query);
            $stmt->bind_param("issii", $new_status, $main_cashier_id, $support_cashier_id, $cartela_number, $current_round);
        } else {
            // Check if taken by someone else
            $taken_check = "SELECT support_cashier_id FROM collaborative_selections 
                           WHERE main_cashier_id = ? AND cartela_number = ? 
                           AND round_number = ? AND is_selected = 1";
            $stmt = $conn->prepare($taken_check);
            $stmt->bind_param("sii", $main_cashier_id, $cartela_number, $current_round);
            $stmt->execute();
            $taken_result = $stmt->get_result()->fetch_assoc();
            
            if ($taken_result) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Already taken by another cashier!'
                ]);
                exit;
            }
            
            // Insert new selection
            $insert_query = "INSERT INTO collaborative_selections 
                           (main_cashier_id, support_cashier_id, cartela_number, round_number, is_selected) 
                           VALUES (?, ?, ?, ?, 1)";
            $stmt = $conn->prepare($insert_query);
            $stmt->bind_param("ssii", $main_cashier_id, $support_cashier_id, $cartela_number, $current_round);
        }
        
        if ($stmt->execute()) {
            echo json_encode(
                [
                    'success' => true,
                    'message' => "Registered with game round $current_round"
                ]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Database error']);
        }
        break;
        
    case 'logout':
        session_destroy();
        echo json_encode(['success' => true]);
        break;
        
    default:
        echo json_encode(['success' => false, 'message' => 'Invalid action']);
}

$conn->close();
?>