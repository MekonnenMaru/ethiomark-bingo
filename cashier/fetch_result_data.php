<?php
		if (session_status() === PHP_SESSION_NONE) {
			session_start();
		}
		
		if (!isset($_SESSION['loggedin'])   || $_SESSION['role']!="cashier") {
			header("Location: ../config/logout.php");
		}
				include_once '../config/Database.php';
				require_once '../config/Youman.php';
				require_once '../config/CartelaResolver.php';
				require_once '../config/BingoPatterns.php';
				require_once '../config/BingoChecker.php';

				$db = Database::getInstance();
				$conn = $db->getConnection(); // Get the connection object

				$cashier_id = isset($_SESSION['cashier_id']) ? $_SESSION['cashier_id'] : '';

				// // Description of Each Function:
				// // 	check_any_two_lines: Checks if there are at least two full lines (horizontal or vertical).
				// // 	check_any_vertical: Checks if any column (vertical) is fully matched.
				// // 	check_any_horizontal: Checks if any row (horizontal) is fully matched.
				// // 	check_t_pattern: Checks if the top row and middle column are fully matched, forming a "T."
				// // 	check_reverse_t_pattern: Checks if the bottom row and middle column are matched, forming a reverse "T."
				// // 	check_x_pattern: Checks both diagonals to form an "X."
				// // 	check_l_pattern: Checks if the left column and bottom row are matched to form an "L."
				// // 	check_reverse_l_pattern: Checks if the right column and bottom row form a reverse "L."
				// // 	check_half_above: Checks if the top two rows are fully matched.
				// // 	check_half_below: Checks if the bottom two rows are fully matched.
				// // 	check_full_pattern: Checks if the entire Bingo card is matched (all numbers are drawn).



				if ($cashier_id)
				{
			
							if (isset($_POST['chack_card']) && isset($_POST['card_no']) && isset($_POST['round']) && isset($_POST['cashier_id'])) 
							{
								$response = [];
			
								$round_number = $_POST['round']; // The round number
								$cartela_number = $_POST['card_no']; // The card number to check
								$cashier_id = $_POST['cashier_id']; // The cashier ID
								$new_bonus_status = '';
								
								
								
								 // Query to get partner IDs based on cashier_id
                                $query_new_bonus_status = "SELECT * FROM `new_bonus` WHERE `game_id`=? and `cashier_id` = ?";
                                $stmt = $conn->prepare($query_new_bonus_status);
                                $stmt->bind_param("is",$_POST['round'], $cashier_id);
                                $stmt->execute();
                                $result = $stmt->get_result();
                                
                                
                            
                                if ($result && $result->num_rows > 0) {
                                    // Loop through results to fetch all partner IDs
                                    while ($row = $result->fetch_assoc()) {
                                        $new_bonus_status = $row['status'];
                                    }
                                }

								$query = "
									SELECT 
									g.round_number,
									g.cashier_id,
									g.pattern,
									g.cartela_number,
									g.result,
									g.locked_cartela_number,
									c.category,
									c.color,
									c.settings_json
									FROM game g
									JOIN cashier c ON g.cashier_id = c.cashier_id
									WHERE g.round_number = ?
									AND g.cashier_id = ?
									";

								$stmt = $conn->prepare($query);
								if ($stmt)
								{
									$stmt->bind_param('is', $round_number, $cashier_id);
									// Execute the statement
									if ($stmt->execute())
									{
										// Get the result set
										$result = $stmt->get_result();

										if ($result->num_rows > 0) 
										{ 
									    	$row = $result->fetch_assoc();

											$registered_cards = array_flip(array_map(
												'intval',
												array_filter(array_map('trim', explode(',', str_replace(' ', '', $row['cartela_number'] ?? ''))))
											));
											if (isset($registered_cards[(int) $cartela_number])) {
									    	
									    	$locked_list_raw = $row['locked_cartela_number'] ?? ''; // Make sure this column is selected in your query
                                            $locked_cards = array_map('intval', explode(',', str_replace(' ', '', $locked_list_raw)));
                                            $is_locked = in_array((int)$cartela_number, $locked_cards) ? 'yes' : 'no';
                                            
                                            

											$category = $row['category'] ?? 'default';
											$result_color = 'three';
											$resolved_card = cartela_fetch_one($conn, (int) $cartela_number, $category);
											$card_data = $resolved_card ? array_merge($row, $resolved_card) : $row;

											// Explode the card columns into arrays once
											$b_col = isset($card_data['b']) ? explode(',', $card_data['b']) : [];
											$i_col = isset($card_data['i']) ? explode(',', $card_data['i']) : [];
											$n_col = isset($card_data['n']) ? explode(',', $card_data['n']) : [];
											$g_col = isset($card_data['g']) ? explode(',', $card_data['g']) : [];
											$o_col = isset($card_data['o']) ? explode(',', $card_data['o']) : [];

											$card = [
												'B' => $b_col,
												'I' => $i_col,
												'N' => $n_col,
												'G' => $g_col,
												'O' => $o_col
											];

											// Get drawn numbers from 'result' column
											$drawn_numbers = array_map('intval', array_filter(array_map('trim', explode(',', $row['result']))));
											$drawn_set = array_fill_keys($drawn_numbers, true);
											// Use pattern as needed
											$pattern = $row['pattern'];

											$claim_system = [];
											$stored = json_decode($row['settings_json'] ?? '', true);
											if (is_array($stored) && is_array($stored['system'] ?? null)) {
												$claim_system = $stored['system'];
											}
											$post_claim = trim((string) ($_POST['bingo_claim_mode'] ?? ''));
											if ($post_claim !== '' && in_array($post_claim, ['no_restriction', 'allow_later_patterns', 'disqualify_on_miss'], true)) {
												$claim_system['bingo_claim_mode'] = $post_claim;
												$claim_system['bingo_claim_limit'] = $post_claim === 'no_restriction' ? -1 : 0;
											}
											$claim_mode = BingoChecker::claimModeFromSystem($claim_system);
											// No restriction: green/red/blue only (no yellow, no late). Strict modes: + yellow for late win.
											$uses_late_yellow = BingoChecker::usesClaimWindow($claim_mode);
											$special_partner_id_condition = !$uses_late_yellow;
											$pattern_for_eval = (int) BingoPatterns::normalize((int) $pattern);
											$pattern_win_achieved = BingoPatterns::evaluate($card, $drawn_numbers, $pattern_for_eval)['had_pattern'];
											$claim_check = BingoChecker::check(
												$card,
												$drawn_numbers,
												(int) $pattern,
												$is_locked === 'yes',
												$claim_system
											);
											$late_claim_all_yellow = $uses_late_yellow
												&& $claim_check['had_winning_pattern']
												&& $claim_check['is_late_claim'];

											//  Check for specific pattern
											$is_bingo = check_pattern($card, $drawn_numbers, $pattern);
											$win_status = 0;
											$last_called = end($drawn_numbers);
											$is_new_bonus_available = "no";
											$count_winning_line = 0; 
												

											// Initialize a variable to store the HTML table
											$pattern_label = htmlspecialchars(BingoPatterns::englishName((int) $pattern), ENT_QUOTES, 'UTF-8');
											$html = "<div id='round' style='font-size: 30px; font-weight: bolder; background-color: white; color: black; padding: 5px; margin-bottom: 5px; display: flex; justify-content: space-between; align-items: center;'>
												<span style='text-align: left;'>Card No: " . $cartela_number . "</span>
													<span style='text-align: right;color : green;'>" . $pattern_label . "</span>
												</div>";
									
											$html.="<table id='tablefetch' style='width: 90%; margin: 0 auto; position: relative; text-align: center; border-collapse: collapse;'>
														<thead>
														<tr style='line-height: 2.5;'>
															<th class='b' style='background-color: #00478B; color: white;'>B</th>
															<th class='i' style='background-color: #00478B; color: white;'>I</th>
															<th class='n' style='background-color: #00478B; color: white;'>N</th>
															<th class='g' style='background-color: #00478B; color: white;'>G</th>
															<th class='o' style='background-color: #00478B; color: white;'>O</th>
														</tr>
														</thead>
														<tbody>";
											//for pattern 1, 2, 3
											if($pattern)
											{
													// Print the header row for the table (B, I, N, G, O)
													// $html .= "<tr>";
													// foreach (array_keys($card) as $col_name) {
													// 	$html .= "<th>$col_name</th>";
													// }
													// $html .= "</tr>";
													// Define winning corners
													$winning_corners = [
														$card['B'][0], // Top-left corner
														$card['O'][0], // Top-right corner
														$card['B'][4], // Bottom-left corner
														$card['O'][4], // Bottom-right corner
													];

													$winning_center_corners = [
														$card['I'][1], // Top-left corner
														$card['G'][1], // Top-right corner
														$card['I'][3], // Bottom-left corner
														$card['G'][3], // Bottom-right corner
													];

													$winning_center_meskel = [
														$card['I'][2], // Top-left corner
														$card['N'][1], // Top-right corner
														$card['N'][3], // Bottom-left corner
														$card['G'][2], // Bottom-right corner
													];
													
													// Check if all winning corners are found in the winning numbers
													$all_corners_found = true; // Assume true until proven otherwise
													foreach ($winning_corners as $corner) {
														if (!isset($drawn_set[(int) $corner])) {
															$all_corners_found = false; // At least one corner is not found
															break; // Exit early if we already know not all corners are found
														}
													}
													if($all_corners_found){ $count_winning_line++; }


													// Check if all winning center corners are found in the winning numbers
													$all_center_corners_found = true; // Assume true until proven otherwise
													foreach ($winning_center_corners as $corner) {
														if (!isset($drawn_set[(int) $corner])) {
															$all_center_corners_found = false; // At least one corner is not found
															break; // Exit early if we already know not all corners are found
														}
													}
													if($all_center_corners_found){ $count_winning_line++; }


													// Check if all winning center meskel are found in the winning numbers
													$all_center_meskel_found = true; // Assume true until proven otherwise
													foreach ($winning_center_meskel as $meskel) {
														if (!isset($drawn_set[(int) $meskel])) {
															$all_center_meskel_found = false; // At least one meskel is not found
															break; // Exit early if we already know not all meskels are found
														}
													}
													if($all_center_meskel_found){ $count_winning_line++; }


													// Initialize arrays to track winning patterns
													$winning_rows = [];
													$winning_rows_num = [];

													$winning_columns = [];
													$winning_columns_num = [];

													$winning_diagonals = [];
													$winning_diagonals_num = [];



													for ($i = 0; $i < 5; $i++) 
													{
														$row_numbers = [];
														
														foreach ($card as $col_key => $col) {
															$row_numbers[] = $col[$i]; // Collect numbers in the i-th row across all columns
														}

														// Ensure row numbers are integers
														$row_numbers = array_map('intval', $row_numbers);
														
														// Count how many drawn numbers are present in the current row
														$count_drawn = count(array_intersect($row_numbers, $drawn_numbers));
														
														// Debugging output
														// echo "Row $i Numbers: " . implode(", ", $row_numbers) . "\n";
														// echo "Count Drawn in Row $i: $count_drawn\n";

														// Determine expected count based on the row index
														$expected_count = ($i == 2) ? 4 : 5; // Row 2 should have 4, others should have 5
														

														// Check if the count of drawn numbers meets or exceeds the expected count
														if ($count_drawn >= $expected_count) { $winning_rows_num[$i] = implode(", ", $row_numbers); }

														// Check if the count of drawn numbers meets the expected count
														$winning_rows[$i] = $count_drawn >= $expected_count;
														if($winning_rows[$i]){ $count_winning_line++; }
													}

													
													// Check for winning columns
													$occurrences_per_column = []; // Initialize an array to hold occurrences for each column
													$expected_number_of_col_occu = 5; // Default expected number of drawn numbers in a column
													// Initialize winning columns to false
													foreach (array_keys($card) as $col_key) {
														$winning_columns[$col_key] = false; // Default to false
														$occurrences_per_column[$col_key] = 0; // Initialize count to 0 for each column
													}
													// Check for winning columns and count occurrences
													foreach ($card as $col_key => $col) 
													{
														$expected_number_of_col_occu = 5; // Reset expected number for each column
														for ($i = 0; $i < 5; $i++) 
														{
															// Center point in column 'N' (row 2) is free
															if ($col_key === 'N' && $i == 2) {
																continue; // Skip checking this free space
															}
															// Check if the current number is in the drawn numbers
															if (isset($drawn_set[(int) $col[$i]])) {
																$occurrences_per_column[$col_key]++; // Increment the count for this column
																$winning_columns_num[$col_key][] = $col[$i]; // Add the drawn number to winning_columns_num for that column
															}
															// If we are checking column 'N', reduce expected number to 4 since the center is free
															if ($col_key === 'N') {
																$expected_number_of_col_occu = 4;
															}
														}
														// if ($occurrences_per_column[$col_key] >= $expected_number_of_col_occu) { $winning_columns_row[$i] = implode(", ", $row_numbers); }
															// Output the collected column data
														
														// Determine if this column is a winning column
														$winning_columns[$col_key] = ($occurrences_per_column[$col_key] >= $expected_number_of_col_occu);
														if($winning_columns[$col_key]){ $count_winning_line++; }
													}
													// print_r($winning_columns_num);
													// print_r("<br>Column  ");
													// print_r($winning_columns);
	
													// Check for winning diagonals
													$winning_diagonals[0] = count(array_intersect([$card['B'][0], $card['I'][1], $card['N'][2], $card['G'][3], $card['O'][4]], $drawn_numbers)) === 4; // Top-left to bottom-right
													$winning_diagonals[1] = count(array_intersect([$card['B'][4], $card['I'][3], $card['N'][2], $card['G'][1], $card['O'][0]], $drawn_numbers)) === 4; // Top-right to bottom-left
													$winning_diagonals_num[0]=[$card['B'][0], $card['I'][1], $card['N'][2], $card['G'][3], $card['O'][4]];
													$winning_diagonals_num[1]= [$card['B'][4], $card['I'][3], $card['N'][2], $card['G'][1], $card['O'][0]];
													
													if($winning_diagonals[0]){ $count_winning_line++; }
													if($winning_diagonals[1]){ $count_winning_line++; }
	
	
													$locked_cells = [];
													$locked_cells_color = [
														0 => ['B' => null, 'I' => null, 'N' => null, 'G' => null, 'O' => null],
														1 => ['B' => null, 'I' => null, 'N' => null, 'G' => null, 'O' => null],
														2 => ['B' => null, 'I' => null, 'N' => null, 'G' => null, 'O' => null],
														3 => ['B' => null, 'I' => null, 'N' => null, 'G' => null, 'O' => null],
														4 => ['B' => null, 'I' => null, 'N' => null, 'G' => null, 'O' => null],
													];
																		
													$center_point_row = 2; // The row for the center point (N2)
													$center_point_col = 'N'; // The column for the center point (N2)
                    
                    												// 	// Initialize the HTML table
                    												// 	$html = "<table border='1' cellpadding='10' cellspacing='0'>";
                    
                    													// Loop through the rows and add each value for each column into the table
                    													for ($i = 0; $i < 5; $i++) 
                    													{
                    														$html .= "<tr>"; // Start a new row
                    														foreach ($card as $col_name => $col) 
																			{
                    															$number = trim($col[$i]); // Get the number for the current column and row
                    															$cell_color = 'white'; // Default cell color
                    															$txt_color = 'black'; // Default text color
                    
                    															// Check if the current number is drawn
                    															if (isset($drawn_set[(int) $number])) 
                    															{
                    






                    																// // If the number is part of a winning corner
                    																if (in_array($number, $winning_corners)) 
                    																{
                    																	if ($all_corners_found) {
                    																		$hl = BingoChecker::winLineHighlightColor(
                    																			$card,
                    																			$drawn_numbers,
                    																			(int) $pattern,
                    																			'corners:outside',
                    																			$uses_late_yellow,
                    																			$late_claim_all_yellow,
                    																			$claim_mode
                    																		);
                    																		if ($hl !== null) {
                    																			if ($special_partner_id_condition && !$late_claim_all_yellow) {
                    																				$win_status = 1;
                    																			}
                    																			$cell_color = $hl;
                    																			$txt_color = 'white';
                    																			$locked_cells[$i][$col_name] = true;
                    																			$locked_cells_color[$i][$col_name] = $hl;
                    																			if ($hl === 'green' && !$late_claim_all_yellow) {
                    																				$win_status = 1;
                    																				$is_new_bonus_available = "yes";
                    																			}
                    																		} else {
                    																			$cell_color = 'red';
                    																			$txt_color = 'white';
                    																		}
                    																	} else {
                    																		$cell_color = 'red';
                    																		$txt_color = 'white';
                    																	}
                    																}

																					// // If the number is part of a winning corner
                    																if (in_array($number, $winning_center_corners)) 
                    																{
                    																	if ($all_center_corners_found) {
                    																		$hl = BingoChecker::winLineHighlightColor(
                    																			$card,
                    																			$drawn_numbers,
                    																			(int) $pattern,
                    																			'corners:inside',
                    																			$uses_late_yellow,
                    																			$late_claim_all_yellow,
                    																			$claim_mode
                    																		);
                    																		if ($hl !== null) {
                    																			if ($special_partner_id_condition && !$late_claim_all_yellow) {
                    																				$win_status = 1;
                    																			}
                    																			$cell_color = $hl;
                    																			$txt_color = 'white';
                    																			$locked_cells[$i][$col_name] = true;
                    																			$locked_cells_color[$i][$col_name] = $hl;
                    																			if ($hl === 'green' && !$late_claim_all_yellow) {
                    																				$win_status = 1;
                    																				$is_new_bonus_available = "yes";
                    																			}
                    																		} else {
                    																			$cell_color = 'red';
                    																			$txt_color = 'white';
                    																		}
                    																	} else {
                    																		$cell_color = 'red';
                    																		$txt_color = 'white';
                    																	}
                    																}


																					// // If the number is part of a winning meskel
                    																if (in_array($number, $winning_center_meskel)) 
                    																{
                    																	if ($all_center_meskel_found && $pattern_win_achieved) {
                    																		if ($late_claim_all_yellow) {
                    																			$hl = '#bca106';
                    																		} elseif ($claim_mode === 'allow_later_patterns') {
                    																			$hl = 'green';
                    																		} else {
                    																			$found = in_array(end($drawn_numbers), $winning_center_meskel, true);
                    																			$hl = ($found || $special_partner_id_condition) ? 'green' : '#bca106';
                    																			if (!$uses_late_yellow) {
                    																				$hl = 'green';
                    																			}
                    																		}
                    																		if ($special_partner_id_condition && !$late_claim_all_yellow) {
                    																			$win_status = 1;
                    																		}
                    																		$cell_color = $hl;
                    																		$txt_color = 'white';
                    																		$locked_cells[$i][$col_name] = true;
                    																		$locked_cells_color[$i][$col_name] = $hl;
                    																		if ($hl === 'green' && !$late_claim_all_yellow) {
                    																			$win_status = 1;
                    																			$is_new_bonus_available = "yes";
                    																		}
                    																	} else {
                    																		$cell_color = 'red';
                    																		$txt_color = 'white';
                    																	}
                    																}



                    																// ==================Check if the number is part of a winning column
                    																if (!empty($winning_columns[$col_name])) {
                    																	$hl = BingoChecker::winLineHighlightColor(
                    																		$card,
                    																		$drawn_numbers,
                    																		(int) $pattern,
                    																		'col:' . $col_name,
                    																		$uses_late_yellow,
                    																		$late_claim_all_yellow,
                    																		$claim_mode
                    																	);
                    																	if ($hl !== null) {
                    																		if ($special_partner_id_condition && !$late_claim_all_yellow) {
                    																			$win_status = 1;
                    																		}
                    																		$cell_color = $hl;
                    																		$txt_color = 'white';
                    																		$locked_cells[$i][$col_name] = true;
                    																		$locked_cells_color[$i][$col_name] = $hl;
                    																		if ($hl === 'green' && !$late_claim_all_yellow) {
                    																			$win_status = 1;
                    																			$is_new_bonus_available = "yes";
                    																		}
                    																	} else {
                    																		$cell_color = 'red';
                    																		$txt_color = 'white';
                    																	}
                    																} elseif (empty($winning_columns[$col_name])) {
                    																	$cell_color = 'red';
                    																	$txt_color = 'white';
                    																}




																					// ========================Check if the number is part of a winning row
                    																if ($winning_rows[$i]) {
                    																	$hl = BingoChecker::winLineHighlightColor(
                    																		$card,
                    																		$drawn_numbers,
                    																		(int) $pattern,
                    																		'row:' . $i,
                    																		$uses_late_yellow,
                    																		$late_claim_all_yellow,
                    																		$claim_mode
                    																	);
                    																	if ($hl !== null) {
                    																		if ($special_partner_id_condition && !$late_claim_all_yellow) {
                    																			$win_status = 1;
                    																		}
                    																		$cell_color = $hl;
                    																		$txt_color = 'white';
                    																		$locked_cells[$i][$col_name] = true;
                    																		$locked_cells_color[$i][$col_name] = $hl;
                    																		if ($hl === 'green' && !$late_claim_all_yellow) {
                    																			$win_status = 1;
                    																			$is_new_bonus_available = "yes";
                    																		}
                    																	} elseif (!isset($locked_cells[$i][$col_name])) {
                    																		$cell_color = 'red';
                    																		$txt_color = 'white';
                    																	}
                    																}
                    																
                    																if ($winning_diagonals[0] && (
                    																	$number === $card['B'][0] || $number === $card['I'][1]
                    																	|| $number === $card['N'][2] || $number === $card['G'][3]
                    																	|| $number === $card['O'][4]
                    																)) {
                    																	$hl = BingoChecker::winLineHighlightColor(
                    																		$card,
                    																		$drawn_numbers,
                    																		(int) $pattern,
                    																		'diag:0',
                    																		$uses_late_yellow,
                    																		$late_claim_all_yellow,
                    																		$claim_mode
                    																	);
                    																	if ($hl !== null) {
                    																		if ($special_partner_id_condition && !$late_claim_all_yellow) {
                    																			$win_status = 1;
                    																		}
                    																		$cell_color = $hl;
                    																		$txt_color = 'white';
                    																		$locked_cells[$i][$col_name] = true;
                    																		$locked_cells_color[0]['B'] = $hl;
                    																		$locked_cells_color[1]['I'] = $hl;
                    																		$locked_cells_color[2]['N'] = $hl;
                    																		$locked_cells_color[3]['G'] = $hl;
                    																		$locked_cells_color[4]['O'] = $hl;
                    																		if ($hl === 'green' && !$late_claim_all_yellow) {
                    																			$win_status = 1;
                    																			$is_new_bonus_available = "yes";
                    																		}
                    																	} elseif (!isset($locked_cells[$i][$col_name])) {
                    																		$cell_color = 'red';
                    																		$txt_color = 'white';
                    																	}
                    																}

																						if ($winning_diagonals[1] && (
                    																	$number === $card['B'][4] || $number === $card['I'][3]
                    																	|| $number === $card['N'][2] || $number === $card['G'][1]
                    																	|| $number === $card['O'][0]
                    																)) {
                    																	$hl = BingoChecker::winLineHighlightColor(
                    																		$card,
                    																		$drawn_numbers,
                    																		(int) $pattern,
                    																		'diag:1',
                    																		$uses_late_yellow,
                    																		$late_claim_all_yellow,
                    																		$claim_mode
                    																	);
                    																	if ($hl !== null) {
                    																		if ($special_partner_id_condition && !$late_claim_all_yellow) {
                    																			$win_status = 1;
                    																		}
                    																		$cell_color = $hl;
                    																		$txt_color = 'white';
                    																		$locked_cells[$i][$col_name] = true;
                    																		$locked_cells_color[4]['B'] = $hl;
                    																		$locked_cells_color[3]['I'] = $hl;
                    																		$locked_cells_color[2]['N'] = $hl;
                    																		$locked_cells_color[1]['G'] = $hl;
                    																		$locked_cells_color[0]['O'] = $hl;
                    																		if ($hl === 'green' && !$late_claim_all_yellow) {
                    																			$win_status = 1;
                    																			$is_new_bonus_available = "yes";
                    																		}
                    																	} elseif (!isset($locked_cells[$i][$col_name])) {
                    																		$cell_color = 'red';
                    																		$txt_color = 'white';
                    																	}
                    																}



																						

                    															}
                    															
                    															
																				
																				// Check if the center cell [2][2] (column 'N') should be colored based on winning conditions
																				if ($pattern_win_achieved && ( /*$all_corners_found>0 || $all_center_corners_found>0 || */  !empty($winning_rows[2]) || !empty($winning_columns[$col_name]) || $winning_diagonals[0] == 1 || $winning_diagonals[1] == 1) && ($i == 2 && $col_name == 'N')) 
																				{
																					// Initialize cell_color and txt_color variables
																					$cell_color = '#bca106'; // Default color for winning column
																					$txt_color = 'white';
																					if ($late_claim_all_yellow) {
																						$cell_color = '#bca106';
																						$locked_cells_color[$i][$col_name] = '#bca106';
																					} elseif ($claim_mode === 'allow_later_patterns') {
																						$cell_color = 'green';
																						$locked_cells_color[$i][$col_name] = 'green';
																					} else {
																					// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                                                                                    if ($special_partner_id_condition ) {
                                                                                        $cell_color = 'green';
                                                                                    }
                                                                                    
																					// Check if the center cell should be green
																					$isGreen = false;

																					// Check winning outer corner
																					// if ($all_corners_found>0 && $locked_cells_color[2]['B'] == "green") {
																					// 	$isGreen = true;
																					// }

																					// // Check winning center corner
																					// if ($all_center_corners_found>0 && $locked_cells_color[2]['B'] == "green") {
																					// 	$isGreen = true;
																					// }


																					// Check winning rows
																					if (!empty($winning_rows[2]) && $locked_cells_color[2]['B'] == "green") {
																						$isGreen = true;
																					}

																					// Check winning columns
																					if (!$isGreen && !empty($winning_columns[$col_name]) && $locked_cells_color[0][$col_name] == "green") {
																						$isGreen = true;
																					}

																					// Check diagonals
																					if (!$isGreen) {
																						if ($winning_diagonals[0] == 1) {
																							if ($locked_cells_color[0]['B'] == "green") {
																								$isGreen = true;
																							}
																						}

																						if (!$isGreen && $winning_diagonals[1] == 1) {
																							if ($locked_cells_color[0]['O'] == "green") {
																								$isGreen = true;
																							}
																						}
																					}
																					

																					// Set color based on winning condition
																					if ($isGreen) {
																						$cell_color = 'green'; // Override color to green if any condition is met
																						$txt_color = 'white';
																						$locked_cells_color[$i][$col_name] = 'green'; // Lock the color as green
																					} else {
																						$locked_cells_color[$i][$col_name] = $cell_color; // Use default winning column color
																					}
																					}
																				} else if (count($drawn_numbers) > 0 && ($i == 2 && $col_name == 'N')) {
																					$cell_color = 'red'; // If no winning condition and drawn numbers exist
																					$txt_color = 'white';
																				}

                    
                    															// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
																				// If the cell is locked from previous checks, keep it green
                    															if (isset($locked_cells[$i][$col_name])) {
                    																if ($late_claim_all_yellow) {
                    																	$cell_color = '#bca106';
                    																} elseif ($special_partner_id_condition) {
                    																	$cell_color = 'green';
                    																} else {
                    																	$cell_color = $locked_cells_color[$i][$col_name];
                    																}
                    															}
                    															// If the current number is the last drawn number, highlight it in blue
                    															// if ($number == end($drawn_numbers) && array_search($number, $drawn_numbers) !== false) {
                    															// 	$cell_color = 'blue'; // Highlight last drawn number in blue
                    															// 	$txt_color = 'white';
                    															// }
																				// If the current number is the last drawn number, highlight it in blue
																					if ($number == end($drawn_numbers) && array_search($number, $drawn_numbers) !== false) {
																						$cell_color = 'blue'; // Highlight last drawn number in blue
																						$txt_color = 'white';
																						$blink_class = 'blink'; // Add blink class for blinking effect
																						
																					} else {
																						$blink_class = ''; // No blinking for other numbers
																					}
                    
                    
                    															// Inside your loop, where you set up the cell
                    															$display_number = ($number == 0) ? '&#9733;' : $number;
                    															// Output the cell with the appropriate color and value
                    															// $html.= "<td style='background-color: $cell_color; color: $txt_color; border: 2px solid #ccc; font-size: 48px; text-align: center; vertical-align: middle;'>" . $display_number . "</td>";

																				$html .= "<td class='$blink_class' style='background-color: $cell_color; color: $txt_color; border: 2px solid #ccc; font-size: 48px; text-align: center; vertical-align: middle;'>" . $display_number . "</td>";
                    														}
                    														$html .= "</tr>"; // End the row
                    													}
                    
                    													// End the table
                    												// 	$html .= "</table>";
                    
                    													// Output the result and pattern
                    													// $html .= "Result: " . implode(', ', $drawn_numbers) . "<br/>";
                    													// $html .= "Pattern: " . $pattern . "<br/>";
                    
                    													// Now print the entire table at once
                    													 
                    
                    						}
											// elseif if($pattern==2) {
											// 	# code...
											// }
											// End the table
											$html.= "
											</tbody></table>
											</br></br></br>
											";

																							
											$response['status'] = "success";
											$response['message'] = "".$html; 
											$response['last_called'] = $last_called;
											$response['new_bonus_status'] = $new_bonus_status;
											$response['is_new_bonus_available'] = $is_new_bonus_available;

											$pattern_evaluation = BingoPatterns::evaluate($card, $drawn_numbers, (int) $pattern);
											$count_winning_line = $pattern_evaluation['winning_lines'];
											$expected_pattern = BingoPatterns::requiredWinScore((int) $pattern);
											$on_time_win = ($win_status === 1);

											$had_qualifying_win = $pattern_evaluation['had_pattern']
												&& $count_winning_line >= $expected_pattern;

											$check = $claim_check;

											$is_late_claim = false;
											if ($uses_late_yellow && $had_qualifying_win) {
												$is_late_claim = $check['is_late_claim'];
											}

											$win_status = ($had_qualifying_win && !$is_late_claim) ? 1 : 0;

											$response['is_late_claim'] = $is_late_claim;
											$response['locks_on_late_claim'] = $uses_late_yellow ? $check['locks_on_late_claim'] : false;
											$response['bingo_claim_mode'] = $claim_mode;
											$response['uses_late_yellow'] = $uses_late_yellow;

											$response['count_winning_line'] = $count_winning_line;
											$response['expected_pattern'] = $expected_pattern;
											$response['is_locked'] = $is_locked;
											$response['win_status'] = $win_status;

													
													

										} else { // Cartela number is not registered
											$response['message'] = "No data found.";
											$response['status'] = "success";
										}

										} else {
											$response['message'] = "No data found.";
											$response['status'] = "success";
										}

										// Free result set
										$result->free();
									}
									else { $response['error'] = "Execution error: " . $stmt->error;  }
									// Close the statement
									$stmt->close();
								}
								else {  $response['error'] = "Error in query preparation: " . $conn->error;  }

								// Set content type and return the response
								header('Content-Type: application/json');
								echo json_encode($response);
								exit;
								
							}

				} else{
				    header("Location: ../config/logout.php");
				}










				
			function check_pattern($card, $drawn_numbers, $pattern)
			{
				return BingoPatterns::checkPattern($card, $drawn_numbers, (int) $pattern);
			}

					
			?>
