<?php
require 'Database.php';
require 'Youman.php';
require_once __DIR__ . '/CartelaResolver.php';
$db   = Database::getInstance();
$conn = $db->getConnection();

header('Content-Type: application/json');
error_reporting(0);
ini_set('display_errors', 0);
error_reporting(E_ALL);
// Set timezone and display PHP time
date_default_timezone_set('Africa/Nairobi');

//==========================Package modal remote gate (Report page)===================================
if (isset($_POST['package_modal_open'])) {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    if (empty($_SESSION['loggedin']) || ($_SESSION['role'] ?? '') !== 'cashier') {
        echo json_encode(['status' => 'error', 'message' => 'Unauthorized']);
        exit;
    }
    require_once __DIR__ . '/DepositService.php';
    deposit_remote_enable();
    echo json_encode(['status' => 'success']);
    exit;
}

if (isset($_POST['package_modal_close'])) {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    require_once __DIR__ . '/DepositService.php';
    deposit_remote_disable();
    echo json_encode(['status' => 'success']);
    exit;
}

//==========================Sync package deposit (Report page)===================================
if (isset($_POST['sync_package_deposit'])) {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    if (empty($_SESSION['loggedin']) || ($_SESSION['role'] ?? '') !== 'cashier') {
        echo json_encode(['status' => 'error', 'message' => 'Unauthorized']);
        exit;
    }
    require_once __DIR__ . '/DepositService.php';
    if (!deposit_remote_is_allowed()) {
        echo json_encode([
            'status'  => 'error',
            'message' => 'Remote connection is only available while the package modal is open.',
        ]);
        exit;
    }
    echo json_encode(deposit_sync_package($conn, (string) $_SESSION['cashier_id']));
    exit;
}

//==========================Login===================================
if (isset($_POST['login_form_submitted']) && isset($_POST['cashier_id']) && isset($_POST['password'])) {
    $cashier_id     = $_POST['cashier_id'];
    $password       = $_POST['password'];
    $login_response = [];


    $xy = shell_exec('wmic bios get serialnumber 2>&1');
        $xy = trim($xy);
        $parts = preg_split('/\s+/', $xy);
        if (count($parts) > 1) {
            $sr = $parts[1];
        } else {
            $sr = '';
        }

        // before comparing the fetched seriial number with the datas from database we must encrypt 
        $sr = base64_encode(openssl_encrypt($sr, 'AES-256-CBC', ENCRYPTION_KEY, 0, ENCRYPTION_IV));
        // $cashier_package = openssl_decrypt(base64_decode($cashier_package), 'AES-256-CBC', ENCRYPTION_KEY, 0, ENCRYPTION_IV);
        
        // Check if the serial number exists in the database (machine_id in settings table)
        $query19 = "SELECT mid FROM cashier WHERE mid = ?";
        $stmt19 = $conn->prepare($query19);
        $stmt19->bind_param('s', $sr);
        $stmt19->execute();
        $result19 = $stmt19->get_result();

        if ($result19->num_rows === 0) {
            $login_response['login_status'] = "Fuck ....  " ;
        }
        else
        {

            $updatingwith_remote_result = [
                "status"  => "false",
                "message" => "",
            ];
        
            try {
                // Fetch partner id
                $sql   = "SELECT partner_id FROM cashier WHERE cashier_id = ?";
                $stmt1 = $conn->prepare($sql);
                $stmt1->bind_param("s", $cashier_id);
                $stmt1->execute();
                $stmt1->store_result();
                $stmt1->bind_result($partner_id);
                $stmt1->fetch();
                $stmt1->close();
        
                require_once __DIR__ . '/RemoteConfig.php';
                $remote_url = remote_sync_url();
        
                // Sending the request to fetch cashier information for update
                $update_cashier_information = [
                    'cashier_id'   => $cashier_id,
                    'partner_id'   => $partner_id,
                    'request_type' => "get_cashier_information_for_update",
                ];
        
                $ch = curl_init();
                curl_setopt($ch, CURLOPT_URL, $remote_url);
                curl_setopt($ch, CURLOPT_POST, true);
                curl_setopt($ch, CURLOPT_POSTFIELDS, $update_cashier_information);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
        
                $response = curl_exec($ch);
                curl_close($ch);
        
                if (! $response) {
                    throw new Exception("Error fetching data from remote server.");
                }
        
                $response_data = json_decode($response, true);
        
                if ($response_data['status'] == 'success') {
                    $remote_cashier_data = $response_data['data'];
        
                    $is_locked_remote                  = $remote_cashier_data['is_locked'];
                    $is_active_remote                  = $remote_cashier_data['is_active'];
                    $login_attempts_remote             = $remote_cashier_data['login_attempts'];
                    $category_remote                   = $remote_cashier_data['category'];
                    $cashier_profit_remote             = $remote_cashier_data['cashier_profit'];
                    $cashier_bonus_status_remote       = $remote_cashier_data['cashier_bonus_status'];
                    $cashier_fixed_bonus_amount_remote = $remote_cashier_data['cashier_fixed_bonus_amount'];
                    $last_remote                       = $remote_cashier_data['last'];
        
                    $last_remote = $remote_cashier_data['last']; // Check if last_remote is 1, then update last separately
                    if ($last_remote == "1") {
                        $update_last_sql = "UPDATE cashier SET last = NULL WHERE cashier_id = ?";
                        $stmt11111       = $conn->prepare($update_last_sql);
                        $stmt11111->bind_param("s", $cashier_id);
                        $stmt11111->execute();
                    }
                        
                    $sql  = "SELECT is_locked, is_active, login_attempts, category, cashier_profit, cashier_bonus_status, cashier_fixed_bonus_amount FROM cashier WHERE cashier_id = ? AND partner_id = ?";
                    $stmt = $conn->prepare($sql);
                    $stmt->bind_param("ss", $cashier_id, $partner_id);
                    $stmt->execute();
                    $stmt->store_result();
                    $stmt->bind_result($is_locked_local, $is_active_local, $login_attempts_local, $category_local, $cashier_profit_local, $cashier_bonus_status_local, $cashier_fixed_bonus_amount_local);
        
                    if ($stmt->fetch()) {
                        $should_update = (
                            $is_locked_remote != $is_locked_local ||
                            $is_active_remote != $is_active_local ||
                            $login_attempts_remote != $login_attempts_local ||
                            $category_remote != $category_local ||
                            $cashier_profit_remote != $cashier_profit_local ||
                            $cashier_bonus_status_remote != $cashier_bonus_status_local ||
                            $cashier_fixed_bonus_amount_remote != $cashier_fixed_bonus_amount_local
                        );
        
                        if ($should_update) {
                            $update_sql = "UPDATE cashier SET is_locked = ?, is_active = ?, login_attempts = ?, category = ?, cashier_profit = ?, cashier_bonus_status = ?, cashier_fixed_bonus_amount = ? WHERE cashier_id = ? AND partner_id = ?";
                            $stmt       = $conn->prepare($update_sql);
                            $stmt->bind_param("sssssssss", $is_locked_remote, $is_active_remote, $login_attempts_remote, $category_remote, $cashier_profit_remote, $cashier_bonus_status_remote, $cashier_fixed_bonus_amount_remote, $cashier_id, $partner_id);
                            if ($stmt->execute()) {
                                $updatingwith_remote_result["message"] = "Cashier data updated successfully.";
                            } else {
                                throw new Exception("Error updating cashier data.");
                            }
                        } else {
                            $updatingwith_remote_result["message"] = "No changes detected in cashier data. No update needed.";
                        }
                    } else {
                        throw new Exception("Cashier data not found for the given cashier_id and partner_id.");
                    }
                    $stmt->close();
                } else {
                    throw new Exception("Error fetching cashier information from the remote server ");
                }
            } catch (Exception $e) {
                $updatingwith_remote_result["status"]  = "error";
                $updatingwith_remote_result["message"] = $e->getMessage();
            }
            
            // Prepare the SQL statement
            $query = "SELECT 
                        cashier.cashier_id,
                        cashier.password,
                        cashier.is_locked, 
                        cashier.login_attempts,
                        partner.is_blocked 
                      FROM 
                        partner 
                      JOIN 
                        cashier 
                      ON 
                        partner.partner_id = cashier.partner_id 
                      WHERE 
                        cashier.cashier_id = ?;";
            
            $stmt = $conn->prepare($query);
            
            if (false === $stmt) {
                $login_response['error'] = "Error in query: " . mysqli_connect_error();
            } 
            else 
            {
                $stmt->bind_param('s', $cashier_id);
                $stmt->execute();
                $result = $stmt->get_result();
                $state = 0; // If there is data
                
                while ($row = $result->fetch_assoc()) 
                {
                    $new_attempts = $row['login_attempts'] + 1;
                    $state = 1;
    
                    if ($row['is_blocked'] == 0) 
                    {
                        if ($row['is_locked'] == 1) {
                            $login_response['login_status'] = "Account is Locked";
                        } 
                        else 
                        {
                            // Check password against the stored password (assuming you are using plain text here, consider using hash)
                             // Hash the entered password using md5
                            $hashed_password = md5($password);
    
                            // Check hashed password against the stored password
                            if ($row['password'] == $hashed_password) 
                            {
                                $login_response['login_status'] = 'success';
                                if (session_status() === PHP_SESSION_NONE)
                                {
                                    session_start();
                                }
                                $_SESSION['cashier_id']=$cashier_id;
                                $_SESSION['loggedin']="true";
                                $_SESSION['role']="cashier";

                                // Reset login attempts on successful login
                                $reset_query = "UPDATE `cashier` SET `login_attempts` = 0 WHERE `cashier_id` = ?;";
                                $reset_stmt = $conn->prepare($reset_query);
                                $reset_stmt->bind_param('s', $cashier_id);
                                $reset_stmt->execute();
                            } 
                            else 
                            {
                                // Increment login attempts on failed login
                                $new_attempts = $row['login_attempts'] + 1;
    
                                // Check if attempts reach 4
                                if ($new_attempts >= 100) 
                                {
                                    // Lock the account
                                    $update_lock_query = "UPDATE `cashier` SET `is_locked` = 1 WHERE `cashier_id` = ?;";
                                    $update_lock_stmt = $conn->prepare($update_lock_query);
                                    $update_lock_stmt->bind_param('s', $cashier_id);
                                    $update_lock_stmt->execute();
                                    $login_response['login_status'] = "Account is Locked";
                                } 
                                else 
                                {
                                    // Update attempts
                                    $update_attempts_query = "UPDATE `cashier` SET `login_attempts` = ? WHERE `cashier_id` = ?;";
                                    $update_attempts_stmt = $conn->prepare($update_attempts_query);
                                    $update_attempts_stmt->bind_param('is', $new_attempts, $cashier_id);
                                    $update_attempts_stmt->execute();
                                    $login_response['login_status'] = 'Invalid cashier_id or password';
                                }
                            }
                        }
                    } else {
                        $login_response['login_status'] = "You entered a blocked account";
                    }
                }
                
                if ($state == 0) 
                {
                    $login_response['login_status'] = 'You entered invalid detail';
                }
            }

        }
		

		// Output the JSON response
		print(json_encode($login_response));
		exit;
	}

//==========================get cashier data===================================
if (isset($_POST['get_cashier_data'])) {
    $cashier_id = $_POST['get_cashier_data'];

    // Prepare the response array
    $response = [];

    // Prepare the SQL statement
    $query = "SELECT
                    cashier.*,
                    partner.is_blocked
                FROM
                    partner
                JOIN
                    cashier
                ON
                    partner.partner_id = cashier.partner_id
                WHERE
                    cashier.cashier_id = ?;";
            
            $stmt = $conn->prepare($query);
            

    if (false === $stmt) {
        // Error in preparing statement
        $response['error'] = "Error in query: " . $conn->error;
    } else {
        // Bind parameters and execute
        $stmt->bind_param('s', $cashier_id);
        $stmt->execute();

        // Get result
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            // Fetch associative array for each row
            while ($row = $result->fetch_assoc()) {
                $row['cashier_package'] = openssl_decrypt( base64_decode($row['cashier_package']), 'AES-256-CBC', ENCRYPTION_KEY, 0,ENCRYPTION_IV);
                $response[] = $row;
            }
            // while ($row = $result->fetch_assoc()) {
            //     $response[] = $row; // Append each row to the response array
            // }
        } else {
            $response['message'] = "No data found for the given cashier_id.";
        }

        // Free the result
        $stmt->free_result();
    }

    // Output response as JSON
    echo json_encode($response);
}

//==========================Get Report Data===================================
if (isset($_POST['cashier_id']) && isset($_POST['start_date']) && isset($_POST['end_date'])) {
    $cashier_id = $_POST['cashier_id']; // Getting the cashier_id from POST request
    $start_date = $_POST['start_date']; // Start date for filtering transactions
    $end_date   = $_POST['end_date'];   // End date for filtering transactions

    // Prepare the response array
    $response = [];

    // Adjust the start and end dates to include the full day
    $start_datetime = $start_date . ' 00:00:00';
    $end_datetime   = $end_date . ' 23:59:59';

    // Prepare the SQL query with date range filtering
    $query = "
			SELECT
				p.partner_id, p.partner_full_name, p.partner_phone,
				p.user_name, p.password AS partner_password, p.is_locked AS partner_locked,
				p.is_blocked AS partner_blocked, p.percent AS partner_percent,
				c.cashier_id, c.password AS cashier_password, c.is_loggedin,
				c.loggin_time, c.is_locked AS cashier_locked, c.is_active,
				c.login_attempts, c.speed_range, c.sound, c.cashier_package,
				t.id AS transaction_id, t.game_round, t.santim, t.sew,
				t.income, t.date
			FROM partner p
			INNER JOIN cashier c ON p.partner_id = c.partner_id
			LEFT JOIN transaction t ON c.cashier_id = t.cashier_id
			WHERE c.cashier_id = ? AND t.date BETWEEN ? AND ?
		";

    // Prepare the SQL statement
    $stmt = $conn->prepare($query);

    if (false === $stmt) {
        // Error in preparing the statement
        $response['error'] = "Error in query: " . $conn->error;
    } else {
                                                                               // Bind the parameters and execute
        $stmt->bind_param('sss', $cashier_id, $start_datetime, $end_datetime); // 's' for strings (dates)
        $stmt->execute();

        // Get the result
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            // Fetch associative array for each row
            while ($row = $result->fetch_assoc()) {
                $response[] = $row; // Append each row to the response array
            }
        } else {
            $response['message'] = "No data found for the given criteria.";
        }

        // Free the result and close the statement
        $stmt->free_result();
        $stmt->close();
    }

    // Output response as JSON
    echo json_encode($response);
}

//==========================save selected card ===================================
if (isset($_POST['register_new_game_round']) && isset($_POST['selectedcard']) && isset($_POST['price']) && isset($_POST['pattern']) && isset($_POST['cashier_id'])) {

    $register_new_game_round = $_POST['register_new_game_round'];
    $selectedcard            = $_POST['selectedcard']; // The selected card numbers
    $price                   = $_POST['price'];        // The price paid for the card
    $pattern                 = $_POST['pattern'];      // The pattern selected in the game
    $cashier_id              = $_POST['cashier_id'];   // The cashier_id (cashier)

    $response = [];
    $roundAdjustInfo = null;
    try 
    {

        // Get the highest game_round for today
        $stmt = $conn->prepare("SELECT MAX(game_round) as max_round FROM transaction WHERE cashier_id = '$cashier_id' and DATE(date) = CURDATE()");
        $stmt->execute();
        $result = $stmt->get_result();
        $row    = $result->fetch_assoc();

        $maxGameRound = (int) ($row['max_round'] ?? 0);
        $submittedRound = (int) $register_new_game_round;

        if ($submittedRound < $maxGameRound) {
            $register_new_game_round = $maxGameRound + 1;
            $roundAdjustInfo = 'Game round set to ' . $register_new_game_round
                . '. Today\'s latest round was ' . $maxGameRound
                . ' — please check date and time!';
        }

        // Step 1: Get the cashier's package amount
        $stmt = $conn->prepare("SELECT cashier_package, partner_id FROM cashier WHERE cashier_id = ?");
        $stmt->bind_param("s", $cashier_id); // Cashier ID is a string
        $stmt->execute();
        $result  = $stmt->get_result();
        $cashier = $result->fetch_assoc();

        if ($cashier) 
        {
            $cashier_package = $cashier['cashier_package'];
            // $newCashierPackage = base64_encode(openssl_encrypt(10000, 'AES-256-CBC', ENCRYPTION_KEY, 0, ENCRYPTION_IV));
            $cashier_package = openssl_decrypt(base64_decode($cashier_package), 'AES-256-CBC', ENCRYPTION_KEY, 0, ENCRYPTION_IV);

            // Split the selected cards string into an array and count the number of cards
            $selectedCardsArray = explode(',', $selectedcard);
            $totalCards         = count($selectedCardsArray);
            $totalincome        = $totalCards * $price * 0.3;

            // Step 3: Check if the total price is less than or equal to the cashier's package
            // if ($totalPrice > $cashier_package)
            if (($cashier_package <= ($totalincome + 5))) {
                $response = ["status" => "error", "message" => "Transaction exceeds cashier's package  : ".$cashier_package];
            } 
            else 
            {
                // Step 1: Check if there's an existing game entry for the specific round_number and cashier_id
                $stmt = $conn->prepare("SELECT * FROM game WHERE round_number = ? AND cashier_id = ?  AND DATE(date) = CURDATE()");
                $stmt->bind_param("is", $register_new_game_round, $cashier_id); // Assuming round_number is an integer and cashier_id is a string
                $stmt->execute();
                $result       = $stmt->get_result();
                $existingGame = $result->fetch_assoc(); // Fetch the result as an associative array




                function getFirst10DrawnNumber($conn, $round_number, $cashier_id) 
                {
                    $debug = false; // Set to false to disable debug output
                    
                    if ($debug) {
                        echo "\n=== GETTING FIRST 10 NUMBERS ===\n";
                        echo "Round: $round_number, Cashier: $cashier_id\n";
                    }
                
                    // Fetch all card numbers and category
                    $query1 = "SELECT game.cartela_number, cashier.category
                               FROM game
                               JOIN cashier ON game.cashier_id = cashier.cashier_id
                               WHERE game.cashier_id = '$cashier_id'
                               AND game.round_number = '$round_number'";
                    $result1 = $conn->query($query1);
                
                    $cartela_numbers = [];
                    $category = "";
                    
                    if ($result1->num_rows > 0) {
                        while ($row = $result1->fetch_assoc()) {
                            $cartela_numbers[] = $row['cartela_number'];
                            $category = $row['category'];
                        }
                    }
                
                    if (empty($cartela_numbers)) {
                        if ($debug) echo "No cards found - returning simple numbers\n";
                        return range(1, 10);
                    }
                
                    // Fetch all card data (file when category in cards_data.js, else cartela table)
                    $flat_numbers = [];
                    foreach ($cartela_numbers as $cn) {
                        $flat_numbers = array_merge(
                            $flat_numbers,
                            array_map('intval', array_filter(explode(',', (string) $cn)))
                        );
                    }
                    $cartela_rows = cartela_fetch_many($conn, $flat_numbers, $category);
                
                    $card_data = [];
                    $used_numbers = [];
                    $card_positions = [];
                
                    if (!empty($cartela_rows)) {
                        foreach ($cartela_rows as $card_number => $row) {
                            $columns = ['b', 'i', 'n', 'g', 'o'];
                            $card_numbers = [];
                            $positions = [];
                            
                            foreach ($columns as $col_index => $col) {
                                $numbers = array_map('intval', explode(',', $row[$col]));
                                foreach ($numbers as $row_index => $num) {
                                    $card_numbers[] = $num;
                                    $positions[$num] = ['col' => $col_index, 'row' => $row_index];
                                }
                            }
                            
                            $used_numbers = array_merge($used_numbers, $card_numbers);
                            $card_data[$card_number] = array_unique($card_numbers);
                            $card_positions[$card_number] = $positions;
                        }
                    }
                    
                    shuffle($card_data);
                    
                    // Get unused numbers
                    $all_numbers = range(1, 75);
                    $unused_numbers = array_values(array_diff($all_numbers, $used_numbers));
                
                    if ($debug) {
                        echo "Total cards: " . count($card_data) . "\n";
                        echo "Used numbers: " . count(array_unique($used_numbers)) . "\n";
                        echo "Unused numbers available: " . count($unused_numbers) . "\n";
                    }
                
                    // Phase 1: Use unused numbers
                    shuffle($unused_numbers);
                    $first_10_numbers = array_slice($unused_numbers, 0, min(10, count($unused_numbers)));
                
                    if ($debug) {
                        echo "\nPhase 1: Selected " . count($first_10_numbers) . " unused numbers\n";
                    }
                
                    // Phase 2: Safe used numbers
                    $needed_count = 10 - count($first_10_numbers);
                    
                    if ($needed_count > 0) {
                        if ($debug) echo "\nPhase 2: Selecting $needed_count safe used numbers\n";
                        
                        $selected_numbers = selectSafeUsedNumbers(
                            $card_data,
                            $card_positions,
                            $first_10_numbers,
                            $needed_count,
                            $debug
                        );
                        
                        $first_10_numbers = array_merge($first_10_numbers, $selected_numbers);
                    }
                
                    // Final verification
                    if (count($first_10_numbers) < 10 ||  !verifyNoWinningPatterns($first_10_numbers, $card_positions)) {
                        if ($debug) echo "\n! Falling back to emergency numbers\n";
                        $first_10_numbers = getEmergencyNumbers($unused_numbers, $used_numbers, $debug);
                    }
                
                    if ($debug) {
                        verifyNoWinningPatterns($first_10_numbers, $card_positions);
                        echo "\n=== FINAL SELECTION ===\n";
                        echo implode(', ', $first_10_numbers) . "\n";
                    }
                
                    // return array_slice($first_10_numbers, 0, 10);
                    
                    //XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                    //TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
                        $first_10_numbers =  array_slice($first_10_numbers, 0, 7);
                    //XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                    //TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
                                                $count = count($card_data);
        
                                                $number_of_cards_to_select = match (true) {
                                                    //$count >= 3 => 3,
                                                    $count >= 2 => 2,
                                                    $count >= 1 => 1,
                                                    default => 0,
                                                };
                                                
                                                $to_finish_faster_winner_card_data = [];
                                                
                                                if ($number_of_cards_to_select > 0) {
                                                    $selected_cards = array_rand($card_data, $number_of_cards_to_select);
                                                
                                                    // Normalize to array
                                                    if (!is_array($selected_cards)) {
                                                        $selected_cards = [$selected_cards];
                                                    }
                                                
                                                    foreach ($selected_cards as $card_index) {
                                                        $card_numbers = $card_data[$card_index]; // flat array of integers
                                                        $to_finish_faster_winner_card_data = array_merge(
                                                            $to_finish_faster_winner_card_data,
                                                            $card_numbers
                                                        );
                                                    }
                                                }
                            
                            
                                                // Remove duplicates, remove 0 (center), and shuffle
                                                $unique_numbers = array_filter(array_unique($to_finish_faster_winner_card_data), fn($n) => $n !== 0);
                                                
                                                // Reindex and pick only required amount
                                                $unique_numbers = array_values($unique_numbers);
                                                shuffle($unique_numbers);
                                                $diff = array_diff($unique_numbers, $first_10_numbers);
                                                $to_finish_faster_winner_card_data = array_slice($diff, 0, 20);
                                                shuffle($to_finish_faster_winner_card_data);
                            
                                                if($debug){
                                                    // echo "all card with data :::: " . print_r($card_data, true) . "\n";
                                                    // echo "all used card data :::: " . print_r($used_numbers, true) . "\n";
                                                    echo "selected_cards :::: " . print_r($selected_cards, true) . "\n";
                                                    echo "to_finish_faster_winner_card_data :::: " .print_r($to_finish_faster_winner_card_data,true). "\n";
                                                    echo "first_10_numbers :::: " .print_r($first_10_numbers,true). "\n";
                                                    echo "Final :::: " .print_r(array_merge($first_10_numbers, $to_finish_faster_winner_card_data),true). "\n";
                                                }
                                                
                                                $first_10_numbers = array_merge($first_10_numbers, $to_finish_faster_winner_card_data);
                            
                                        // // //	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

                            
                                        // // //	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

                
                
                            
                                return $first_10_numbers;
                }
                
                function drawnOnlySelectedNumber($conn, $round_number, $cashier_id, $count_to_be_returned)
                {
                    $debug = false; // Set to false to disable debug output
                    
                    if ($debug) {
                        echo "\n=== GETTING FIRST 10 NUMBERS ===\n";
                        echo "Round: $round_number, Cashier: $cashier_id\n";
                    }
                
                    // Fetch all card numbers and category
                    $query1 = "SELECT game.cartela_number, cashier.category
                               FROM game
                               JOIN cashier ON game.cashier_id = cashier.cashier_id
                               WHERE game.cashier_id = '$cashier_id'
                               AND game.round_number = '$round_number'";
                    $result1 = $conn->query($query1);
                
                    $cartela_numbers = [];
                    $category = "";
                    
                    if ($result1->num_rows > 0) {
                        while ($row = $result1->fetch_assoc()) {
                            $cartela_numbers[] = $row['cartela_number'];
                            $category = $row['category'];
                        }
                    }
                
                    if (empty($cartela_numbers)) {
                        if ($debug){ echo "No cards found - returning simple numbers\n"; }
                        return range(1, 10);
                    }
                
                    // Fetch all card data (file when category in cards_data.js, else cartela table)
                    $flat_numbers = [];
                    foreach ($cartela_numbers as $cn) {
                        $flat_numbers = array_merge(
                            $flat_numbers,
                            array_map('intval', array_filter(explode(',', (string) $cn)))
                        );
                    }
                    $cartela_rows = cartela_fetch_many($conn, $flat_numbers, $category);
                
                    if ($debug) {
                         echo "Total cartela: " . count($cartela_rows) . "\n"; 
                    }
                
                    $used_numbers = [];
                
                    if (!empty($cartela_rows)) {
                        foreach ($cartela_rows as $row) {
                            if($debug ){ echo "\n=== Card #" . $row['cartela_number'] . " ===\n" ; }
                
                            $columns = ['b', 'i', 'n', 'g', 'o'];
                            foreach ($columns as $col) {
                                $numbers = array_map('intval', explode(',', $row[$col]));
                                shuffle($numbers); // Optional shuffle per column
                
                                 if ($debug){ echo strtoupper($col) . ": " . implode(', ', $numbers) . "\n"; }
                
                                $used_numbers = array_merge($used_numbers, $numbers);
                            }
                
                        }
                    } else {
                        if ($debug) {
                              echo "❌ No matching cartela rows found in database.\n"; 
                        }
                        return [];
                    }
                     if ($debug){ 
                        echo "\n=== All Merged Used Numbers (Before Deduplication) ===\n";
                        echo implode(', ', $used_numbers) . "\n";
                     }
                
                    $unique_used_numbers = array_unique($used_numbers);
                    shuffle($unique_used_numbers);
                    if ($debug){ 
                        echo "\n=== Unique Used Numbers After Deduplication & Shuffle ===\n";
                        echo implode(', ', $unique_used_numbers) . "\n";
                     }
                    
                
                    $total_available = count($unique_used_numbers);
                    $final_draw_numbers = $unique_used_numbers;
                
                    if ($total_available < $count_to_be_returned) {
                        if ($debug) {
                            echo "\n⚠️ Warning: Not enough unique numbers available! Requested $count_to_be_returned, but only $total_available found.\n";
                        }
                
                        // Add 5 extra unused numbers
                        $full_bingo_range = range(1, 75);
                        $unused_numbers = array_values(array_diff($full_bingo_range, $unique_used_numbers));
                        shuffle($unused_numbers);
                
                        $additional_needed = min(5, count($unused_numbers));
                        $extra_numbers = array_slice($unused_numbers, 0, $additional_needed);
                        $final_draw_numbers = array_merge($final_draw_numbers, $extra_numbers);
                        shuffle($final_draw_numbers); // Final shuffle after merging extras
                
                        if ($debug) {
                            echo "=== Added Extra Unused Numbers ===\n";
                            echo implode(', ', $extra_numbers) . "\n";
                            echo "=== Final Shuffled Numbers (Used + Extra) ===\n";
                            echo implode(', ', $final_draw_numbers) . "\n";
                        }
                    }
                
                    // Final limit based on available size
                    $final_return_count = min($count_to_be_returned, count($final_draw_numbers));
                    shuffle($final_draw_numbers);
                    
                    
                    if ($debug) {
                        $preview = array_slice($final_draw_numbers, 0, $final_return_count);
                        echo "=== Selected Final Numbers to Return (Count: $final_return_count) ===\n";
                        echo implode(', ', $preview) . "\n";
                    }
                
                    return array_slice($final_draw_numbers, 0, $final_return_count);
                }
                
                function selectSafeUsedNumbers($card_data, $card_positions, $existing_numbers, $count_needed, $debug = false) {
                    $selected = [];
                    $attempts = 0;
                    $max_attempts = 200;
                    
                    // Get all possible used numbers
                    $all_used_numbers = [];
                    foreach ($card_data as $numbers) {
                        $all_used_numbers = array_merge($all_used_numbers, $numbers);
                    }
                    $all_used_numbers = array_unique($all_used_numbers);
                    $all_used_numbers = array_diff($all_used_numbers, $existing_numbers);
                    
                    // Sort by frequency (least used first)
                    $frequency = array_count_values($all_used_numbers);
                    usort($all_used_numbers, function($a, $b) use ($frequency) {
                        return ($frequency[$a] ?? 0) <=> ($frequency[$b] ?? 0);
                    });
                
                    if ($debug) {
                        echo "Trying to select from " . count($all_used_numbers) . " used numbers\n";
                    }
                
                    while (count($selected) < $count_needed && $attempts < $max_attempts) {
                        $attempts++;
                        
                        foreach ($all_used_numbers as $num) {
                            if (in_array($num, $selected)) continue;
                            
                            $temp_numbers = array_merge($existing_numbers, $selected, [$num]);
                            
                            if (isNumberSafe($num, $card_data, $card_positions, $temp_numbers)) {
                                $selected[] = $num;
                                if ($debug) echo "  Selected $num (appears on " . ($frequency[$num] ?? 0) . " cards)\n";
                                if (count($selected) >= $count_needed) break 2;
                            }
                        }
                    }
                    
                    if ($debug && count($selected) < $count_needed) {
                        echo "Warning: Only found " . count($selected) . " safe numbers after $attempts attempts\n";
                    }
                    
                    return array_slice($selected, 0, $count_needed);
                }
                
                function isNumberSafe($num, $card_data, $card_positions, $drawn_numbers) {
                    $max_per_card = 3;
                    
                    foreach ($card_data as $card_number => $numbers) {
                        if (in_array($num, $numbers)) {
                            // Check max numbers per card
                            $current_hits = count(array_intersect($drawn_numbers, $numbers));
                            if ($current_hits >= $max_per_card) return false;
                            
                            // Check pattern completion
                            if (wouldCompletePattern($num, $card_number, $card_positions, $drawn_numbers)) {
                                return false;
                            }
                        }
                    }
                    return true;
                }
                
                function wouldCompletePattern($num, $card_number, $card_positions, $drawn_numbers) {
                    if (!isset($card_positions[$card_number][$num])) return false;
                    
                    $pos = $card_positions[$card_number][$num];
                    $row = $pos['row'];
                    $col = $pos['col'];
                    
                    $patterns = [
                        'row' => 0,
                        'col' => 0,
                        'diag1' => 0,
                        'diag2' => 0,
                        'corners' => 0,
                        'internal' => 0
                    ];
                    
                    foreach ($drawn_numbers as $drawn_num) {
                        if (!isset($card_positions[$card_number][$drawn_num])) continue;
                        
                        $drawn_pos = $card_positions[$card_number][$drawn_num];
                        
                        // Check row
                        if ($drawn_pos['row'] == $row) $patterns['row']++;
                        
                        // Check column
                        if ($drawn_pos['col'] == $col) $patterns['col']++;
                        
                        // Check diagonals
                        if ($drawn_pos['row'] == $drawn_pos['col']) $patterns['diag1']++;
                        if ($drawn_pos['row'] + $drawn_pos['col'] == 4) $patterns['diag2']++;
                        
                        // Check corners (B1, O1, B5, O5)
                        if (($drawn_pos['row'] == 0 || $drawn_pos['row'] == 4) && 
                            ($drawn_pos['col'] == 0 || $drawn_pos['col'] == 4)) {
                            $patterns['corners']++;
                        }
                        
                        // Check internal corners (I2, G2, I4, G4)
                        if (($drawn_pos['row'] == 1 || $drawn_pos['row'] == 3) && 
                            ($drawn_pos['col'] == 1 || $drawn_pos['col'] == 3)) {
                            $patterns['internal']++;
                        }
                    }
                    
                    // Custom pattern rules
                    if ($patterns['corners'] >= 1) return true;  // Block any corner marks
                    if ($patterns['internal'] >= 1) return true; // Block any internal corner marks
                    
                    // Row-specific rules (middle row N is free)
                    if ($row != 2) { // Not the middle row
                        if ($patterns['row'] >= 2) return true; // Max 2 in other rows
                    }
                    
                    // Column-specific rules (N column is free)
                    if ($col != 2) { // Not the N column
                        if ($patterns['col'] >= 2) return true; // Max 2 in other columns
                    }
                    
                    // Diagonal rules
                    if ($patterns['diag1'] >= 2) return true;
                    if ($patterns['diag2'] >= 2) return true;
                    
                    return false;
                }
                
             
                function getEmergencyNumbers($unused_numbers, $used_numbers, $debug = false) {
                    if ($debug) {
                        echo "\n=== EMERGENCY NUMBER SELECTION ===\n";
                        echo "Unused available: " . count($unused_numbers) . "\n";
                    }
                    
                    $result = array_slice($unused_numbers, 0, 10);
                    
                    if (count($result) < 10) {
                        $remaining = 10 - count($result);
                        $available = array_diff(range(1, 75), $unused_numbers);
                        $frequency = array_count_values($used_numbers);
                        
                        // Sort by least used
                        usort($available, function($a, $b) use ($frequency) {
                            return ($frequency[$a] ?? 0) <=> ($frequency[$b] ?? 0);
                        });
                        
                        $safe_numbers = array_slice($available, 0, $remaining);
                        $result = array_merge($result, $safe_numbers);
                        
                        if ($debug) {
                            echo "Added $remaining least-used numbers:\n";
                            foreach ($safe_numbers as $num) {
                                echo " - $num (on " . ($frequency[$num] ?? 0) . " cards)\n";
                            }
                        }
                    }
                    
                    shuffle($result);
                    return array_slice($result, 0, 10);
                }
                
                function verifyNoWinningPatterns($drawn_numbers, $card_positions) {
                    $debug = false;
                    $cards_checked = 0;
                    
                    if ($debug) {
                        echo "\n=== PATTERN VERIFICATION ===\n";
                        echo "Numbers: " . implode(', ', $drawn_numbers) . "\n";
                    }
                    
                    foreach ($card_positions as $card_number => $positions) {
                        $cards_checked++;
                        $marked = array_fill(0, 5, array_fill(0, 5, false));
                        $patterns = [
                            'rows' => array_fill(0, 5, 0),
                            'cols' => array_fill(0, 5, 0),
                            'diag1' => 0,
                            'diag2' => 0,
                            'corners' => 0,
                            'internal' => 0
                        ];
                        
                        // Mark numbers and count patterns
                        foreach ($drawn_numbers as $num) {
                            if (isset($positions[$num])) {
                                $pos = $positions[$num];
                                $marked[$pos['row']][$pos['col']] = true;
                                
                                $patterns['rows'][$pos['row']]++;
                                $patterns['cols'][$pos['col']]++;
                                
                                if ($pos['row'] == $pos['col']) $patterns['diag1']++;
                                if ($pos['row'] + $pos['col'] == 4) $patterns['diag2']++;
                                
                                // Check corners
                                if (($pos['row'] == 0 || $pos['row'] == 4) && 
                                    ($pos['col'] == 0 || $pos['col'] == 4)) {
                                    $patterns['corners']++;
                                }
                                
                                // Check internal corners
                                if (($pos['row'] == 1 || $pos['row'] == 3) && 
                                    ($pos['col'] == 1 || $pos['col'] == 3)) {
                                    $patterns['internal']++;
                                }
                            }
                        }
                        
                        if ($debug) {
                            echo "\nCard #$card_number:\n";
                            echo "   B  I  N  G  O\n";
                            for ($row = 0; $row < 5; $row++) {
                                echo ($row+1)." ";
                                for ($col = 0; $col < 5; $col++) {
                                    echo $marked[$row][$col] ? "[X]" : "[ ]";
                                }
                                echo "\n";
                            }
                            echo "Row counts:    ".implode(',', $patterns['rows'])."\n";
                            echo "Column counts: ".implode(',', $patterns['cols'])."\n";
                            echo "Diagonals:     \\ {$patterns['diag1']} / {$patterns['diag2']}\n";
                            echo "Corners:       {$patterns['corners']} marked\n";
                            echo "Internal:      {$patterns['internal']} marked\n";
                        }
                        
                        // Check for potential wins
                        if (max($patterns['rows']) >= 3 || 
                            max($patterns['cols']) >= 3 || 
                            $patterns['diag1'] >= 3 || 
                            $patterns['diag2'] >= 3 ||
                            $patterns['corners'] >= 3 ||
                            $patterns['internal'] >= 3) {
                            if ($debug) echo "! Potential win detected on card #$card_number\n";
                            return false;
                        }
                    }
                    
                    if ($debug) {
                        echo "\n=== VERIFICATION COMPLETE ===\n";
                        echo "Checked $cards_checked cards - no winning patterns found\n";
                    }
                    
                    return true;
                }

                function generateBonusWinnerNumber($conn, $round_number, $cashier_id)
                {
                    // 1. Fetch Used Numbers and Card Numbers
                    $cartela_numbers = [];

                    // Fetch all `cartela_number` from `game`
                    $query1  = "SELECT cartela_number FROM game WHERE cashier_id='$cashier_id' AND round_number='$round_number'";
                    $result1 = $conn->query($query1);

                    if ($result1->num_rows > 0) {
                        while ($row = $result1->fetch_assoc()) {
                            $numbers         = explode(',', $row['cartela_number']); // Convert string to array
                            $cartela_numbers = array_merge($cartela_numbers, array_map('intval', $numbers));
                        }
                    }

                    // Fetch b,i,n,g,o (file when category in cards_data.js, else cartela table)
                    $category = cartela_get_cashier_category($conn, $cashier_id);
                    $cartela_rows = cartela_fetch_many($conn, $cartela_numbers, $category);

                    if (!empty($cartela_rows)) {
                        foreach ($cartela_rows as $row) {
                            foreach (['b', 'i', 'n', 'g', 'o'] as $col) {
                                $cartela_numbers = array_merge($cartela_numbers, explode(',', $row[$col]));
                            }
                        }
                    }

                    $cartela_numbers = array_values(array_unique(array_map('intval', $cartela_numbers))); // Remove duplicates and ensure integers

                    // 2. Identify Unused Numbers
                    $all_numbers    = range(1, 75);
                    $unused_numbers = array_values(array_diff($all_numbers, $cartela_numbers));

                    // 3. Get Winning Patterns and Identify Ending Numbers
                    $winning_patterns = getWinningPatternsFromCard($cartela_numbers);
                    $ending_numbers   = [];
                    foreach ($winning_patterns as $pattern) {
                        $ending_numbers[] = end($pattern);
                    }
                    $ending_numbers = array_map('intval', array_unique($ending_numbers));

                    // 4. Generate Bonus Numbers with Strict Exclusion
                    function getNumberOrRandom($unused, $min, $max, $excluded = [])
                    {
                        $available = array_diff($unused, $excluded);
                        if (! empty($available)) {
                            return $available[array_rand($available)];
                        } else {
                                                         // If no unused numbers are available after exclusion, try a few randoms
                            for ($i = 0; $i < 5; $i++) { // Try up to 5 times
                                $random = rand($min, $max);
                                if (! in_array($random, $excluded)) {
                                    return $random;
                                }

                            }
                            return null; // Return null if no available number exists
                        }
                    }

                    $winner_numbers = [];
                    foreach (['b' => [1, 15], 'i' => [16, 30], 'n' => [31, 45], 'g' => [46, 60], 'o' => [61, 75]] as $letter => $range) {
                        $number = null;
                        for ($i = 0; $i < 10; $i++) { // Try multiple times to find a valid number
                            $number = getNumberOrRandom(
                                array_filter(range($range[0], $range[1]), fn($n) => ! in_array($n, $cartela_numbers)), //Exclude numbers on the card
                                $range[0],
                                $range[1],
                                $ending_numbers
                            );
                            if ($number !== null) {
                                break;
                            }
                            // Exit if a valid number is found
                        }
                        if ($number === null) {
                            // Handle the extremely rare case where no valid number can be found
                            // Log an error, throw an exception, or use a fallback.
                            //error_log("Could not generate a bonus number for category " . $letter . " after multiple attempts.  Consider increasing the number of attempts or adjusting the exclusion criteria.");
                            // For now, let's just use a random number within the range (not ideal)
                            $number = rand($range[0], $range[1]);
                        }
                        $winner_numbers[] = $number;
                    }

                    $winner_number = implode(",", $winner_numbers);
                    return $winner_number;
                }

                function getWinningPatternsFromCard($selectedCard)
                {
                    $winning_patterns = [];

                    if (empty($selectedCard)) {
                        return $winning_patterns; // Handle empty card case
                    }

                    $numbers = $selectedCard;            // $selectedCard is already an array of numbers
                    $card    = array_chunk($numbers, 5); // Split into 5 rows of 5 columns

                    // Rows
                    foreach ($card as $row) {
                        $winning_patterns[] = $row;
                    }

                    // Columns
                    for ($col = 0; $col < 5; $col++) {
                        $column = [];
                        for ($row = 0; $row < 5; $row++) {
                            $column[] = $card[$row][$col];
                        }
                        $winning_patterns[] = $column;
                    }

                    // Diagonals
                    $diagonal1          = [$card[0][0], $card[1][1], $card[2][2], $card[3][3], $card[4][4]];
                    $diagonal2          = [$card[0][4], $card[1][3], $card[2][2], $card[3][1], $card[4][0]];
                    $winning_patterns[] = $diagonal1;
                    $winning_patterns[] = $diagonal2;

                    // Four Corners
                    $fourCorners        = [$card[0][0], $card[0][4], $card[4][0], $card[4][4]];
                    $winning_patterns[] = $fourCorners;

                    return $winning_patterns;
                }










                if ($existingGame) 
                {
                    
                    //first update select3d card then we will update first draw based on the new updated data
                    // Update game entry
                    $stmttttt = $conn->prepare("UPDATE game SET cartela_number = ?, price = ?, pattern = ? WHERE id = ?");
                    $stmttttt->bind_param("ssii", $selectedcard, $price, $pattern, $existingGame['id']);
                    $stmttttt->execute(); 
                    
                    /////   if error remove $first_priority_drawn_num   ////////////

                    // Initialize an empty array for the first priority drawn numbers
                    $first_priority_drawn_num = [];
                    // Check if the partner_id is "24" Esubalew
                    // 17 Abe yonas
                    
                    
                    
                    // if ($cashier['partner_id'] == "24" || $cashier['partner_id'] == "17" ||$cashier['partner_id'] == "13") {
                    //     $first_priority_drawn_num = getFirst10DrawnNumber($conn, $register_new_game_round, $cashier_id) ?: [];
                    // }
                    // if (   $cashier['partner_id'] == "15"  ) {
                    //     $first_priority_drawn_num = drawnOnlySelectedNumber($conn, $register_new_game_round, $cashier_id, 30) ?: [];
                    // }
                    
                    
                    

                    // Remove 0 from the returned numbers
                    $first_priority_drawn_num = array_filter($first_priority_drawn_num, function ($num) {
                        return $num > 0;
                    });
                    $first_priority_drawn_num_str = ! empty($first_priority_drawn_num) ? implode(',', $first_priority_drawn_num) : '';

                    // Update game entry
                    $stmt = $conn->prepare("UPDATE game SET cartela_number = ?, price = ?, pattern = ?, first_draw = ? WHERE id = ?");
                    $stmt->bind_param("ssisi", $selectedcard, $price, $pattern, $first_priority_drawn_num_str, $existingGame['id']);
                    $stmt->execute();

                    // Prepare success response for update
                    $response = ["status" => "success", "message" => "Card updated successfully"];
                } else {
                                                              // No existing game entry, insert a new one
                    $round_number = $register_new_game_round; // Use the provided round_number

                    // Step 3: Insert into the `game` table with the new round_number
                    $stmt = $conn->prepare("INSERT INTO game (cartela_number, cashier_id, price, pattern, round_number) VALUES (?, ?, ?, ?, ?)");
                    $stmt->bind_param("sssii", $selectedcard, $cashier_id, $price, $pattern, $round_number);
                    $stmt->execute();

                    /////   if error remove $first_priority_drawn_num   ////////////

                    $first_priority_drawn_num = [];
                    // Check if the partner_id is "24"
                    
                    
                    // if ($cashier['partner_id'] == "24" || $cashier['partner_id'] == "17" ||$cashier['partner_id'] == "13") {
                    //     $first_priority_drawn_num = getFirst10DrawnNumber($conn, $register_new_game_round, $cashier_id) ?: [];
                    // }
                    // if (  $cashier['partner_id'] == "15"  ) {
                    //     $first_priority_drawn_num = drawnOnlySelectedNumber($conn, $register_new_game_round, $cashier_id, 30) ?: [];
                    // }
                    
                    
                    
                    
                    // Remove 0 from the returned numbers
                    $first_priority_drawn_num = array_filter($first_priority_drawn_num, function ($num) {
                        return $num > 0;
                    });
                    $first_priority_drawn_num_str = ! empty($first_priority_drawn_num) ? implode(',', $first_priority_drawn_num) : '';

                    // Update game entry
                    $stmt = $conn->prepare("UPDATE game SET first_draw = ? WHERE round_number = ? AND cashier_id = ?  AND DATE(date) = CURDATE()");
                    $stmt->bind_param("sis", $first_priority_drawn_num_str, $register_new_game_round, $cashier_id);
                    $stmt->execute();

                    ////////////////////////////////////////////////////////////////

                    // Call the function and store the result in $winner_number
                    $winner_number = generateBonusWinnerNumber($conn, $round_number, $cashier_id);
                    $stmt_binus    = $conn->prepare("INSERT INTO `new_bonus`(`cashier_id`, `game_id`, `winner_number`) VALUES (?, ?, ?)");
                    $stmt_binus->bind_param("sis", $cashier_id, $round_number, $winner_number);
                    $stmt_binus->execute();

                    // Prepare success response for insert  "Card saved successfully"
                    $response = ["status" => "success", "message" => "Card saved successfully"];
                }
            }

        } else {
            $response = ["status" => "error", "message" => "Error saving card: " . $e->getMessage()];
        }
    } catch (mysqli_sql_exception $e) {
        // Handle database error
        $response = ["status" => "error", "message" => "Error saving card: " . $e->getMessage()];
    }

    if (
        $roundAdjustInfo !== null
        && ($response['status'] ?? '') === 'success'
    ) {
        $response['info'] = $roundAdjustInfo;
        $response['game_round'] = (int) $register_new_game_round;
    }

    // Output the JSON response
    print(json_encode($response));
    exit;
}

//==========================update cashier with sound range or level ===================================
if (isset($_POST['cashier_sound_range_value']) && isset($_POST['cashier_id'])) {
    $cashier_sound_range_value = $_POST['cashier_sound_range_value']; // The selected card numbers
    $cashier_id                = $_POST['cashier_id'];                // The price paid for the card
    $response                  = [];

    try {
        // update into the `cashier` table
        $stmt = $conn->prepare("UPDATE `cashier` SET  `speed_range`=?  WHERE `cashier_id`=?");
        $stmt->execute([$cashier_sound_range_value, $cashier_id]);

        // Prepare success response
        $response = ["status" => "success", "message" => "Sound Range saved successfully"];
    } catch (PDOException $e) {
        // Handle database error
        $response = ["status" => "error", "message" => "Error saving data: " . $e->getMessage()];
    }

    // Output the JSON response
    print(json_encode($response));
    exit;
}

//==========================update cashier with selected sound ===================================
if (isset($_POST['selectvoice']) && isset($_POST['cashier_id'])) {
    $selectvoice = $_POST['selectvoice'];
    $cashier_id  = $_POST['cashier_id'];
    $response    = [];

    try {
        // update into the `cashier` table
        $stmt = $conn->prepare("UPDATE `cashier` SET  `sound`=?  WHERE `cashier_id`=?");
        $stmt->execute([$selectvoice, $cashier_id]);

        // Prepare success response
        $response = ["status" => "success", "message" => "Sound type saved successfully"];
    } catch (PDOException $e) {
        // Handle database error
        $response = ["status" => "error", "message" => "Error saving data: " . $e->getMessage()];
    }

    // Output the JSON response
    print(json_encode($response));
    exit;
}

//   ========================== get cartela data  ==================================================================
if (isset($_POST['cashiername']) && isset($_POST['get_cartela_data'])) {
    // Initialize response array
    $response = [];
                                                                                                              // Prepare the SQL query to fetch specific data from the cartela table
    $query = "SELECT `cartela_number`, `b`, `i`, `n`, `g`, `o`, `date`, `partner_id` FROM `cartela` WHERE 1"; // Fetch all records
    $stmt  = $conn->prepare($query);

    if (false === $stmt) {
        // Error in preparing statement
        $response['error'] = "Error in query: " . $conn->error;
    } else {
        // Execute the statement
        $stmt->execute();

        // Get result
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            // Fetch associative array for each row
            while ($row = $result->fetch_assoc()) {
                $response[] = $row; // Append each row to the response array
            }
            $response['status'] = "success"; // Set success status
        } else {
            $response['message'] = "No data found.";
            $response['status']  = "success"; // Still a success status with a message
        }

        // Free the result
        $result->free();
    }

    // Output the JSON response
    header('Content-Type: application/json');
    echo json_encode($response);
    exit;
}

//==========================update game with result ===================================
if (isset($_POST['result']) && isset($_POST['round']) && isset($_POST['cashier_id'])) {
    $result     = $_POST['result'];
    $round      = $_POST['round'];
    $cashier_id = $_POST['cashier_id'];
    $response   = [];

    $stmt = $conn->prepare('UPDATE `game` SET `result` = ? WHERE `cashier_id` = ? AND `round_number` = ?');
    if ($stmt) {
        $stmt->bind_param('sss', $result, $cashier_id, $round);
        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                $response = ['status' => 'success', 'message' => 'Result saved successfully'];
            } else {
                $response = ['status' => 'info', 'message' => 'No changes were made.'];
            }
        } else {
            $response = ['status' => 'error', 'message' => 'Error saving data: ' . $stmt->error];
        }
        $stmt->close();
    } else {
        $response = ['status' => 'error', 'message' => 'Error preparing save query: ' . $conn->error];
    }

    print(json_encode($response));
    exit;
}

// ========================== get datas during startup or on loading data ==================================================================
if (isset($_POST['cashier_id']) && isset($_POST['get_onload_data'])) {
    // Initialize response array
    $response   = [];
    $cashier_id = $_POST['cashier_id'];

    // Prepare the SQL query to fetch specific data from the game table
    $query = "
			SELECT
				game.`round_number`,
				game.`cartela_number`,
				cashier.`cashier_id`,
				cashier.`partner_id`,
				cashier.`is_loggedin`,
				cashier.`loggin_time`,
				cashier.`is_locked`,
				cashier.`is_active`,
				cashier.`login_attempts`,
				cashier.`speed_range`,
				cashier.`sound`,
				game.`price`,
				game.`pattern`,
				game.`result`,
				game.`date`,
				game.`iscompleted`
			FROM `game`
			JOIN `cashier` ON game.`cashier_id` = cashier.`cashier_id`
			WHERE
				game.`iscompleted` = 0
				AND game.`cashier_id` = ?
			ORDER BY game.`round_number` DESC
			LIMIT 1;"; // Limit to the latest round

    $stmt = $conn->prepare($query);

    if (false === $stmt) {
        // Error in preparing statement
        $response['error'] = "Error in query: " . $conn->error;
    } else {
                                             // Bind the parameter
        $stmt->bind_param("s", $cashier_id); // Assuming cashier_id is a string

        // Execute the statement
        $stmt->execute();

        // Get result
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            // Fetch associative array for each row
            while ($row = $result->fetch_assoc()) {
                $response[] = $row; // Append each row to the response array
            }
            $response['status'] = "success"; // Set success status
        } else {
            $response['message'] = "No data found.";
            $response['status']  = "success"; // Still a success status with a message
        }

        // Free the result
        $result->free();
    }

    // Output the JSON response
    header('Content-Type: application/json');
    echo json_encode($response);
    exit;
}

//==========================save transaction  ===================================
// if (isset($_POST['round_number']) && isset($_POST['santim']) && isset($_POST['sew']) && isset($_POST['income']) && isset($_POST['cashier_id'])) {
// 	// Sanitize input
// 	$cashier_id = $_POST['cashier_id'];
// 	$game_round = $_POST['round_number'];
// 	$santim = $_POST['santim'];
// 	$sew = $_POST['sew'];
// 	$income = $_POST['income'];
// 	$bonus_amount = $_POST['bonus_amount'];

// 	// Start a transaction to ensure atomicity
// 	mysqli_begin_transaction($conn);

// 	try {
// 		// Check if the transaction already exists
// 		$checkQuery = "SELECT * FROM `transaction` WHERE `game_round` = '$game_round' AND `cashier_id` = '$cashier_id' AND DATE(date) = CURDATE()";
// 		$result = mysqli_query($conn, $checkQuery);

// 		if (mysqli_num_rows($result) > 0)
// 		{
// 			// Transaction exists, update it
// 			$updateQuery = "UPDATE `transaction`
// 							SET `santim` = '$santim', `sew` = '$sew', `income` = '$income'
// 							WHERE `game_round` = '$game_round' AND `cashier_id` = '$cashier_id' AND DATE(date) = CURDATE()";

// 			if (!mysqli_query($conn, $updateQuery)) {
// 				throw new Exception('Error updating transaction: ' . mysqli_error($conn));
// 			}

// 			$response = ['status' => 'success', 'message' => 'Transaction updated successfully'];
// 		} else
// 		{
// 			// Transaction does not exist, insert it
// 			$insertQuery = "INSERT INTO `transaction` (`cashier_id`, `game_round`, `santim`, `sew`, `income`, `bonus`)
// 							VALUES ('$cashier_id', '$game_round', '$santim', '$sew', '$income', '$bonus_amount')";

// 			if (!mysqli_query($conn, $insertQuery)) {
// 				throw new Exception('Error inserting transaction: ' . mysqli_error($conn));
// 			}

// 			$response = ['status' => 'success', 'message' => 'Transaction saved successfully.'];
// 		}

// 		//===============================================================
// 		// Step 1: Fetch the current cashier package
// 		$cashierQuery = "SELECT cashier_package FROM `cashier` WHERE `cashier_id` = '$cashier_id'";
// 		$cashierResult = mysqli_query($conn, $cashierQuery);

// 		if (mysqli_num_rows($cashierResult) > 0) {
// 			$cashier = mysqli_fetch_assoc($cashierResult);
// 			$currentCashierPackage = $cashier['cashier_package'];

// 			// Step 2: Calculate the new cashier package
// 			$newCashierPackage = $currentCashierPackage - ($income + $bonus_amount);

// 			// Step 3: Update the cashier's package in the database
// 			$updateCashierPackageQuery = "UPDATE `cashier` SET `cashier_package` = '$newCashierPackage' WHERE `cashier_id` = '$cashier_id'";

// 			if (!mysqli_query($conn, $updateCashierPackageQuery)) {
// 				throw new Exception('Error updating cashier package: ' . mysqli_error($conn));
// 			}
// 		} else {
// 			throw new Exception('Cashier not found.');
// 		}

// 		// Commit the transaction
// 		mysqli_commit($conn);
// 	} catch (Exception $e) {
// 		// Rollback the transaction in case of error
// 		mysqli_rollback($conn);
// 		$response = ['status' => 'error', 'message' => $e->getMessage()];
// 	}

// 	// Output the JSON response
// 	print(json_encode($response));
// 	exit;
// }

//==========================Game completed and save transaction===================================
if (isset($_POST['round_number']) && isset($_POST['santim']) && isset($_POST['sew']) && isset($_POST['income']) && isset($_POST['cashier_id'])) {
    // Sanitize input
    $cashier_id   = mysqli_real_escape_string($conn, $_POST['cashier_id']);
    $game_round   = mysqli_real_escape_string($conn, $_POST['round_number']);
    $santim       = mysqli_real_escape_string($conn, $_POST['santim']);
    $sew          = mysqli_real_escape_string($conn, $_POST['sew']);
    $income       = mysqli_real_escape_string($conn, $_POST['income']);
    $bonus_amount = mysqli_real_escape_string($conn, $_POST['bonus_amount']);

    // Start a transaction to ensure atomicity
    mysqli_begin_transaction($conn);

    try {
        // Check if the transaction already exists
        $checkQuery = "SELECT * FROM `transaction` WHERE `game_round` = '$game_round' AND `cashier_id` = '$cashier_id' AND DATE(date) = CURDATE()";
        $result     = mysqli_query($conn, $checkQuery);

        if (mysqli_num_rows($result) > 0) {
            // Transaction exists, update it
            $updateQuery = "UPDATE `transaction`
										SET `santim` = '$santim', `sew` = '$sew', `income` = '$income'
										WHERE `game_round` = '$game_round' AND `cashier_id` = '$cashier_id' AND DATE(date) = CURDATE()";
            if (! mysqli_query($conn, $updateQuery)) {
                throw new Exception('Error updating transaction: ' . mysqli_error($conn));
            }
            $response = ['status' => 'success', 'message' => 'Transaction updated successfully'];
        } else {
            // Transaction does not exist, insert it
            $insertQuery = "INSERT INTO `transaction` (`cashier_id`, `game_round`, `santim`, `sew`, `income`, `bonus`)
										VALUES ('$cashier_id', '$game_round', '$santim', '$sew', '$income', '$bonus_amount')";
            if (! mysqli_query($conn, $insertQuery)) {
                throw new Exception('Error inserting transaction: ' . mysqli_error($conn));
            }
            $response = ['status' => 'success', 'message' => 'Transaction saved successfully.'];
        }

        // Step 1: Fetch the current cashier package
        $cashierQuery  = "SELECT cashier_package FROM `cashier` WHERE `cashier_id` = '$cashier_id'";
        $cashierResult = mysqli_query($conn, $cashierQuery);

        if (mysqli_num_rows($cashierResult) > 0) {
            $cashier               = mysqli_fetch_assoc($cashierResult);
            $currentCashierPackage = $cashier['cashier_package'];
            // $newCashierPackage = base64_encode(openssl_encrypt(10000, 'AES-256-CBC', ENCRYPTION_KEY, 0, ENCRYPTION_IV));
            $currentCashierPackage = openssl_decrypt(base64_decode($currentCashierPackage), 'AES-256-CBC', ENCRYPTION_KEY, 0, ENCRYPTION_IV);

            // Step 2: Calculate the new cashier package
            $newCashierPackage = $currentCashierPackage - ($income - $bonus_amount);
            $newCashierPackage = base64_encode(openssl_encrypt($newCashierPackage, 'AES-256-CBC', ENCRYPTION_KEY, 0, ENCRYPTION_IV));

            
            // Step 3: Update the cashier's package in the database
            $updateCashierPackageQuery = "UPDATE `cashier` SET `cashier_package` = '$newCashierPackage' WHERE `cashier_id` = '$cashier_id'";
            if (! mysqli_query($conn, $updateCashierPackageQuery)) {
                throw new Exception('Error updating cashier package: ' . mysqli_error($conn));
            }

            // Step 4: Mark the game as completed if there are results

            $completeGameQuery = "UPDATE `game` SET `iscompleted` = 1 WHERE `round_number` = '$game_round' AND `cashier_id` = '$cashier_id'";
            if (! mysqli_query($conn, $completeGameQuery)) {
                throw new Exception('Error marking game as completed: ' . mysqli_error($conn));
            }

        } else {
            throw new Exception('Cashier not found.');
        }

        // Commit the transaction
        mysqli_commit($conn);
    } catch (Exception $e) {
        // Rollback the transaction in case of error
        mysqli_rollback($conn);
        $response = ['status' => 'error', 'message' => $e->getMessage()];
    }

    // Output the JSON response
    print(json_encode($response));
    exit;
}

//==========================Game completed  ===================================
if (isset($_POST['game_completed']) && isset($_POST['round_number']) && isset($_POST['cashier_id'])) {
    // Sanitize input
    $cashier_id = mysqli_real_escape_string($conn, $_POST['cashier_id']);
    $game_round = mysqli_real_escape_string($conn, $_POST['round_number']);

    // Check if there are results for the specified round
    $checkResultsQuery = "SELECT `result` FROM `game` WHERE `round_number` = '$game_round' AND `cashier_id` = '$cashier_id'";
    $result            = mysqli_query($conn, $checkResultsQuery);

    if ($result && mysqli_num_rows($result) > 0) {
        $row         = mysqli_fetch_assoc($result);
        $resultsData = $row['result']; // Assuming 'result' is the column name where results are stored

        // Check if the results string is not empty
        if (! empty(trim($resultsData))) {
            // Results exist, proceed to mark the game as completed
            $completeGameQuery = "UPDATE `game` SET `iscompleted` = 1 WHERE `round_number` = '$game_round' AND `cashier_id` = '$cashier_id'";
            if (mysqli_query($conn, $completeGameQuery)) {
                $response = ['status' => 'success', 'message' => 'Game marked as completed.'];

                $updateTransactionQuery = "UPDATE `transaction`
                                                       SET `result` = '$resultsData'
                                                       WHERE `cashier_id` = '$cashier_id'
                                                       AND `game_round` = '$game_round'
                                                       AND DATE(`date`) = CURDATE()";

                if (mysqli_query($conn, $updateTransactionQuery)) {
                    $response = ['status' => 'success', 'message' => 'Game marked as completed and results saved in transactions.'];
                } else {
                    $response = ['status' => 'error', 'message' => 'Game completed, but failed to update transactions: ' . mysqli_error($conn)];
                }
            } else {
                $response = ['status' => 'error', 'message' => 'Error on completing game: ' . mysqli_error($conn)];
            }
        } else {
            // No results found for this round
            $response = ['status' => 'error', 'message' => 'Play before closing pls.'];
        }
    } else {
        // No game record found for the specified round and cashier
        $response = ['status' => 'error', 'message' => 'Game not found for the specified round and cashier.'];
    }

    // Output the JSON response
    print(json_encode($response));
    exit;
}

//==========================block unwinning user ===================================
if (isset($_POST['block_user_cartela']) && isset($_POST['round_number']) && isset($_POST['cashier_id'])) {
    // Sanitize input
    $cartela_number = $_POST['block_user_cartela'];
    $cashier_id     = $_POST['cashier_id'];
    $game_round     = $_POST['round_number'];

    // Start a transaction
    mysqli_begin_transaction($conn);

    // Default response
    $response = ['status' => 'error', 'message' => 'An unknown error occurred.'];

    // First, get the existing locked_cartela_number
    $selectQuery = "SELECT `locked_cartela_number` FROM `game` WHERE `round_number` = '$game_round' AND `cashier_id` = '$cashier_id'";
    $result      = mysqli_query($conn, $selectQuery);

    if ($result && mysqli_num_rows($result) > 0) {
        $row                            = mysqli_fetch_assoc($result);
        $existing_locked_cartela_number = $row['locked_cartela_number'] ?? ''; // Use an empty string if null

        // Check if the cartela_number is already in the locked list
        $locked_cartelas = explode(',', $existing_locked_cartela_number);
        if (in_array($cartela_number, $locked_cartelas)) {
            $response['message'] = 'Cartela number is already locked.';
        } else {
            // Append the new cartela_number
            $new_locked_cartela_number = ! empty($existing_locked_cartela_number)
            ? $existing_locked_cartela_number . ',' . $cartela_number
            : $cartela_number;

            // Update the locked_cartela_number
            $updateQuery = "UPDATE `game` SET `locked_cartela_number` = '$new_locked_cartela_number' WHERE `round_number` = '$game_round' AND `cashier_id` = '$cashier_id'";
            if (mysqli_query($conn, $updateQuery)) {
                // Commit the transaction
                mysqli_commit($conn);
                $response = ['status' => 'success', 'message' => 'Locked cartela number updated successfully.'];
            } else {
                // Set response message if update fails
                $response['message'] = 'Error updating locked cartela number: ' . mysqli_error($conn);
                mysqli_rollback($conn);
            }
        }
    } else {
        $response['message'] = 'No game found for the given round number and cashier ID.';
        mysqli_rollback($conn);
    }

    // Output the JSON response
    header('Content-Type: application/json');
    echo json_encode($response);
    exit;
}

//==========================checkCardLockedStatus  ===================================
if (isset($_POST['checkCardLockedStatus']) && isset($_POST['round_num']) && isset($_POST['cashier_id'])) {
    // Sanitize input
    $cartela_number = $_POST['checkCardLockedStatus'];
    $cashier_id     = $_POST['cashier_id'];
    $game_round     = $_POST['round_num'];

    // Initialize response
    $response = ['status' => 'error', 'message' => 'Cartela number not found.'];

    // Query to check if the cartela number is locked
    $selectQuery = "SELECT `locked_cartela_number` FROM `game` WHERE `round_number` = '$game_round' AND `cashier_id` = '$cashier_id'";
    $result      = mysqli_query($conn, $selectQuery);

    if ($result && mysqli_num_rows($result) > 0) {
        $row                            = mysqli_fetch_assoc($result);
        $existing_locked_cartela_number = $row['locked_cartela_number'];

        // Check if the existing_locked_cartela_number is null or empty
        if (! empty($existing_locked_cartela_number)) {
            // Check if the cartela_number is in the locked list
            $locked_cartelas = explode(',', $existing_locked_cartela_number);
            if (in_array($cartela_number, $locked_cartelas)) {
                $response = ['status' => 'locked', 'message' => 'Cartela number is locked.'];
            } else {
                $response = ['status' => 'notlocked', 'message' => 'Cartela number is not locked.'];
            }
        } else {
            // If locked_cartela_number is empty, treat it as not locked
            $response = ['status' => 'notlocked', 'message' => 'Cartela number is not locked.'];
        }
    } else {
        // No records found
        $response = ['status' => 'notlocked', 'message' => 'Cartela number is not locked.'];
    }

    // Output the JSON response
    print(json_encode($response));
    exit;
}

//   ========================== get bonus data  ==================================================================
if (isset($_POST['get_bonus_data'])) {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    // already the bonus amount is set inside bonus table with calculation is made with default partners bonus_percent
    // what we do here is get partners,  min_bonus, max_bonus, fixed_bonus_amount and bonus_status then fixed_bonus_amount
    // then based on these data the saved bonus amount will be updated
    /*
                    bonus_status
                        0  default
                        1, for fixed amount gifts
                        2. gift is locked
                    1889007835

            */

    // Initialize response array
    $response   = [];
    $cashier_id = $_SESSION['cashier_id'];

    //==================================== 1 ===============================
    // Step 1: Check if a bonus has already been awarded for today
    $transactionQuery = "
				SELECT SUM(bonus) as total_bonus
				FROM transaction
				WHERE cashier_id = ?
				AND DATE(date) = CURDATE()
			";
    $stmt = $conn->prepare($transactionQuery);

    if (false === $stmt) {
        // Error in preparing statement
        $response['error'] = "Error in query: " . $conn->error;
    } else {
        // Bind cashier_id to the prepared statement
        $stmt->bind_param('s', $cashier_id);

        // Execute the statement
        $stmt->execute();

        // Get result
        $result = $stmt->get_result();

        // Fetch the total bonus for today
        $transactionRow = $result->fetch_assoc();
        $total_bonus    = $transactionRow['total_bonus'] ? $transactionRow['total_bonus'] : 0;

        //==================================== 2 ===============================
        // Step 2: If no bonus awarded yet (total_bonus is 0), check game_bonus
        if ($total_bonus == 0) {

            //==================================== 3 ===============================
            // Step 3: select bonus status and related thing from partner
            $sql_1 = "SELECT
								c.cashier_bonus_status,
								c.cashier_fixed_bonus_amount,
								p.partner_id,
								p.bonus_percent,
								p.min_bonus,
								p.max_bonus,
								p.min_player,
								p.bonus_status,
								p.fixed_bonus_amount
							FROM
								partner p
							JOIN
								cashier c
							ON
								p.partner_id = c.partner_id
							WHERE
								c.cashier_id = ? ;";

            // Prepare the statement
            $stmt_1 = $conn->prepare($sql_1);

            // Bind the cashier_id parameter
            $stmt_1->bind_param("s", $cashier_id);

            // Execute the query
            $stmt_1->execute();

            // Fetch the result
            $result_1 = $stmt_1->get_result();
            $row_1    = $result_1->fetch_assoc();

            if ($row_1) {
                // echo "Partner ID: " . $row_1["partner_id"] . "<br>";
                // Assign values to variables
                if ($row_1["cashier_bonus_status"] > 0) {

                    $min_bonus  = $row_1["min_bonus"];  //from partner table
                    $max_bonus  = $row_1["max_bonus"];  //from partner table
                    $min_player = $row_1["min_player"]; //from partner table

                    $bonus_status       = $row_1["cashier_bonus_status"];
                    $fixed_bonus_amount = $row_1["cashier_fixed_bonus_amount"];

                } else {
                    $min_bonus          = $row_1["min_bonus"];
                    $max_bonus          = $row_1["max_bonus"];
                    $min_player         = $row_1["min_player"];
                    $bonus_status       = $row_1["bonus_status"];
                    $fixed_bonus_amount = $row_1["fixed_bonus_amount"];
                }

                //defoult or fixed amount
                if ($bonus_status == '0' || $bonus_status == '1') {
                    // Query to get valid bonuses for the cashier where the current time falls within the bonus time window
                    $bonusQuery = " SELECT bonus_amount
														FROM game_bonus
													WHERE cashier_id = ?
														AND NOW() BETWEEN bonus_start_time AND bonus_end_time
													";
                    $stmt_2 = $conn->prepare($bonusQuery);

                    if (false === $stmt_2) {
                        $response['error'] = "Error in query: " . $conn->error;
                    } else {
                        // Bind cashier_id to the prepared statement
                        $stmt_2->bind_param('s', $cashier_id);

                        // Execute the statement
                        $stmt_2->execute();

                        // Get result
                        $result_2 = $stmt_2->get_result();

                        if ($result_2->num_rows > 0) {
                            // Fetch the bonus amount
                            $bonusRow     = $result_2->fetch_assoc();
                            $bonus_amount = $bonusRow['bonus_amount'];

                            //set bonus based on partner statuse data
                            if ($bonus_status == "1") {
                                $bonus_amount = $fixed_bonus_amount;
                            } elseif ($bonus_amount > $max_bonus) {
                                $bonus_amount = $max_bonus;
                            } elseif ($bonus_amount < $min_bonus) {
                                $bonus_amount = $min_bonus;
                            }

                            // Set success response
                            $response['status']       = "success";
                            $response['bonus_amount'] = $bonus_amount;
                            $response['message']      = "Bonus of $bonus_amount awarded to cashier $cashier_id.";
                        } else {
                            // No valid bonuses found
                            $response['status']       = "success";
                            $response['message']      = "No valid bonuses found for cashier $cashier_id.";
                            $response['bonus_amount'] = 0;
                        }
                    }
                } else { //locked means no bonus
                             // No valid bonuses found
                    $response['status']       = "success";
                    $response['message']      = "No valid bonuses found for cashier $cashier_id.";
                    $response['bonus_amount'] = 0;
                }

            } else {
                // No valid bonuses found
                $response['status']       = "success";
                $response['message']      = "No valid bonuses found for cashier $cashier_id.";
                $response['bonus_amount'] = 0;
            }

            // // Query to get valid bonuses for the cashier where the current time falls within the bonus time window
            // $bonusQuery = "
            // 	SELECT bonus_amount
            // 	FROM game_bonus
            // 	WHERE cashier_id = ?
            // 	AND NOW() BETWEEN bonus_start_time AND bonus_end_time
            // ";
            // $stmt = $conn->prepare($bonusQuery);

            // if (false === $stmt) {
            // 	// Error in preparing statement
            // 	$response['error'] = "Error in query: " . $conn->error;
            // } else {
            // 	// Bind cashier_id to the prepared statement
            // 	$stmt->bind_param('i', $cashier_id);

            // 	// Execute the statement
            // 	$stmt->execute();

            // 	// Get result
            // 	$result = $stmt->get_result();

            // 	if ($result->num_rows > 0) {
            // 		// Fetch the bonus amount
            // 		$bonusRow = $result->fetch_assoc();
            // 		$bonus_amount = $bonusRow['bonus_amount'];

            // 		// Set success response
            // 		$response['status'] = "success";
            // 		$response['bonus_amount'] = $bonus_amount;
            // 		$response['message'] = "Bonus of $bonus_amount awarded to cashier $cashier_id.";
            // 	} else {
            // 		// No valid bonuses found
            // 		$response['status'] = "success";
            // 		$response['message'] = "No valid bonuses found for cashier $cashier_id.";
            // 		$response['bonus_amount'] = 0;
            // 	}
            // }
        } else {
            // If a bonus has already been awarded today, return the total_bonus
            $response['status']       = "success";
            $response['bonus_amount'] = 0;
            $response['message']      = "Cashier $cashier_id has already received bonus";
        }

        // Free result set
        $result->free();
    }

    // Output the JSON response
    header('Content-Type: application/json');
    print(json_encode($response));
    exit;
}

//==========================create new card===================================
// if (isset($_POST['cardNumber']))
// {
// 	// Extract card number, partner_id, and all the input values
// 	$cartelaNumber = $_POST['cardNumber'];
// 	$inputs = [];
// 	$response = [];
// 	$cashier_id ="user1";

//     try
// 	{
//         // Collect BINGO card values into a 2D array for easier processing
//         // for ($row = 0; $row < 5; $row++) {
//         //     for ($col = 0; $col < 5; $col++) {
//         //         // Store each input into the $inputs array
//         //         $inputs[$row][$col] = $_POST["input_{$row}_{$col}"];
//         //     }
//         // }
// 		// Collect BINGO card values into a 2D array for easier processing
// 		for ($row = 0; $row < 5; $row++) {
// 			for ($col = 0; $col < 5; $col++) {
// 				// Store each input into the $inputs array
// 				$inputs[$row][$col] = $_POST["input_{$row}_{$col}"];
// 			}
// 		}

//         // Prepare the SQL query to insert or update the cartela
//         $stmt = $conn->prepare("
//             INSERT INTO cartela (cartela_number, b, i, n, g, o, partner_id)
//             VALUES (?, ?, ?, ?, ?, ?, ?)
//             ON DUPLICATE KEY UPDATE
//             b = VALUES(b), i = VALUES(i), n = VALUES(n), g = VALUES(g), o = VALUES(o)
//         ");

//         // Iterate through each row and bind parameters
//         foreach ($inputs as $rowIndex => $rowValues)
// 		{
//             $b = $rowValues[0];
//             $i = $rowValues[1];
//             $n = $rowValues[2];
//             $g = $rowValues[3];
//             $o = $rowValues[4];

//             // Bind the values to the query
//             $stmt->bind_param("issssss", $cartelaNumber, $b, $i, $n, $g, $o, $cashier_id);

//             // Execute the query
//             if (!$stmt->execute()) {
//                 throw new Exception("Error executing query: " . $stmt->error);
//             }
//         }

//         // Return a success response
//         $response = ['status' => 'success', 'message' => $inputs];

//     } catch (Exception $e) {
//         // Log the error and return an error response
//         $response = ['status' => 'error', 'message' => $e->getMessage()];
//     }

//     // Output the JSON response
//     print(json_encode($response));
//     exit;
// }s
if (isset($_POST['cardNumber'])) {
    // Extract card number, partner_id, and all the input values
    $cartelaNumber = $_POST['cardNumber'];
    $inputs        = [];
    $response      = [];
    $cashier_id    = "user1";

    // try {
    //     // Collect BINGO card values into a 2D array for easier processing
    //     for ($row = 0; $row < 5; $row++) {
    //         for ($col = 0; $col < 5; $col++) {
    //             $inputs[$row][$col] = $_POST["input_{$row}_{$col}"];
    //         }
    //     }

    //     // Combine values for each column
    //     $b = implode(",", array_column($inputs, 0)); // First column
    //     $i = implode(",", array_column($inputs, 1)); // Second column
    //     $n = implode(",", array_column($inputs, 2)); // Third column
    //     $g = implode(",", array_column($inputs, 3)); // Fourth column
    //     $o = implode(",", array_column($inputs, 4)); // Fifth column

    //     // Prepare the SQL query to insert the combined values
    //     $stmt = $conn->prepare("
    //         INSERT INTO cartela (cartela_number, b, i, n, g, o, partner_id)
    //         VALUES (?, ?, ?, ?, ?, ?, ?)
    //         ON DUPLICATE KEY UPDATE
    //         b = VALUES(b), i = VALUES(i), n = VALUES(n), g = VALUES(g), o = VALUES(o)
    //     ");

    //     // Bind the combined values to the query
    //     $stmt->bind_param("issssss", $cartelaNumber, $b, $i, $n, $g, $o, $cashier_id);

    //     // Execute the query
    //     if (!$stmt->execute()) {
    //         throw new Exception("Error executing query: " . $stmt->error);
    //     }

    //     // Return a success response
    //     $response = ['statuse' => 'success', 'message' => 'Data saved/updated successfully.'];

    // } catch (Exception $e) {
    //     // Log the error and return an error response
    //     $response = ['statuse' => 'error', 'message' => $e->getMessage()];
    // }

    $response = ['statuse' => 'error', 'message' => "Temporarlly its disabled!"];
    // Output the JSON response
    echo json_encode($response);
    exit;
}

// // Check for winner
// if (isset($_POST['chack_card']) && isset($_POST['card_no']) && isset($_POST['round']) && isset($_POST['cashier_id']))
// {
// 	$response = [];

// 	$cartela_number = $_POST['card_no'];
// 	$round_number = $_POST['round'];
// 	$cashier_id = $_POST['cashier_id'];

// 	$query = "SELECT * FROM `game`
// 			  WHERE `round_number` = ?
// 			  AND `cashier_id` = ?
// 			  AND FIND_IN_SET(?, `cartela_number`) > 0
// 			  AND FIND_IN_SET(?, `result`) > 0";

// 	$stmt = $conn->prepare($query);

// 	if (false === $stmt) {
// 		$response['error'] = "Error in query: " . $conn->error;
// 	} else {
// 		$stmt->bind_param('isss', $round_number, $cashier_id, $cartela_number, $cartela_number);

// 		if (!$stmt->execute()) {
// 			$response['error'] = "Execution error: " . $stmt->error;
// 		} else {
// 			$result = $stmt->get_result();

// 			if ($result->num_rows > 0) {
// 				while ($row = $result->fetch_assoc()) {
// 					$response[] = $row;
// 				}
// 				$response['status'] = "success";
// 			} else {
// 				$response['message'] = "No data found.";
// 				$response['status'] = "success";
// 			}

// 			$result->free();
// 		}
// 		$stmt->close();
// 	}

// 	header('Content-Type: application/json');
// 	echo json_encode($response);
// 	exit;
// }

if (isset($_POST['cashier_id']) && isset($_POST['get_onload_selected_cartela_data'])) {
    // Initialize response array
    $response     = [];
    $cashier_id   = $_POST['cashier_id'];
    $round_number = $_POST['get_onload_selected_cartela_data'];

    // Prepare the SQL query to fetch all cartela_numbers for the given round
    $query = "SELECT `cartela_number` FROM `game` WHERE `cashier_id` = ? AND `round_number` = ?";

    // Prepare the statement
    $stmt = $conn->prepare($query);

    if ($stmt === false) {
        // Error in preparing the statement
        $response['status']  = 'error';
        $response['message'] = 'Error preparing the query: ' . $conn->error;
    } else {
                                                             // Bind the parameters
        $stmt->bind_param("ss", $cashier_id, $round_number); // Assuming cashier_id and round_number are strings

        // Execute the statement
        if ($stmt->execute()) {
            // Get the result
            $result = $stmt->get_result();

            if ($result->num_rows > 0) {
                // Loop through all the rows returned
                while ($row = $result->fetch_assoc()) {
                    // Split the comma-separated string into an array of numbers
                    $numbers = explode(',', $row['cartela_number']);
                                                       // Store the numbers in the response
                    $response['numbers'][] = $numbers; // Add the numbers array for this card
                }
                $response['status'] = "success"; // Set success status
            } else {
                                                  // If no cards found for this round
                $response['status']  = "success"; // Still success, but no data
                $response['message'] = "No data found.";
            }

            // Free the result
            $result->free();
        } else {
            // Error in executing the statement
            $response['status']  = 'error';
            $response['message'] = 'Error executing the query: ' . $stmt->error;
        }
    }

    // Output the JSON response
    header('Content-Type: application/json');
    echo json_encode($response);
    exit;
}

if (isset($_POST['get_last_transaction_time']) && $_POST['get_last_transaction_time'] === "true") {
    // Prepare the response array
    $response = [];

    // Query to get the last transaction date
    $transactionQuery  = "SELECT `date` FROM `transaction` ORDER BY `date` DESC LIMIT 1";
    $transactionResult = $conn->query($transactionQuery);

    // Query to check if there is any uncleared data in the game table
    $gameQuery = "SELECT COUNT(*) AS unclearedGames FROM `game` WHERE DATE(`date`) < CURDATE()";

    $gameResult = $conn->query($gameQuery);

    if ($transactionResult && $gameResult) {
        // Check last transaction date
        if ($transactionResult->num_rows > 0) {
            $transactionRow                  = $transactionResult->fetch_assoc();
            $response['success']             = true;
            $response['lastTransactionTime'] = $transactionRow['date'];
        } else {
            $response['success']             = false;
            $response['lastTransactionTime'] = null;
            $response['message']             = "No transactions found.";
        }

        // Check for uncleared games
        $gameRow                    = $gameResult->fetch_assoc();
        $response['unclearedGames'] = (int) $gameRow['unclearedGames'];

        if ($response['unclearedGames'] > 0) {
            $response['gameMessage'] = "There are uncleared games in the game table.";
        } else {
            $response['gameMessage'] = "No uncleared games found.";
        }
    } else {
        // Error in one or both queries
        $response['success'] = false;
        $response['message'] = "Error executing queries: " . $conn->error;
    }

    // Return the JSON response
    echo json_encode($response);

    // Close the connection
    $conn->close();
    exit;
}

if (isset($_POST['delete_game_history'])) {

    $response = []; // Initialize the response array

    // Fetch the date of the last transaction
    $query  = "SELECT `date` FROM `transaction` ORDER BY `date` DESC LIMIT 1";
    $result = $conn->query($query);

    if ($result && $result->num_rows > 0) {
        // Get the last transaction date
        $row                 = $result->fetch_assoc();
        $lastTransactionDate = $row['date'];

        // Optional: Log the last transaction date for debugging
        // error_log("Last transaction date: " . $lastTransactionDate);

        // Proceed to delete data
        $deleteGameQuery  = "DELETE FROM `game`";
        $deleteBonusQuery = "DELETE FROM `game_bonus`";

        if ($conn->query($deleteGameQuery) === true && $conn->query($deleteBonusQuery) === true) {
            $cashierId              = $_SESSION['cashier_id'] ?? 'System'; // Ensure cashier ID is available
            $insertTransactionQuery = "INSERT INTO `transaction` (`cashier_id`)  VALUES ('$cashierId')";

            if ($conn->query($insertTransactionQuery) === true) {
                $response['status']  = 'success';
                $response['message'] = 'Data have been cleared successfully and recorded.';
            } else {
                $response['status']  = 'error';
                $response['message'] = 'Error inserting transaction log: ' . $conn->error;
            }
        } else {
            $response['status']  = 'error';
            $response['message'] = 'Error deleting data history: ' . $conn->error;
        }
    } else {
        // Handle the case where no transactions exist
        $response['status']  = 'error';
        $response['message'] = 'No transactions found to determine the last transaction date.';
    }

    // Send the JSON response
    echo json_encode($response);

    // Close the database connection
    $conn->close();
    exit;
}

/// update_settings_cashier_id


if (isset($_POST['action']) && $_POST['action'] == 'update_settings_cashier_id') 
{
    $cashier_id = $_POST['cashier_id'];
    $settings = $_POST['settings'];

    $settings_data = json_decode($settings, true);
    //bonus
    $set_bonus        = $settings_data['bonus']['status'] ?? 'off'; // Default 'off' if not set
    $bonus_amount = $settings_data['bonus']['amount'] ?? 20;    // Default 20 if not set
    $bonus_per_day = $settings_data['bonus']['per_day'] ?? 1;   // Default 1 if not set
    // 2. System Settings
    $check_result = $settings_data['system']['check_result'] ?? 'auto';
    if (!isset($settings_data['system']) || !is_array($settings_data['system'])) {
        $settings_data['system'] = [];
    }
    $settings_data['system']['color_mode'] = 'three';
    $settings = json_encode($settings_data);
    $color_mode = 'three';
    $profit = $settings_data['system']['profit'] ?? 10;
    $good_bingo_sound = $settings_data['system']['good_bingo_sound'] ?? 'default';
    // 3. Toggle Settings
    $will_start_sound = $settings_data['toggles']['will_start'] ?? true;
    $started_sound = $settings_data['toggles']['started'] ?? true;
    $stopped_sound = $settings_data['toggles']['stopped'] ?? true;
    $show_card_count = $settings_data['toggles']['show_card_count'] ?? true;

    $response = ["status" => "error", "message" => "An error occurred"];

    if (! empty($cashier_id)) {
        $query = "UPDATE `cashier`
							SET `new_bonus_status` = ?,
								`auto_check_result` = ?,
								`color` = ?,
								`good_bingo_sound` = ?,
								`cashier_profit` = ?,
                                `settings_json`=?
							WHERE `cashier_id` = ?";
                            

        if ($stmt = $conn->prepare($query)) {
            $stmt->bind_param("sssssss", $set_bonus, $check_result, $color_mode, $good_bingo_sound, $profit, $settings, $cashier_id);
            if ($stmt->execute()) {
                
                
                        $description = "Cashier settings updated: " .
                            "Profit ={$profit}%, " .
                            "Bonus is =" . ($set_bonus === 'on' ? "Active" : "Inactive") . ", " . 
                            "Bonus Value={$bonus_amount}, " .
                            "Daily Bonus Cap={$bonus_per_day}";


                        $log_query = "INSERT INTO `activity_logs` (`user_id`, `action`, `description`) VALUES (?, ?, ?)";
                        if ($log_stmt = $conn->prepare($log_query)) {
                            $action = 'UPDATE';
                            $log_stmt->bind_param("sss", $cashier_id, $action, $description);
                            $log_stmt->execute();
                        }
                        
                        
                $response["status"]  = "success";
                $response["message"] = "Settings updated successfully" . $good_bingo_sound;
            } else {
                $response["message"] = "Failed to update settings";
            }
            $stmt->close();
        } else {
            $response["message"] = "Database query error";
        }
    } else {
        $response["message"] = "Invalid cashier ID";
    }

    // Send the JSON response
    echo json_encode($response);

    // Close the database connection
    $conn->close();
    exit;
}

// Check if required POST parameters are set
// Check if required POST parameters are set
if (isset($_POST['claim_new_bonus_round']) && isset($_POST['cashier_id'])) {
    $game_id    = intval($_POST['claim_new_bonus_round']);
    $cashier_id = $_POST['cashier_id'];
    $new_bonus_amount = $_POST['new_bonus_amount'];
    $response   = ["status" => "error", "message" => "Invalid request"];

    // Validate inputs
    if ($game_id <= 0 || empty($cashier_id)) {
        $response = ["status" => "error", "message" => "Invalid input"];
    } else {
        // Check if the bonus is open (status = 0)
        $query = "SELECT id FROM new_bonus WHERE game_id = ? AND cashier_id = ? AND status = 0";
        if ($stmt = $conn->prepare($query)) {
            $stmt->bind_param("is", $game_id, $cashier_id);
            $stmt->execute();
            $stmt->store_result();

            if ($stmt->num_rows > 0) {
                // Check if there is an existing transaction for the same game round and cashier
                $query = "SELECT id FROM `transaction` WHERE `game_round` = ? AND `cashier_id` = ? AND DATE(date) = CURDATE()";
                if ($stmt_transaction = $conn->prepare($query)) {
                    $stmt_transaction->bind_param("is", $game_id, $cashier_id);
                    $stmt_transaction->execute();
                    $stmt_transaction->store_result();

                    if ($stmt_transaction->num_rows > 0) {
                        // Update new_bonus status to 1 (claimed)
                        $query = "UPDATE new_bonus SET status = 1 WHERE game_id = ? AND cashier_id = ?";
                        if ($stmt_update = $conn->prepare($query)) {
                            $stmt_update->bind_param("is", $game_id, $cashier_id);
                            $stmt_update->execute();
                            $stmt_update->close();
                            
                            // Fetch partner and cashier data together
                            $query = "
                                SELECT 
                                    p.partner_id, 
                                    p.partner_balance, 
                                    p.partner_full_name,
                                    c.cashier_package 
                                FROM partner p 
                                JOIN cashier c ON c.partner_id = p.partner_id 
                                WHERE c.cashier_id = '$cashier_id'
                            ";
                            $result = mysqli_query($conn, $query);
                            if (mysqli_num_rows($result) > 0) 
                            {
                                $data = mysqli_fetch_assoc($result);
                            
                                $partner_id         = $data['partner_id'];
                                $partner_full_name  = $data['partner_full_name'];
                                $cashier_package    = $data["cashier_package"];
                                $cashier_package = openssl_decrypt(base64_decode($cashier_package), 'AES-256-CBC', ENCRYPTION_KEY, 0, ENCRYPTION_IV);
                                
                                // Update cashier package
                                $newCashierPackage  = $cashier_package + ($new_bonus_amount * 0.10);
                                $newCashierPackage = base64_encode(openssl_encrypt($newCashierPackage, 'AES-256-CBC', ENCRYPTION_KEY, 0, ENCRYPTION_IV));

                                $updateCashier = "UPDATE cashier SET cashier_package = '$newCashierPackage' WHERE cashier_id = '$cashier_id'";
                                if (!mysqli_query($conn, $updateCashier)) {
                                    throw new Exception('Error updating cashier package: ' . mysqli_error($conn));
                                }
                                
                            } else {
                                throw new Exception("No partner found for cashier_id = $cashier_id");
                            }
                            



                            // Update transaction with 300 bonus
                            $query = "UPDATE `transaction` SET `bonus` = '$new_bonus_amount' WHERE `game_round` = ? AND `cashier_id` = ? AND DATE(date) = CURDATE()";
                            if ($stmt_bonus = $conn->prepare($query)) {
                                $stmt_bonus->bind_param("is", $game_id, $cashier_id);
                                if ($stmt_bonus->execute()) {
                                    $response = ["status" => "success", "message" => "Bonus claimed successfully"];
                                } else {
                                    $response = ["status" => "error", "message" => "Failed to update transaction"];
                                }
                                $stmt_bonus->close();
                            }
                        }
                    } else {
                        $response = ["status" => "error", "message" => "No transactions found"];
                    }
                    $stmt_transaction->close();
                }
            } else {
                $response = ["status" => "error", "message" => "Bonus not available or already claimed"];
            }
            $stmt->close();
        } else {
            $response = ["status" => "error", "message" => "Database error"];
        }
    }

    // Close the database connection
    $conn->close();

    // Send the JSON response at the end
    echo json_encode($response);
    exit;
}

// SAVE CHECKED WINNING NUMBER
if (isset($_POST['save_checked_number'])) 
{
    $response = ['success' => false, 'message' => null];
    $existingNumbers = [];

    try {
        // Get the posted data
        $checked_number = $_POST['checked_card_no']; // <-- this is the winning number
        $game_round = $_POST['checked_round'];
        $cashier_id = $_POST['checked_cashier_id'];

        // Fetch existing checked_number only if the date is CURDATE()
        $stmt = $conn->prepare("SELECT checked_number FROM transaction WHERE game_round = ? AND cashier_id = ? AND DATE(`date`) = CURDATE()");
        $stmt->bind_param("ss", $game_round, $cashier_id); 
        $stmt->execute();
        $stmt->bind_result($existingCheckedNumber);
        $stmt->fetch();
        $stmt->close();
        // Convert existing numbers to array
        if ($existingCheckedNumber != null) {
            $existingNumbers = array_filter(array_map('trim', explode(',', $existingCheckedNumber)));
        }

        // Add new number if not already there
        if (!in_array($checked_number, $existingNumbers)) {
            $existingNumbers[] = $checked_number;
        }

        // Join back to string
        $updatedCheckedNumbers = implode(',', array_unique($existingNumbers));

        // Now update the transaction table
        $updateStmt = $conn->prepare("UPDATE `transaction` SET `checked_number`= ? WHERE `game_round` = ? AND `cashier_id` = ? AND DATE(`date`) = CURDATE()");
        $updateStmt->bind_param("sss", $updatedCheckedNumbers, $game_round, $cashier_id);

        
        if ($updateStmt->execute()) {
            $response['success'] = true;
            $response['message'] = 'Checked number updated successfully.';
        } else {
            $response['message'] = 'Failed to update checked number.';
        }
        

        $updateStmt->close();

    } catch (Exception $e) {
        $response['message'] = $e->getMessage();
    }

    header('Content-Type: application/json');
    echo json_encode($response);
    exit;
}