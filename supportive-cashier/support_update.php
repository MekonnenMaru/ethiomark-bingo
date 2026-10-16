// <?php
// // support_updates.php

// header('Content-Type: text/event-stream');
// header('Cache-Control: no-cache');
// header('Connection: keep-alive');
// header('X-Accel-Buffering: no');

// session_start();
// include_once '../config/Database.php';

// $db   = Database::getInstance();
// $conn = $db->getConnection();

// $main_cashier_id = $_GET['main_cashier_id'] ?? '';
// $round_number    = (int)($_GET['round_number'] ?? 0);

// /* ================= VALIDATION ================= */
// if (!$main_cashier_id || !$round_number) {
//     echo "event: error\n";
//     echo "data: " . json_encode(['error' => 'Invalid parameters']) . "\n\n";
//     flush();
//     exit();
// }

// /* ================= RUNTIME SETTINGS ================= */
// set_time_limit(0);
// ignore_user_abort(true);

// /* ================= INITIAL MESSAGE ================= */
// echo "event: connected\n";
// echo "data: " . json_encode([
//     'status' => 'connected',
//     'time'   => date('H:i:s')
// ]) . "\n\n";
// flush();

// /* ================= OPTIMIZATION VARS ================= */
// $lastHash       = '';
// $lastSendTime   = time();
// $maxIdleTime    = 300; // auto close after 5 minutes
// $pollInterval   = 20;   // DB check every 3 seconds

// /* ================= MAIN LOOP ================= */
// while (true) {

//     /* ---- Stop if browser closed ---- */
//     if (connection_aborted()) {
//         break;
//     }

//     /* ---- Auto close idle connections ---- */
//     if (time() - $lastSendTime > $maxIdleTime) {
//         echo "event: timeout\n";
//         echo "data: " . json_encode(['message' => 'Connection closed (idle)']) . "\n\n";
//         flush();
//         break;
//     }

//     /* ---- Fetch selections ---- */
//     $stmt = $conn->prepare("
//         SELECT 
//             cs.cartela_number,
//             cs.support_cashier_id,
//             COALESCE(sp.color_code, '#FF5733') AS color_code
//         FROM collaborative_selections cs
//         LEFT JOIN support_preferences sp
//             ON cs.support_cashier_id = sp.support_cashier_id
//         WHERE cs.main_cashier_id = ?
//           AND cs.round_number    = ?
//           AND cs.is_selected     = 1
//         ORDER BY cs.cartela_number
//     ");

//     $stmt->bind_param("si", $main_cashier_id, $round_number);
//     $stmt->execute();
//     $result = $stmt->get_result();

//     $selections = [];
//     while ($row = $result->fetch_assoc()) {
//         $selections[] = $row;
//     }
//     $stmt->close();

//     /* ---- Send ONLY if data changed ---- */
//     $currentHash = md5(json_encode($selections));

//     if ($currentHash !== $lastHash) {
//         $lastHash     = $currentHash;
//         $lastSendTime = time();

//         echo "event: update\n";
//         echo "data: " . json_encode([
//             'selections' => $selections,
//             'count'      => count($selections),
//             'timestamp'  => time()
//         ]) . "\n\n";
//         flush();
//     }

//     /* ---- Smart sleep ---- */
//     sleep($pollInterval);
// }

// /* ================= CLEANUP ================= */
// $conn->close();
// exit();
