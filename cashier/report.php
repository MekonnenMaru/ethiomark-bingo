<?php
if (session_status() === PHP_SESSION_NONE) {
	session_start();
}

if (!isset($_SESSION['loggedin'])   || $_SESSION['role']!="cashier") {
	header("Location: ../config/logout.php");
}
// Include your database configuration
include_once '../config/Database.php';
require '../config/Youman.php';


$db = Database::getInstance();
$conn = $db->getConnection(); // Get the connection object

$response = ['status' => 'error', 'message' => ''];
$start_datetime = date("Y-m-d") . " 00:00:00"; // Start of today
$end_datetime = date("Y-m-d") . " 23:59:59";   // End of today

if (isset($_POST['start_date'], $_POST['end_date'])) 
{
    $cashier_id = $_SESSION['cashier_id']; // Get cashier ID from session
    $start_datetime = $_POST['start_date'] . ' 00:00:00'; // Start date
    $end_datetime = $_POST['end_date'] . ' 23:59:59'; // End date

    // Prepare the SQL query
    $query = "
        SELECT 
            p.partner_id, p.partner_full_name, p.partner_phone, 
            p.user_name, p.password AS partner_password, p.is_locked AS partner_locked, 
            p.is_blocked AS partner_blocked, p.percent AS partner_percent, 
            c.cashier_id,c.cashier_package, c.password AS cashier_password, c.is_loggedin, 
            c.loggin_time, c.is_locked AS cashier_locked, c.is_active, 
            c.login_attempts, c.speed_range, c.sound,
            t.id AS transaction_id, t.game_round, t.santim, t.sew, 
            t.income,t.bonus, t.date, t.result, t.checked_number
        FROM partner p
        INNER JOIN cashier c ON p.partner_id = c.partner_id
        LEFT JOIN transaction t ON c.cashier_id = t.cashier_id
        WHERE c.cashier_id = ? AND t.date BETWEEN ? AND ?
    ";

    // Prepare the statement
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        $response['message'] = "Error in query: " . $conn->error;
    } else 
	{
        // Bind parameters and execute
        $stmt->bind_param('sss', $cashier_id, $start_datetime, $end_datetime);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            $response = ['status' => 'success', 'data' => []];

            while ($row = $result->fetch_assoc()) {
                $row['cashier_package'] = decrypt_cashier_package($row['cashier_package']);
                $response['data'][] = $row;
            }
        } else 
		{
            $response['message'] = "No data found for the given date. ";
        }

        // Cleanup
        $stmt->free_result();
        $stmt->close();
    }
}
else
{
    $cashier_id = $_SESSION['cashier_id']; // Get cashier ID from session
    
    // Prepare the SQL query
    $query = "
        SELECT 
            p.partner_id, p.partner_full_name, p.partner_phone, 
            p.user_name, p.password AS partner_password, p.is_locked AS partner_locked, 
            p.is_blocked AS partner_blocked, p.percent AS partner_percent, 
            c.cashier_id,c.cashier_package, c.password AS cashier_password, c.is_loggedin, 
            c.loggin_time, c.is_locked AS cashier_locked, c.is_active,  
            c.login_attempts, c.speed_range, c.sound,
            t.id AS transaction_id, t.game_round, t.santim, t.sew, 
            t.income,t.bonus, t.date, t.result, t.checked_number
        FROM partner p
        INNER JOIN cashier c ON p.partner_id = c.partner_id
        LEFT JOIN transaction t ON c.cashier_id = t.cashier_id
        WHERE c.cashier_id = ? AND t.date BETWEEN CURDATE() AND CURDATE() + INTERVAL 1 DAY - INTERVAL 1 SECOND
    ";

    // Prepare the statement
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        $response['message'] = "Error in query: " . $conn->error;
    } else 
	{
        // Bind parameters and execute
        $stmt->bind_param('s', $cashier_id);
        $stmt->execute();
        $result = $stmt->get_result();

         if ($result->num_rows > 0) {
            $response = ['status' => 'success', 'data' => []];

            while ($row = $result->fetch_assoc()) {
                $row['cashier_package'] = decrypt_cashier_package($row['cashier_package']);
                $response['data'][] = $row;
            }
        } else 
		{
            $response['message'] = "No data found for the given date.";
        }

        // Cleanup
        $stmt->free_result();
        $stmt->close();
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=1280, user-scalable=no">
    <title>Ethiomark</title>
    	
    <link rel="stylesheet" href="../bootstrap/css/style.css">
    <script src="../bootstrap/js/jquery.js"></script>
	<script src="../cashier/pagination.js"></script>
    


	<link rel="stylesheet" type="text/css" href="side-nav.css">
	<link rel="stylesheet" type="text/css" href="container.css">
	<link rel="stylesheet" type="text/css" href="../bootstrap/css/cashier_option_container.css?v=2">

	<style>
		.package-sync-btn {
			background: linear-gradient(135deg, #0a9396, #05535d);
			color: #fff;
			border: none;
			border-radius: 8px;
			padding: 10px 18px;
			font-size: 16px;
			font-weight: 600;
			cursor: pointer;
			box-shadow: 0 4px 14px rgba(5, 83, 93, 0.35);
		}
		.package-sync-btn-attention {
			display: inline-flex;
			align-items: center;
			margin-left: 16px;
			background: linear-gradient(135deg, #ef4444, #991b1b);
			border: 2px solid #fecaca;
			animation: package-btn-blink 1.1s ease-in-out infinite;
		}
		@keyframes package-btn-blink {
			0%, 100% { box-shadow: 0 0 8px rgba(239, 68, 68, 0.6); }
			50% { box-shadow: 0 0 22px rgba(255, 100, 100, 1); }
		}
		.cashier-name-row {
			display: flex;
			align-items: center;
			flex-wrap: wrap;
			gap: 8px 12px;
			margin: 0 0 8px;
		}
		.cashier-name-row p { margin: 0; }
		.package-modal-overlay {
			display: none;
			position: fixed;
			inset: 0;
			background: rgba(0, 0, 0, 0.72);
			z-index: 9000;
			align-items: center;
			justify-content: center;
			padding: 20px;
		}
		.package-modal-overlay.open { display: flex; }
		.package-modal {
			width: min(640px, 96vw);
			background: #0f1419;
			border: 1px solid #1f2a33;
			border-radius: 16px;
			overflow: hidden;
		}
		.package-modal-header {
			display: flex;
			align-items: center;
			justify-content: space-between;
			padding: 18px 22px;
			background: linear-gradient(90deg, #05535d, #0a9396);
			color: #fff;
		}
		.package-modal-header h3 { margin: 0; font-size: 20px; }
		.package-modal-close {
			background: rgba(255,255,255,0.15);
			border: none;
			color: #fff;
			width: 36px;
			height: 36px;
			border-radius: 50%;
			font-size: 22px;
			cursor: pointer;
		}
		.package-modal-body { padding: 24px; color: #d7e2ea; min-height: 220px; }
		.package-loader {
			display: flex;
			flex-direction: column;
			align-items: center;
			justify-content: center;
			gap: 16px;
			min-height: 180px;
		}
		.package-spinner {
			width: 52px;
			height: 52px;
			border: 4px solid rgba(10, 147, 150, 0.25);
			border-top-color: #2dd4bf;
			border-radius: 50%;
			animation: packageSpin 0.9s linear infinite;
		}
		@keyframes packageSpin { to { transform: rotate(360deg); } }
		.package-modal-status {
			display: none;
			align-items: center;
			gap: 16px;
			margin-bottom: 18px;
			padding: 16px 18px;
			border-radius: 12px;
			border: 1px solid transparent;
		}
		.package-modal-status.visible { display: flex; }
		.package-modal-status.kind-success {
			background: rgba(34, 197, 94, 0.12);
			border-color: rgba(74, 222, 128, 0.35);
		}
		.package-modal-status.kind-danger {
			background: rgba(248, 113, 113, 0.12);
			border-color: rgba(248, 113, 113, 0.35);
		}
		.package-modal-status.kind-warning {
			background: rgba(250, 204, 21, 0.12);
			border-color: rgba(250, 204, 21, 0.35);
		}
		.package-modal-status.kind-info {
			background: rgba(96, 165, 250, 0.12);
			border-color: rgba(96, 165, 250, 0.35);
		}
		.package-modal-status-icon {
			flex-shrink: 0;
			width: 52px;
			height: 52px;
			border-radius: 50%;
			display: flex;
			align-items: center;
			justify-content: center;
			font-size: 28px;
			font-weight: 800;
			line-height: 1;
		}
		.kind-success .package-modal-status-icon {
			background: #22c55e;
			color: #052e16;
			box-shadow: 0 0 0 4px rgba(34, 197, 94, 0.25);
		}
		.kind-danger .package-modal-status-icon {
			background: #ef4444;
			color: #fff;
			box-shadow: 0 0 0 4px rgba(239, 68, 68, 0.25);
		}
		.kind-warning .package-modal-status-icon {
			background: #eab308;
			color: #422006;
			box-shadow: 0 0 0 4px rgba(234, 179, 8, 0.25);
		}
		.kind-info .package-modal-status-icon {
			background: #3b82f6;
			color: #fff;
			box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.25);
		}
		.package-modal-status-title {
			font-size: 18px;
			font-weight: 700;
			color: #f1f5f9;
			margin-bottom: 4px;
		}
		.package-modal-status-message {
			font-size: 14px;
			color: #94a3b8;
			line-height: 1.45;
		}
		.package-status-badge { display: none; }
		.package-code-block {
			background: #06080b;
			border: 1px solid #243041;
			border-radius: 12px;
			padding: 18px 20px;
			font-family: Consolas, monospace;
			font-size: 14px;
			color: #7ee787;
			white-space: pre;
			overflow-x: auto;
		}
		.package-modal-message { display: none; }
		.package-modal-footer {
			display: flex;
			justify-content: flex-end;
			gap: 10px;
			padding: 14px 22px 18px;
			border-top: 1px solid #1f2a33;
		}
		.package-modal-btn {
			border: none;
			border-radius: 8px;
			padding: 10px 18px;
			font-size: 14px;
			font-weight: 600;
			cursor: pointer;
		}
		.package-modal-btn-primary { background: #0a9396; color: #fff; }
		.package-modal-btn-secondary { background: #243041; color: #d7e2ea; }
	</style>

</head>
<body>
    <div id="customAlert" class="custom-alert" style="display: block; position: fixed; top: 20px; right: 20px; z-index: 10000;"></div>

	<?php if (! app_usage_is_online()): ?>
	<div id="packageModalOverlay" class="package-modal-overlay">
		<div class="package-modal" role="dialog" aria-modal="true">
			<div class="package-modal-header">
				<h3>ፓኬጅ ለመሙላት — Package Deposit</h3>
				<button type="button" id="packageModalClose" class="package-modal-close">&times;</button>
			</div>
			<div class="package-modal-body">
				<div id="packageModalStatus" class="package-modal-status" role="status" aria-live="polite">
					<div id="packageModalStatusIcon" class="package-modal-status-icon" aria-hidden="true"></div>
					<div>
						<div id="packageModalStatusTitle" class="package-modal-status-title"></div>
						<div id="packageModalStatusMessage" class="package-modal-status-message"></div>
					</div>
				</div>
				<div id="packageModalLoader" class="package-loader">
					<div class="package-spinner"></div>
					<p>Fetching available package from admin server…</p>
				</div>
				<div id="packageModalResult" style="display:none;">
					<span id="packageStatusBadge" class="package-status-badge"></span>
					<p id="packageModalMessage" class="package-modal-message"></p>
					<pre id="packageCodeBlock" class="package-code-block"></pre>
				</div>
			</div>
			<div class="package-modal-footer">
				<button type="button" id="packageModalRefetch" class="package-modal-btn package-modal-btn-primary">Re-fetch</button>
				<button type="button" id="packageModalCloseFooter" class="package-modal-btn package-modal-btn-secondary">Close</button>
			</div>
		</div>
	</div>
	<?php endif; ?>

    <div id="user-content" style="display: none;">
          
<script>
  document.addEventListener('contextmenu', function (e) {
    e.preventDefault();
    showAlert('Hello! You are using Ethiomark Bingo.', "success"); 
  });
</script>

        <?php include_once("side-nav.php"); ?>






				
        <div class="main-content">
            <div id="cashier_option_content" class="cashier_option_container" style="min-width: 1700px;">                
                <!-- Partner Information -->


				<?php
					// Get last transaction (simplified)
					$last = $conn->query("SELECT amount, action, timestamp 
										FROM transaction_logs
										WHERE cashier_id = '{$_SESSION['cashier_id']}' 
										ORDER BY timestamp DESC LIMIT 1")->fetch_assoc();

					$amount = $last ? number_format($last['amount'], 2) : '0.00';
					$action = $last ? (strpos($last['action'], 'deposit') !== false ? 'deposit' : 'withdrawal') : 'none';
					$time = $last ? date('M j, g:i a', strtotime($last['timestamp'])) : 'Never';
					?>

				<div class="cashier-dashboard-connected compact">
					<div class="cashier-dashboard-section cashier-id">
						<span class="cashier-dashboard-label">Cashier ID</span>
						<span class="cashier-dashboard-value"  id = "dashboard_cashier_id"><?php echo  $_SESSION['cashier_id']; ?></span>
					</div>
					<div class="cashier-dashboard-section remaining-package">
						<span class="cashier-dashboard-label">Remaining Package</span>
						<span class="cashier-dashboard-value" id="remaining_balance"><span id="remaining_balance" ></span> Birr</span>
					</div>

					
					<div class="cashier-dashboard-section last-deposit">
						<span class="cashier-dashboard-label">Last Transaction</span>
						<span class="cashier-dashboard-value" id="dashboard_last_deposit">
						<?php 
						if (!empty($last) && isset($last['amount'], $last['action'], $last['timestamp'])) {?>
							<?= $amount ?> ብር  <?= $action ?> at <?= $time ?> 
						<?php } else {
							echo 'No transaction';
						}
						?>
					</span>
					</div>
					
				</div>
				

				
                <div class="cashier_option_info">
					<?php if (! app_usage_is_online()): ?>
					<div class="cashier-name-row">
						<p><strong>Cashier Name:</strong> <span id="cashier_option_cashier_name" class="cashier_option_name"></span></p>
						<button type="button" id="btnSyncPackage" class="package-sync-btn package-sync-btn-attention" title="Fetch and apply package deposit from admin">Package (ፓኬጅ ለመሙላት)</button>
					</div>
					<?php endif; ?>
					
					<form id="report_form" method="POST" action="report.php" class="cashier_option_report_form" style="display: flex; align-items: center; gap: 10px;">
						<div class="mini-box">
							<label for="report_choice" class="cashier_option_label"> &nbsp;&nbsp;</label>
							<select id="report_choice" class="cashier_option_select required cashier_option_date_input date-inputs">
								<option value="today">Today</option>
								<option value="yesterday">Yesterday</option>
								<option value="this_week">This Week</option>
								<option value="last_week">Last Week</option>
								<option value="this_month">This Month</option>
								<option value="last_month" hidden>Last Month</option>
							</select>
						</div>
						
						<div class="mini-box">
							<label for="start_date" class="cashier_option_label">From Date  &nbsp;&nbsp;</label>
							<input type="date" name="start_date" id="start_dates" required class="cashier_option_date_input date-inputs">
						</div>

						<div class="mini-box">
							<label for="end_date" class="cashier_option_label">To Date  &nbsp;&nbsp;</label>
							<input type="date" name="end_date" id="end_dates" required class="cashier_option_date_input date-inputs">
						</div>

						<input type="hidden" name="report_cashiername" id="report_cashiernames" required class="cashier_option_hidden_input">
						
						<button type="submit" name="generate_report" value="Generate Report" class="cashier_option_submit_button">Search</button>
					</form>

					<script>
						// For the Search button in the report form
						document.getElementById('report_form').addEventListener('submit', function (e) {
								e.preventDefault(); // Stop immediate form submission

								const form = this;
								const submitBtn = form.querySelector('button[type="submit"]');
								const startDateInput = document.getElementById('start_dates');
								const endDateInput = document.getElementById('end_dates');

								const startDate = new Date(startDateInput.value);
								const endDate = new Date(endDateInput.value);
								const today = new Date();
								const twoMonthsAgo = new Date();
								twoMonthsAgo.setMonth(today.getMonth() - 2);

								// Validate: from date must be within last 2 months
								if (startDate < twoMonthsAgo) {
									showAlert("ከሁለት ወር በላይ የሆነዉን ዳታ ማየት አይችሉም.", "danger");
									return;
								}

								// Validate: from date must be before or same as to date
								if (startDate > endDate) {
									showAlert("'From Date' ከ todate መብለጥ የለበትም ", "danger");
									return;
								}

								// Disable the button and show loading
								submitBtn.disabled = true;
								submitBtn.innerText = 'Searching...';
								submitBtn.style.opacity = '0.6';
								submitBtn.style.cursor = 'not-allowed';

								// Delay for 1 second before submitting
								setTimeout(() => {
									form.submit();
								}, 1000);
							});



						document.getElementById("report_choice").addEventListener("change", function() {
							let startDateInput = document.getElementById("start_dates");
							let endDateInput = document.getElementById("end_dates");
							let today = new Date();
							let startDate, endDate;

							switch (this.value) {
								case "today":
									startDate = endDate = today;
									break;
								case "yesterday":
									startDate = new Date(today);
									startDate.setDate(today.getDate() - 1);
									endDate = startDate;
									break;
								case "this_week":
									startDate = new Date(today);
									startDate.setDate(today.getDate() - today.getDay()); // Start of week (Sunday)
									endDate = today;
									break;
								case "last_week":
									startDate = new Date(today);
									startDate.setDate(today.getDate() - today.getDay() - 7); // Previous week's Monday
									endDate = new Date(startDate);
									endDate.setDate(startDate.getDate() + 6); // Last week's Sunday
									break;
								case "this_month":
									startDate = new Date(today.getFullYear(), today.getMonth(), 1);
									endDate = today;
									break;
								case "last_month":
									startDate = new Date(today.getFullYear(), today.getMonth() - 1, 1);
									endDate = new Date(today.getFullYear(), today.getMonth(), 0); // Last day of last month
									break;
								default:
									startDate = endDate = null; // Custom date selection
							}

							if (startDate && endDate) {
								startDateInput.value = startDate.toISOString().split('T')[0];
								endDateInput.value = endDate.toISOString().split('T')[0];
							} else {
								startDateInput.value = "";
								endDateInput.value = "";
							}
						});
					</script>
                </div>
                
                <!-- Date Range Report -->
                <div id="report_section" class="cashier_option_report_section">

					

                    <div class="cashier_option_table_container">
                       
                        
                        <?php if ($response['status'] === 'success'): 
							
							$totalBet = 0;
							$totalPayed = 0;
							$totalNetBalance = 0;
							$totalIncome = 0;
							$total_bonus=0;

							?>


							<label for="itemsPerPage" class="cashier_option_label">Items per page:</label>
							<select id="itemsPerPage" class="cashier_option_items_per_page">
								<option value="10">10</option>
								<option value="20">20</option>
								<option value="50">50</option>
								<option value="100">100</option>
							</select>
							<input type="text" id="searchInput_report" placeholder="Search by Card..." class="cashier_option_search_input">
                            <table class=" cashier_option_table table-bordered" id="report-dataTable">
                                <thead>
                                    <tr>
                                        
                                        <th class="cashier_option_table_header">Bet Time</th>
                                        <th class="cashier_option_table_header">Round</th>
                                        <th class="cashier_option_table_header">On Call</th>
										<th class="cashier_option_table_header" style="font-weight: bold; color: #4CAF50; text-align: left; padding: 10px;">Winner Number</th>

										<th class="cashier_option_table_header">Total Card</th>
										<th class="cashier_option_table_header">Birr</th>
                                        <th class="cashier_option_table_header">Total Bet</th>
                                        <th class="cashier_option_table_header">Paid</th>
                                        <th class="cashier_option_table_header">Income </th>
										<th class="cashier_option_table_header">bonus </th>
										<th class="cashier_option_table_header">Income - bonus  </th>
                                        <th class="cashier_option_table_header">Action</th>
                                    </tr>
                                </thead>
                                <tbody id="cashier_report_display_table" class="cashier_option_table_body">
                                    <?php foreach ($response['data'] as $row): 
                                        
										$santim = floatval($row['santim']);
										$sew = floatval($row['sew']);
										$income = floatval($row['income']);

										

										// Accumulate totals
										$totalBet += ($santim * $sew);
										$totalPayed += (($santim * $sew)-$income); // Assuming this is how total paid is calculated
										$totalIncome += $income;
										$total_bonus+= floatval($row['bonus']);
							
										?>
                                        <tr>
                                            <td><?php echo htmlspecialchars($row['date']); ?></td>
                                            <td><?php echo htmlspecialchars($row['game_round']); ?></td>
                                            <td><?php echo count(array_filter(explode(',', $row['result']))); ?></td>
											<td style="font-size: 16px; font-family: Arial, sans-serif; text-align: center; padding: 10px; 
												<?php 
												$checkedNumbers = explode(',', $row['checked_number']); // Split numbers into an array
												$checkedNumbers = array_map('trim', $checkedNumbers); // Remove any extra spaces

												// Check if the array is empty or contains only empty strings
												$count = count(array_filter($checkedNumbers));

												// Apply color based on the number of results
												if ($count >= 1) {
													echo "color:rgb(125, 255, 116);"; // Exactly one result
												} else {
													echo "color: rgb(255, 147, 147);"; // Default case, red
												}
												?>">
												<?php echo " [".$row['checked_number']. " ]"; ?>
											</td>



											<td><?php echo htmlspecialchars($row['sew']); ?></td>
											<td><?php echo htmlspecialchars($row['santim']); ?></td>
											<td><?php echo number_format(($row['santim'] * $row['sew']), 2); ?></td>
                                            <td><?php echo number_format(($row['santim'] * $row['sew'])-$row['income'], 2); ?></td>
                                            <td><?php echo number_format($row['income'], 2); ?></td>
											<td><?php echo number_format($row['bonus'], 2); ?></td>
											<td><?php echo number_format($row['income']-$row['bonus'], 2); ?></td>
                                            <td><button class="action-button">Action</button></td>
                                        </tr>
										
                                    <?php endforeach; ?>
									<!-- Totals Row -->
									
                                </tbody>
								<!-- Totals Row Outside Pagination -->
								<tfoot>
									<tr>
										<td colspan="6">
                                            <nobr>Total<strong style="color:#f39292">
                                                &nbsp;(<?php echo date("Y-m-d", strtotime($start_datetime)) . " - " . date("Y-m-d", strtotime($end_datetime)); ?>)
                                            </strong></nobr>
                                        </td>
										<td><strong><?php echo number_format($totalBet, 2); ?></strong></td>
										<td><strong><?php echo number_format($totalPayed, 2); ?></strong></td>
										<td><strong><?php echo number_format($totalIncome, 2); ?></strong></td>
										<td><strong><?php echo number_format($total_bonus, 2); ?></strong></td>
										<td>
											<strong class="cashier_option_table_td_fade_in"><?php echo number_format($totalIncome - $total_bonus, 2); ?> ብር</strong>
										</td>
										<td></td>
									</tr>
								</tfoot>
                            </table>
                            <div id="pagination" class="cashier_option_pagination"></div>
                        <?php else: ?>
                            <p style="color:white;font-size:30px;"><?php echo htmlspecialchars($response['message']); ?></p>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
        </div>
    </div>
		
	<script>

			// Simulate login check (replace this with real check)
			const isLoggedIn = localStorage.getItem('loggedin') === 'true';
			// DOM elements
			const userContent = document.getElementById('user-content');

			// If the user is logged in, show user content
			// If the user is not logged in, show overly
			if (isLoggedIn) {
				userContent.style.display = 'block';
			}else
            {
                window.location.href = '../config/logout.php'
            }
			// Handle logout
			const logoutBtn = document.getElementById('logoutbtn');
			logoutBtn.addEventListener('click', function() {

				localStorage.removeItem('loggedin');
				localStorage.removeItem('cashier_id');
				showAlert('Successfully loggedout!', 'success');
				setTimeout(function() {
					window.location.href = '../config/logout.php'
				}, 1000);
				
			});


			

			// Function to show alert in the top right corner
			function showAlert(message, type) 
			{
				const alertDiv = $('#customAlert');
				alertDiv.html(message);
				alertDiv.removeClass('custom-alert-success custom-alert-danger slide-out'); // Clear previous alert classes
				alertDiv.addClass('custom-alert-' + type + ' slide-in'); // Add the appropriate class and slide-in

				alertDiv.show(); // Show the alert

				// Animate the alert by adding the slide-in class
				setTimeout(function() {
					alertDiv.removeClass('slide-in'); // Remove slide-in for smooth transition
				}, 50); // Delay to allow for CSS transition to kick in

				// Hide the alert after 3 seconds
				setTimeout(function() {
					alertDiv.addClass('slide-out'); // Add slide-out class for hiding animation
					setTimeout(function() {
						alertDiv.fadeOut(); // Fade out after the slide-out animation
					}, 300); // Wait for the slide-out transition to complete
				}, 3000);
			}
			// Function to set today's date as default value for the input fields
			function setDefaultDates() 
			{
				var today = new Date();
				var year = today.getFullYear();
				var month = String(today.getMonth() + 1).padStart(2, '0');  // padStart ensures two digits for month
				var day = String(today.getDate()).padStart(2, '0'); // padStart ensures two digits for day

				var formattedDate = year + '-' + month + '-' + day; // Format date as YYYY-MM-DD

				// Set both the from and to date inputs to today's date
				document.getElementById("start_dates").value = formattedDate;
				document.getElementById("end_dates").value = formattedDate;
			}



			//========================================================================================
			//========================================================================================
			//========================================================================================
			//=============================load cashier information====================================
			if (isLoggedIn) 
			{
					$(document).ready(function() 
					{
						// Function to set today's date as default value for the input fields
						setDefaultDates();


						var form_data = {
							get_cashier_data: localStorage.getItem('cashier_id'),
						};

						$.ajax({
							url: "../config/DbFunction.php",
							method: "POST",
							data: form_data,
							dataType: "JSON",
							success: function(resp) {
								// Check if the response contains data
								if (resp.length > 0) {
									// Assuming the first record contains the cashier data
									var cashier = resp[0]; // If there's at least one record
									
									// Set the cashier profile name from the fetched data
									document.getElementById("cashier_profile_name").innerHTML = cashier.cashier_id;
									document.getElementById("report_cashiernames").value = cashier.cashier_id;
									const cashierOptionName = document.getElementById("cashier_option_cashier_name");
									if (cashierOptionName) {
										cashierOptionName.innerHTML = resp[0].cashier_id;
									}
									let formattedNumber = new Intl.NumberFormat('en-US').format(cashier.cashier_package);
									document.getElementById("remaining_balance").innerHTML = formattedNumber;
								} else {
									// If no data found, you can handle the case accordingly
									console.log("No cashier data found.");
									showAlert('No data found for this cashier!', 'danger');
								}
							},
							error: function(jqXHR, textStatus, errorThrown) {
                                // Log detailed error information
                                console.error('Error Details:');
                                console.error('Status: ' + textStatus);
                                console.error('Error Thrown: ' + errorThrown);
                                console.error('Response Text: ' + jqXHR.responseText);
                                showAlert("An error occurred while updating the partner. Check console for details.", "danger");
                            }
						});
					});





					
					
				
					
				
					
										
			}
			
	 if (document.getElementById('report-dataTable')) {
	 	initializeTable('report-dataTable', 'pagination', 'searchInput_report', 'itemsPerPage');
	 }

	function refreshCashierBalance() {
		$.ajax({
			url: "../config/DbFunction.php",
			method: "POST",
			data: { get_cashier_data: localStorage.getItem('cashier_id') },
			dataType: "JSON",
			success: function(resp) {
				if (resp.length > 0) {
					const formatted = new Intl.NumberFormat('en-US').format(resp[0].cashier_package);
					document.getElementById("remaining_balance").innerHTML = formatted;
				}
			}
		});
	}

	function openPackageModal() {
		document.getElementById('packageModalOverlay').classList.add('open');
		document.getElementById('packageModalLoader').style.display = 'flex';
		document.getElementById('packageModalResult').style.display = 'none';
		hidePackageModalStatus();
	}

	function closePackageModal() {
		document.getElementById('packageModalOverlay').classList.remove('open');
		hidePackageModalStatus();
		disablePackageRemote();
	}

	function enablePackageRemote() {
		return $.ajax({
			url: '../config/DbFunction.php',
			method: 'POST',
			data: { package_modal_open: 1 },
			dataType: 'json',
			timeout: 10000
		});
	}

	function disablePackageRemote() {
		$.ajax({
			url: '../config/DbFunction.php',
			method: 'POST',
			data: { package_modal_close: 1 },
			dataType: 'json',
			timeout: 5000
		});
	}

	function packageResultStatusUi(status, resp) {
		const message = resp.message || '';
		switch (status) {
			case 'success':
				return {
					kind: 'success',
					icon: '✓',
					title: 'ተሳክቷል — Success',
					message: message || 'Package deposited and saved securely.',
				};
			case 'duplicate':
				return {
					kind: 'info',
					icon: '✓',
					title: 'አስቀድሞ ተተግብሯል — Already applied',
					message: message || 'This deposit was already saved on this device.',
				};
			case 'empty':
				return {
					kind: 'warning',
					icon: '!',
					title: 'ምንም ፓኬጅ የለም — No package waiting',
					message: message || 'No pending deposit on admin server. Try again after admin adds package.',
				};
			case 'offline':
				return {
					kind: 'danger',
					icon: '✕',
					title: 'ኢንternet የለም — Offline',
					message: message || 'Connect to the internet and tap Re-fetch.',
				};
			default:
				return {
					kind: 'danger',
					icon: '✕',
					title: 'አልተሳካም — Failed',
					message: message || 'Package sync failed.',
				};
		}
	}

	function showPackageModalStatus(ui) {
		const wrap = document.getElementById('packageModalStatus');
		wrap.className = 'package-modal-status visible kind-' + ui.kind;
		document.getElementById('packageModalStatusIcon').textContent = ui.icon;
		document.getElementById('packageModalStatusTitle').textContent = ui.title;
		document.getElementById('packageModalStatusMessage').textContent = ui.message;
	}

	function hidePackageModalStatus() {
		const wrap = document.getElementById('packageModalStatus');
		wrap.className = 'package-modal-status';
		document.getElementById('packageModalStatusIcon').textContent = '';
		document.getElementById('packageModalStatusTitle').textContent = '';
		document.getElementById('packageModalStatusMessage').textContent = '';
	}

	function renderPackageResult(resp) {
		document.getElementById('packageModalLoader').style.display = 'none';
		document.getElementById('packageModalResult').style.display = 'block';

		const status = resp.status || 'error';
		showPackageModalStatus(packageResultStatusUi(status, resp));
		document.getElementById('packageCodeBlock').textContent = resp.code_block || JSON.stringify(resp.display || {}, null, 2);

		if (status === 'success' || status === 'duplicate') {
			refreshCashierBalance();
		}
	}

	function fetchPackageDeposit() {
		document.getElementById('packageModalLoader').style.display = 'flex';
		document.getElementById('packageModalResult').style.display = 'none';
		hidePackageModalStatus();

		$.ajax({
			url: '../config/DbFunction.php',
			method: 'POST',
			data: { sync_package_deposit: 1 },
			dataType: 'json',
			timeout: 25000,
			success: function(resp) {
				renderPackageResult(resp);
			},
			error: function(xhr) {
				let message = 'Could not reach server.';
				try {
					const parsed = JSON.parse(xhr.responseText);
					message = parsed.message || message;
				} catch (e) {}
				renderPackageResult({
					status: 'error',
					message: message,
					code_block: '======================================\n        REQUEST FAILED\n======================================'
				});
			}
		});
	}

	$(document).on('click', '#btnSyncPackage', function() {
		openPackageModal();
		enablePackageRemote().done(function() {
			fetchPackageDeposit();
		}).fail(function() {
			renderPackageResult({
				status: 'error',
				message: 'Could not start remote connection. Try again.',
				code_block: '======================================\n   REMOTE CONNECTION NOT OPEN\n======================================'
			});
		});
	});

	$(document).on('click', '#packageModalRefetch', function() {
		fetchPackageDeposit();
	});

	$(document).on('click', '#packageModalClose, #packageModalCloseFooter', function(e) {
		e.preventDefault();
		closePackageModal();
	});
	</script>

            </div>
        </div>
    </div>
</body>
</html>
