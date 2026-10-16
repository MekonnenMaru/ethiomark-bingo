<?php
           if (session_status() === PHP_SESSION_NONE) {
                session_start();
            }
            
			if (!isset($_SESSION['loggedin'])   || $_SESSION['role']!="cashier") {
                header("Location: ../config/logout.php");
            }   // Include your database configuration
        include_once '../config/Database.php';
        require_once '../config/CartelaResolver.php';

        $db = Database::getInstance();
        $conn = $db->getConnection(); // Get the connection object



		$response = ['status' => 'error', 'message' => 'An error occurred.'];

		// Get the cashier's category based on the logged-in cashier ID
		$cashier_id = $_SESSION['cashier_id'];
		$query = "SELECT `category` FROM `cashier` WHERE `cashier_id` = ?";
		$stmt = $conn->prepare($query);
		if (!$stmt) {
			$response['message'] = "Error fetching category: " . $conn->error;
		} else 
		{
			$stmt->bind_param("s", $cashier_id);
			$stmt->execute();
			$stmt->bind_result($category);
			$stmt->fetch();
			$stmt->close();
		
			if ($category) 
			{
				$rows = cartela_fetch_all_for_category($conn, $category);

				if (!empty($rows)) {
					$data = array_values($rows);
					usort($data, static function ($a, $b) {
						return (int) $a['cartela_number'] - (int) $b['cartela_number'];
					});
					$response['status'] = 'success';
					$response['data'] = $data;
				} else {
					$response['message'] = "No cartela data found for this category.";
				}
			} else {
				$response['message'] = "Category not found for the given cashier.";
			}
		}		

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ethiomark</title>
    	
    <link rel="stylesheet" href="../bootstrap/css/style.css">
    <script src="../bootstrap/js/jquery.js"></script>
    


	<link rel="stylesheet" type="text/css" href="side-nav.css">
	<!-- <link rel="stylesheet" type="text/css" href="container.css"> -->
	<link rel="stylesheet" type="text/css" href="../bootstrap/css/cashier_option_container.css">
	
	<style>
			/* Prevent text selection via CSS */
			body {
				-webkit-user-select: none; /* Chrome, Safari */
				-moz-user-select: none;    /* Firefox */
				-ms-user-select: none;     /* IE10+/Edge */
				user-select: none;         /* Standard */
			}
			#display_cartela_table tr:hover {
				background-color: black;
			}
		</style>
</head>
<body>

		<script>
			// Disable right-click
			document.addEventListener('contextmenu', function (e) {
				e.preventDefault();
				showAlert('Hello! You are using Ethiomark Bingo.', "success");
			});

			// Disable text selection
			document.addEventListener('selectstart', function (e) {
				e.preventDefault();
			});

			// Disable copy
			document.addEventListener('copy', function (e) {
				e.preventDefault();
				showAlert('Copying is disabled.', "warning");
			});

			// Disable cut
			document.addEventListener('cut', function (e) {
				e.preventDefault();
				showAlert('Cutting is disabled.', "warning");
			});

			// Disable paste
			document.addEventListener('paste', function (e) {
				e.preventDefault();
				showAlert('Pasting is disabled.', "warning");
			});

			// Optional: disable drag text
			document.addEventListener('dragstart', function (e) {
				e.preventDefault();
			});
		</script>

    <div id="customAlert" class="custom-alert" style="display: block; position: fixed; top: 20px; right: 20px; z-index: 1000;"></div>
    <div id="user-content" style="display: none;">
          


        <?php include_once("side-nav.php"); ?>






				
        <div class="main-content">
            <div id="cashier_option_content" class="cashier_option_container" style="min-width: 1700px;">                
                <!-- Date Range Report -->
                <div id="report_section" class="cashier_option_report_section">
                    <div class="cashier_option_table_container">
					<?php if ($response['status'] === 'success'): 
														?>
							<!-- Filter Input -->
							<input type="text" id="searchInput" placeholder="Search by Card..." class="search-input">
		
							<!-- Select Items Per Page -->
							<label for="itemsPerPage" class="cashier_option_label">Items per page:</label>
							<select id="itemsPerPage" class="cashier_option_items_per_page">
								<option value="10">10</option>
								<option value="20">20</option>
								<option value="50">50</option>
								<option value="100">100</option>
								<option value="200">200</option>
							</select>
		
							<!-- Table -->
							<table id="cartela-dataTable" class="table">
								<thead>
									<tr  style ="color : white; " >
										<th class="cardh">Card</th>
										<th class="b">B</th>
										<th class="i">I</th>
										<th class="n">N</th>
										<th class="g">G</th>
										<th class="o" >O</th>
										<th class="action"  style ="color : black; " >Category</th>
									</tr>
								</thead>
								<tbody id="display_cartela_table"  style ="color : white; " >
                                        <?php foreach ($response['data'] as $row): 
                                              
                                                ?>
                                                <tr>
                                                <td><?php echo htmlspecialchars($row['cartela_number']); ?></td>
                                                <td><?php echo htmlspecialchars($row['b']); ?></td>
                                                <td><?php echo htmlspecialchars($row['i']); ?></td>
                                                <td><?php echo htmlspecialchars($row['n']); ?></td>
                                                <td><?php echo htmlspecialchars($row['g']); ?></td>
                                                <td><?php echo htmlspecialchars($row['o']); ?></td>
                                                    <td><button class="action-button"><?php echo htmlspecialchars($row['category']); ?></button></td>
                                                </tr>
                                                
                                            <?php endforeach; ?>
                                            <!-- Totals Row -->
                                            
                                        </tbody>
                                    </table>
                                    <div id="pagination" class="cashier_option_pagination"></div>
                                <?php else: ?>
                                    <p><?php echo htmlspecialchars($response['message']); ?></p>
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
//card registration input validation
function validateInput(event, min, max) {
			const value = event.target.value;
			const numValue = parseInt(value, 10);

			if (isNaN(numValue) || numValue < min || numValue > max) {
				event.target.setCustomValidity(`Please enter a number between ${min} and ${max}.`);
			} else {
				event.target.setCustomValidity('');
			}

			event.target.reportValidity();
		}

//========================================================================================
//========================================================================================
//========================================================================================
//=============================load cashier information====================================
if (isLoggedIn) 
{
		$(document).ready(function() 
		{
			// Set up click handlers for the side menu
			$('#cashier_option_link').click(function () {
				showContent('cashier_option_content');
				toggleMenu();
			});
			
			$('#card_record_link').click(function () {
				showContent('card_record_content');
				toggleMenu();
			});

			$('#play_bingo_link').click(function () {
				showContent('play_bingo_content');
				toggleMenu();
			});
			
			$('#register_new_pllayer_link').click(function () {
				showContent('reg_new_game_content');
				toggleMenu();
			});

			

				function showContent(contentId) {
						// Hide all content sections
						const sections = ['card_record_content', 'play_bingo_content', 'cashier_option_content', 'reg_new_game_content'];
						sections.forEach(section => $('#' + section).hide());

						// Resetting inputs or fields in the hidden sections
						sections.forEach(section => {
							if (contentId !== section) {
								$('#' + section + ' input, #' + section + ' textarea').val('');
							}
						});

						// Direct navigation for specific content
						if (contentId === 'play_bingo_content') {
							window.location.href = '../cashier/index.php'; // Direct to bingo page
							return; 
						} else if (contentId === 'reg_new_game_content') {
							window.location.href = 'reg_new_game.php'; // Direct to new game registration
							return;
						}
						else if (contentId === 'cashier_option_content') {
							window.location.href = 'report.php'; // Direct to new game registration
							return;
						}
						else if (contentId === 'card_record_content') {
							window.location.href = 'register_new_card.php'; // Direct to new game registration
							return;
						}

						// Redirect if the clicked contentId is 'add_link'
						if (contentId === 'add_link') {
							window.location.href = 'your_redirect_url.php'; // Change to your desired URL
							return; 
						}

						// Show the selected content for other sections
						$('#' + contentId).show();
					}	
					
					
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
					} else {
						// If no data found, you can handle the case accordingly
						console.log("No cashier data found.");
						showAlert('No data found for this cashier!', 'danger');
					}
				},
				error: function(xhr, status, error) {
					// Log the error for debugging
					console.error("AJAX Error: ", status, error);
					showAlert('Internal error occurred!', 'danger');
				}
			});
			
		});





		
		
}



		// Select the table and pagination elements
		const table = document.getElementById('cartela-dataTable');
		const pagination = document.getElementById('pagination');
		const searchInput = document.getElementById('searchInput');
		const itemsPerPageSelect = document.getElementById('itemsPerPage');

		// Global Variables
		let currentPage = 1;
		let itemsPerPage = 10;
		let rows = Array.from(table.querySelectorAll('tbody tr'));

		// Filter table based on search input
		searchInput.addEventListener('input', () => {
			renderTable();
			updatePagination();
		});

		// Set items per page based on select input
		itemsPerPageSelect.addEventListener('change', () => {
			itemsPerPage = parseInt(itemsPerPageSelect.value, 10);
			currentPage = 1; // Reset to first page
			renderTable();
			updatePagination();
		});

		// Render table based on current page and items per page
		function renderTable() {
			const filteredRows = rows.filter(row => {
				const text = row.textContent.toLowerCase();
				return text.includes(searchInput.value.toLowerCase());
			});

			const start = (currentPage - 1) * itemsPerPage;
			const end = start + itemsPerPage;
			const paginatedRows = filteredRows.slice(start, end);

			// Clear the table body
			table.querySelector('tbody').innerHTML = '';

			// Append the paginated rows
			paginatedRows.forEach(row => {
				table.querySelector('tbody').appendChild(row);
			});
		}

		// Update pagination buttons based on number of pages
		function updatePagination() {
			const filteredRows = rows.filter(row => {
				const text = row.textContent.toLowerCase();
				return text.includes(searchInput.value.toLowerCase());
			});

			const pageCount = Math.ceil(filteredRows.length / itemsPerPage);
			pagination.innerHTML = ''; // Clear pagination

			// Previous Button
			const prevButton = document.createElement('button');
			prevButton.innerText = 'Previous';
			prevButton.addEventListener('click', () => {
				if (currentPage > 1) {
					currentPage--;
					renderTable();
					updatePagination();
				}
			});
			prevButton.disabled = currentPage === 1;
			pagination.appendChild(prevButton);

			// Current Page Display
			const pageDisplay = document.createElement('span');
			pageDisplay.innerText = `Page ${currentPage} of ${pageCount}`;
			pagination.appendChild(pageDisplay);

			// Next Button
			const nextButton = document.createElement('button');
			nextButton.innerText = 'Next';
			nextButton.addEventListener('click', () => {
				if (currentPage < pageCount) {
					currentPage++;
					renderTable();
					updatePagination();
				}
			});
			nextButton.disabled = currentPage === pageCount;
			pagination.appendChild(nextButton);
		}

		// Initial render
		renderTable();
		updatePagination();
</script>
</body>
</html>
