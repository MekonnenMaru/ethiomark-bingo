<?php
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    
    if (!isset($_SESSION['loggedin'])   || $_SESSION['role']!="cashier") {
        header("Location: ../config/logout.php");
    }
    include_once '../config/Database.php';

    $db = Database::getInstance();
    $conn = $db->getConnection(); // Get the connection object

    $cashier_id = isset($_SESSION['cashier_id']) ? $_SESSION['cashier_id'] : '';
    $bonus_check_date = date('Y-m-d');
    if ($cashier_id && (($_SESSION['create_bonus_date'] ?? '') !== $bonus_check_date)) {
        createBonus($cashier_id);
        $_SESSION['create_bonus_date'] = $bonus_check_date;
    }

function createBonus($cashier_id) 
{
    global $conn;

    // Define the shift start and end times
    $shift_start = strtotime("09:00"); // 9 AM
    $shift_end = strtotime("18:00");   // 5 PM

    // Get the current time
    $current_time = time();

    // Check for existing bonus
    $bonusCheckQuery = "SELECT id, bonus_start_time, bonus_end_time FROM game_bonus 
                        WHERE cashier_id = '$cashier_id' 
                        AND DATE(created_at) = CURDATE() 
                        ORDER BY created_at DESC LIMIT 1"; // Get the latest bonus for today
    $bonusCheckResult = mysqli_query($conn, $bonusCheckQuery);
    $bonusRecord = mysqli_fetch_assoc($bonusCheckResult);

    // If there is an existing bonus
    if ($bonusRecord) 
    {
        $bonus_start_time = strtotime($bonusRecord['bonus_start_time']);
        $bonus_end_time = strtotime($bonusRecord['bonus_end_time']);

        // Check if both times are less than the current time
        if ($bonus_start_time < $current_time && $bonus_end_time < $current_time) 
        {
            // Calculate total income for today for the cashier
            $incomeQuery = "
            SELECT 
                SUM(transaction.income) AS total_income, 
                partner.bonus_percent 
            FROM 
                transaction 
            JOIN 
                cashier ON transaction.cashier_id = cashier.cashier_id 
            JOIN 
                partner ON cashier.partner_id = partner.partner_id 
            WHERE 
                transaction.cashier_id = '$cashier_id' 
                AND DATE(transaction.date) = CURDATE();
            ";

            $incomeResult = mysqli_query($conn, $incomeQuery);

            if (!$incomeResult) 
            {
                // echo "Error: " . mysqli_error($conn) . "\n";
                return null;
            }

            $totalIncomeRow = mysqli_fetch_assoc($incomeResult);
            $total_income = $totalIncomeRow['total_income'] ? $totalIncomeRow['total_income'] : 0; // Handle null

            // Get the bonus percentage from the partner
            $bonus_percent = $totalIncomeRow['bonus_percent'] ? $totalIncomeRow['bonus_percent'] : 0;

            // Calculate the bonus amount based on the partner's bonus percent
            $bonus_amount = $total_income * ($bonus_percent / 100); // Use percentage for calculation




            // Generate new bonus times
            $bonus_start_time = rand(max($current_time + 1, $shift_start), $shift_end - 20 * 60);
            $bonus_end_time = $bonus_start_time + 20 * 60; // Add 20 minutes

            // Update the existing bonus
            $updateBonusQuery = "UPDATE game_bonus SET bonus_amount='$bonus_amount',bonus_start_time = '" . date('Y-m-d H:i:s', $bonus_start_time) . "', 
                                 bonus_end_time = '" . date('Y-m-d H:i:s', $bonus_end_time) . "', 
                                 created_at = NOW() 
                                 WHERE id = '" . $bonusRecord['id'] . "'";

            if (mysqli_query($conn, $updateBonusQuery)) {
                // echo "Bonus updated for cashier $cashier_id to new times from " . date('Y-m-d H:i:s', $bonus_start_time) . " to " . date('Y-m-d H:i:s', $bonus_end_time) . ".\n";
                return $bonusRecord['id']; // Return the updated bonus ID
            } else {
                // echo "Error updating bonus: " . mysqli_error($conn) . "\n";
                return null;
            }
        }
        else
        {

            //we must update bonus amount based on currunt cashier balance
            // Calculate total income for today for the cashier
            $incomeQuery = "
            SELECT 
                SUM(transaction.income) AS total_income, 
                partner.bonus_percent 
            FROM 
                transaction 
            JOIN 
                cashier ON transaction.cashier_id = cashier.cashier_id 
            JOIN 
                partner ON cashier.partner_id = partner.partner_id 
            WHERE 
                transaction.cashier_id = '$cashier_id' 
                AND DATE(transaction.date) = CURDATE();
            ";

            $incomeResult = mysqli_query($conn, $incomeQuery);

            if (!$incomeResult) 
            {
                // echo "Error: " . mysqli_error($conn) . "\n";
                return null;
            }

            $totalIncomeRow = mysqli_fetch_assoc($incomeResult);
            $total_income = $totalIncomeRow['total_income'] ? $totalIncomeRow['total_income'] : 0; // Handle null

            // Get the bonus percentage from the partner
            $bonus_percent = $totalIncomeRow['bonus_percent'] ? $totalIncomeRow['bonus_percent'] : 0;

            // Calculate the bonus amount based on the partner's bonus percent
            $bonus_amount = $total_income * ($bonus_percent / 100); // Use percentage for calculation




            // Generate new bonus times
            $bonus_start_time = rand(max($current_time + 1, $shift_start), $shift_end - 20 * 60);
            $bonus_end_time = $bonus_start_time + 20 * 60; // Add 20 minutes

            // Update the existing bonus
            $updateBonusQuery = "UPDATE game_bonus SET bonus_amount='$bonus_amount'
                                 WHERE id = '" . $bonusRecord['id'] . "'";

            if (mysqli_query($conn, $updateBonusQuery)) {
                // echo "Bonus updated for cashier $cashier_id to new times from " . date('Y-m-d H:i:s', $bonus_start_time) . " to " . date('Y-m-d H:i:s', $bonus_end_time) . ".\n";
                return $bonusRecord['id']; // Return the updated bonus ID
            } else {
                // echo "Error updating bonus: " . mysqli_error($conn) . "\n";
                return null;
            }


            // // echo "Bonus is still active for cashier $cashier_id.\n";
            // return $bonusRecord['id']; // Return the existing bonus ID
        }
    }
    else 
    {
        if ($current_time > $shift_end) {
            // Add extra minutes to shift_end to allow for bonus creation
            $shift_end += 30 * 60; // Add 30 minutes (in seconds)
        }
        
        // Generate new times for the bonus
        $bonus_start_time = rand(max($current_time + 1, $shift_start), $shift_end - 20 * 60);
        $bonus_end_time = $bonus_start_time + 20 * 60; // Add 20 minutes
        
        // Calculate total income for today for the cashier
            $incomeQuery = "
            SELECT 
                SUM(transaction.income) AS total_income, 
                partner.bonus_percent 
            FROM 
                transaction 
            JOIN 
                cashier ON transaction.cashier_id = cashier.cashier_id 
            JOIN 
                partner ON cashier.partner_id = partner.partner_id 
            WHERE 
                transaction.cashier_id = '$cashier_id' 
                AND DATE(transaction.date) = CURDATE();
            ";

            $incomeResult = mysqli_query($conn, $incomeQuery);

            if (!$incomeResult) {
            // echo "Error: " . mysqli_error($conn) . "\n";
            return null;
            }

            $totalIncomeRow = mysqli_fetch_assoc($incomeResult);
            $total_income = $totalIncomeRow['total_income'] ? $totalIncomeRow['total_income'] : 0; // Handle null

            // Get the bonus percentage from the partner
            $bonus_percent = $totalIncomeRow['bonus_percent'] ? $totalIncomeRow['bonus_percent'] : 0;

            // Calculate the bonus amount based on the partner's bonus percent
            $bonus_amount = $total_income * ($bonus_percent / 100); // Use percentage for calculation

            // Insert the bonus into the game_bonus table
            $insertBonusQuery = "
            INSERT INTO game_bonus (cashier_id, bonus_amount, bonus_start_time, bonus_end_time, created_at) 
            VALUES ('$cashier_id', '$bonus_amount', '" . date('Y-m-d H:i:s', $bonus_start_time) . "', 
            '" . date('Y-m-d H:i:s', $bonus_end_time) . "', NOW())
            ";

            if (mysqli_query($conn, $insertBonusQuery)) 
            {
                // echo "Bonus created for cashier $cashier_id from " . date('Y-m-d H:i:s', $bonus_start_time) . " to " . date('Y-m-d H:i:s', $bonus_end_time) . ".\n";
                return mysqli_insert_id($conn); // Return the newly created bonus ID
            } 
            else 
            {
                // echo "Error: " . mysqli_error($conn) . "\n";
                return null;
            }
    }
}

?>
