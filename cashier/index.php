<?php
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }

    if (! isset($_SESSION['loggedin']) || $_SESSION['role'] != "cashier") {
        header("Location: ../config/logout.php");
    }

    // // Set session timeout duration (5 minutes = 300 seconds)

    include_once '../config/Database.php';
    //####################################### SET BONUS  #####################################################################
    include_once '../cashier/create_bonus.php';
	require_once '../config/Youman.php';

	

    //############################################################################################################

    $db   = Database::getInstance();
    $conn = $db->getConnection(); // Get the connection object

    /**
     * Full-screen account block overlays (blocked partner, locked cashier, low balance).
     */
    function renderCashierBlockOverlay(string $type, array $data = []): void
    {
        $phone = '0918101037';
        $phoneEsc = htmlspecialchars($phone, ENT_QUOTES, 'UTF-8');

        $accent = '#f59e0b';
        $icon = '💳';
        $title = 'Insufficient Balance';
        $subtitle = 'Please recharge your balance to continue.';
        $footerActions = '';

        if ($type === 'blocked') {
            $accent = '#ef4444';
            $icon = '🚫';
            $title = 'Blocked Partner Account';
            $subtitle = 'Please contact your admin to continue.';
        } elseif ($type === 'locked') {
            $accent = '#f87171';
            $icon = '🔒';
            $title = 'Sorry, your account is locked out!';
            $subtitle = 'Please contact support for assistance.';
            $footerActions = '
                <a href="../config/logout.php" class="cashier-block-btn cashier-block-btn-secondary">Logout</a>';
        } elseif ($type === 'low_balance') {
            $cashierId = htmlspecialchars((string) ($data['cashier_id'] ?? ''), ENT_QUOTES, 'UTF-8');
            $balance = htmlspecialchars((string) ($data['balance'] ?? '0'), ENT_QUOTES, 'UTF-8');
            $footerActions = '
                <a href="../cashier/report.php" class="cashier-block-btn cashier-block-btn-primary">Go to Report</a>';
            $balanceChip = '
                <div class="cashier-block-balance">' . $cashierId . ' = ' . $balance . ' ብር</div>';
        } else {
            return;
        }

        if ($type !== 'low_balance') {
            $balanceChip = '';
        }

        echo '
        <div id="overlay" class="cashier-block-overlay" role="alertdialog" aria-modal="true" aria-labelledby="cashier-block-title">
            <div class="cashier-block-card" style="--block-accent:' . $accent . ';">
                <div class="cashier-block-header">
                    <div class="cashier-block-icon" aria-hidden="true">' . $icon . '</div>
                    <h2 id="cashier-block-title" class="cashier-block-title">' . htmlspecialchars($title, ENT_QUOTES, 'UTF-8') . '</h2>
                </div>
                <div class="cashier-block-body">
                    ' . $balanceChip . '
                    <p class="cashier-block-subtitle">' . htmlspecialchars($subtitle, ENT_QUOTES, 'UTF-8') . '</p>
                    <p class="cashier-block-contact">
                        <a href="tel:' . $phoneEsc . '" class="cashier-block-phone">' . $phoneEsc . '</a>
                    </p>
                </div>
                <div class="cashier-block-footer">' . $footerActions . '</div>
            </div>
        </div>
        <style>
            .cashier-block-overlay {
                position: fixed; inset: 0; z-index: 9999;
                display: flex; align-items: center; justify-content: center;
                padding: 16px; box-sizing: border-box;
                background: rgba(15, 23, 42, 0.88);
                font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
            }
            .cashier-block-card {
                width: 100%; max-width: 420px;
                background: linear-gradient(180deg, #1e293b 0%, #0f172a 100%);
                color: #f8fafc;
                border-radius: 16px;
                box-shadow: 0 24px 48px rgba(0,0,0,0.45);
                border: 1px solid rgba(255,255,255,0.12);
                overflow: hidden;
                text-align: center;
            }
            .cashier-block-header {
                padding: 22px 22px 16px;
                background: color-mix(in srgb, var(--block-accent) 18%, transparent);
                border-bottom: 1px solid rgba(255,255,255,0.08);
            }
            .cashier-block-icon { font-size: 2.5rem; line-height: 1; margin-bottom: 10px; }
            .cashier-block-title {
                margin: 0; font-size: clamp(1.2rem, 4vw, 1.5rem);
                font-weight: 700; line-height: 1.25; letter-spacing: -0.02em;
            }
            .cashier-block-body { padding: 20px 22px 8px; }
            .cashier-block-balance {
                margin: 0 auto 16px; max-width: 100%;
                padding: 12px 16px;
                background: rgba(245, 158, 11, 0.15);
                border: 1px solid rgba(245, 158, 11, 0.35);
                border-radius: 10px;
                font-size: clamp(0.95rem, 3vw, 1.1rem);
                font-weight: 700; color: #fde68a;
                word-break: break-word;
            }
            .cashier-block-subtitle {
                margin: 0 0 14px; font-size: 0.95rem; line-height: 1.55; color: #cbd5e1;
            }
            .cashier-block-contact { margin: 0; }
            .cashier-block-phone {
                display: inline-block; font-size: 1.15rem; font-weight: 600;
                color: #38bdf8; text-decoration: none;
            }
            .cashier-block-phone:hover { text-decoration: underline; }
            .cashier-block-footer {
                display: flex; flex-wrap: wrap; gap: 12px; justify-content: center;
                padding: 18px 22px 22px;
                border-top: 1px solid rgba(255,255,255,0.08);
                background: rgba(0,0,0,0.2);
            }
            .cashier-block-btn {
                display: inline-block; min-width: 180px;
                padding: 14px 22px; border-radius: 10px;
                font-size: 1rem; font-weight: 700; text-decoration: none;
                text-align: center; border: 2px solid transparent;
                transition: transform 0.15s ease, box-shadow 0.15s ease;
            }
            .cashier-block-btn:hover { transform: translateY(-1px); }
            .cashier-block-btn-primary {
                color: #0f172a; background: #f8fafc;
                border-color: rgba(255,255,255,0.2);
                box-shadow: 0 4px 14px rgba(0,0,0,0.25);
            }
            .cashier-block-btn-secondary {
                color: #f8fafc; background: transparent;
                border-color: rgba(255,255,255,0.35);
            }
        </style>';
    }

    $response = ['status' => 'error', 'message' => 'An error occurred.'];

    $cashier_id                   = isset($_SESSION['cashier_id']) ? $_SESSION['cashier_id'] : '';
    $round_number                 = 1;
    $cartela_number               = '';
    $speed_range                  = 3;
    $pattern                      = 1;
    $sound                        = 1;
    $price                        = 0;
    $sew                          = 0;
    $birr                         = 0;
    $bala                         = 0;
    $profit                       = 0;
    $bonus_eligiblity_starts_from = 0;
    $start_get_mony_from          = 0;
    $lock_round_up_last_digit     = 0;
    $income_rounding              = 'off';
    $winner_card                  = [];

    $first_draw = '';
	$profit_json = '';
	$partner_id = 0;

    // Clear specific session variables
    unset($_SESSION['sew']);
    unset($_SESSION['birr']);
    unset($_SESSION['bala']);

    if ($cashier_id) {
        $query = "
				SELECT
					game.`round_number`,
					game.`cartela_number`,
					game.`iscompleted`,
					cashier.`speed_range`,
					cashier.`sound`,
					cashier.`is_active`,
					cashier.`cashier_package`,
					cashier.cashier_id,
					cashier.cashier_profit,
					cashier.winner_card,
					cashier.profit_json,

					game.`price`,
					game.`pattern`,
					game.`first_draw`,

					partner.`is_blocked`,
					partner.`profit`,
					partner.`bonus_eligiblity_starts_from`,
					partner.`start_get_mony_from`,
					partner.`lock_round_up_last_digit`,
					partner.`partner_id`
				FROM `game`
				JOIN `cashier` ON game.`cashier_id` = cashier.`cashier_id`
				JOIN `partner` ON cashier.`partner_id` = partner.`partner_id`
				WHERE
					game.`cashier_id` = ?
				ORDER BY game.`round_number` DESC
				LIMIT 1;

			";

        $stmt = $conn->prepare($query);
        $stmt->bind_param("s", $cashier_id);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($row = $result->fetch_assoc()) {
            if ($row['iscompleted'] == 0) {
                $round_number   = $row['round_number'];
                $cartela_number = str_replace(' ', '', $row['cartela_number']);

                $price                        = $row['price'];
                $numbersArray                 = array_filter(array_map('trim', explode(',', $row['cartela_number']))); // Split, trim, and filter
                $sew                          = count($numbersArray);                                                  // Count of numbers
                $birr                         = $row['price'];
                $bala                         = $row['cashier_package'];
                $profit                       = ($row['cashier_profit'] == 0) ? $row['profit'] : $row['cashier_profit'];
                $bonus_eligiblity_starts_from = $row['bonus_eligiblity_starts_from'];
                $start_get_mony_from          = $row['start_get_mony_from'];
                $lock_round_up_last_digit     = $row['lock_round_up_last_digit'];
                $winner_card                  = $row['winner_card'];


                $first_draw = $row['first_draw'];
				$partner_id = $row['partner_id'];
				$profit_json =$row['profit_json'];

				// $newCashierPackage = base64_encode(openssl_encrypt(10000, 'AES-256-CBC', ENCRYPTION_KEY, 0, ENCRYPTION_IV));
            	$bala = decrypt_cashier_package($bala);
                if ($row['is_blocked'] == "1") {
                    renderCashierBlockOverlay('blocked');
                }

                if ($row['is_active'] == "1") {
                    renderCashierBlockOverlay('locked');
                }

                if ($bala <= "100") {
                    renderCashierBlockOverlay('low_balance', [
                        'cashier_id' => $row['cashier_id'],
                        'balance'    => $bala,
                    ]);
                }

            } else {
                $round_number = $row['round_number'] + 1;
				$bala = decrypt_cashier_package($row['cashier_package']);

                if ($row['is_blocked'] == "1") {
                    renderCashierBlockOverlay('blocked');
                }

                if ($row['is_active'] == "1") {
                    renderCashierBlockOverlay('locked');
                }

                if ($bala <= "100") {
                    renderCashierBlockOverlay('low_balance', [
                        'cashier_id' => $row['cashier_id'],
                        'balance'    => $bala,
                    ]);
                }
            }

            $speed_range = $row['speed_range'];
            $pattern     = $row['pattern'];
            $sound       = $row['sound'];
        }

        // Store values in session for later use
        $_SESSION['sew']  = ! empty($cartela_number) ? count(explode(',', $cartela_number)) : 0;
        $_SESSION['birr'] = $price;
        $_SESSION['bala'] = 10000; // Assuming a constant value for now
    }

    // Render the HTML

?>




<!DOCTYPE html>
<html lang="en"> 
<head>
    <meta charset="UTF-8">
	<meta name="viewport" content="width=1280, initial-scale=0.1, minimum-scale=0.1, maximum-scale=5.0, user-scalable=yes">
	<meta name="robots" content="noindex, noarchive, nosnippet">
    <title>Ethiomark Bingo</title>


	 <!-- Default Stylesheets -->
	 <link id="lightStyleSheet" rel="stylesheet" href="../bootstrap/css/style.css">
	<link id="modalStyleSheet" rel="stylesheet" href="../bootstrap/css/modal.css">
	<link id="giftStyleSheet" rel="stylesheet" href="../bootstrap/css/gift-unboxing.css">
	<link id="ballStyleSheet" rel="stylesheet" type="text/css" href="../bootstrap/css/ball.css">
	<link id="bingoStyleSheet" rel="stylesheet" type="text/css" href="../bootstrap/css/bingon.css">



	<link rel="stylesheet" type="text/css" href="../bootstrap//css/congura.css">
	<link rel="stylesheet" type="text/css" href="../cashier/right-menu.css">
	<link rel="stylesheet" type="text/css" href="../bootstrap/css/reg_card.css">
	<script src="../bootstrap/js/bootstrap.bundle.min.js"></script>
	<script src="../bootstrap//js/jquery.js"></script>
	<script src="../bootstrap/js/bootstrap.min.js"></script>
	<script src="../bootstrap/js/umd.js"></script>


	<link rel="stylesheet" type="text/css" href="../cashier/side-nav.css">
	<link rel="stylesheet" type="text/css" href="../cashier/container.css">



	<script>
			 // IndexedDB setup
				const dbPromise = idb.openDB('audio-cache-db', 1, {
					upgrade(db) {
						if (!db.objectStoreNames.contains('audios')) {
							db.createObjectStore('audios');
						}
					}
				});

			// Audio file directories for each folder with 75 files (1.wav to 75.wav)
			const directories = [
				'../assets/afall/sound/voice/',
				'../assets/afall/sound/nigus/',
				'../assets/afall/sound/modern-arada/',
				'../assets/afall/sound/modern-formal/',
				'../assets/afall/sound/fana/',
				'../assets/afall/sound/famharic/',
				'../assets/afall/sound/foromifa/',
				'../assets/afall/sound/gual/',
				'../assets/afall/sound/wedi/',
				'../assets/afall/sound/addis/',
				'../assets/afall/sound/new_voice_1/',
				'../assets/afall/sound/bereket/'
			];

			// Dynamically generated file names (1.wav to 75.wav)
			const dynamicVoiceFiles = Array.from({ length: 75 }, (_, i) => `${i + 1}.wav`);

			// Special files with a fixed directory
			const specialFiles = {
				'goodbingo.mp3':'../assets/afall/sound/',
				'good.wav': '../assets/afall/sound/',
				'lijemr_new.mp3': '../assets/afall/sound/',
				'locked_card.mp3': '../assets/afall/sound/',
				'notgood.wav': '../assets/afall/sound/',
				'notreg.wav': '../assets/afall/sound/',
				'shuffle.wav': '../assets/afall/sound/',
				'start.mp3': '../assets/afall/sound/',
				'StartupSound.opus': '../assets/afall/sound/',
				'stop.mp3': '../assets/afall/sound/',
				'clapping.mp3': '../assets/afall/sound/',
				'late.mp3': '../assets/afall/sound/'

			};

			// Combine dynamically generated files with special files
			const voiceFiles = [
				...directories.map(directory =>
					dynamicVoiceFiles.map(file => ({ file, directory }))
				).flat(), // Flatten the nested array of dynamically generated files
				...Object.entries(specialFiles).map(([file, directory]) => ({ file, directory })) // Special files
			];

			let activeAudios = []; // Array to track active audio objects
			let backgroundVoicePreloadPromise = null;
			const audioPlaybackCache = new Map();
			let bingoCallCells = null;
			var bingoGameActive = false;
			const bingoUiCache = {
				numCells: {},
				randEl: null,
				ranVoiceEl: null,
				drawnCounterEl: null,
			};

			function initBingoUiCache() {
				bingoUiCache.randEl = document.getElementById('rand');
				bingoUiCache.ranVoiceEl = document.getElementById('ran_voice');
				bingoUiCache.drawnCounterEl = document.getElementById('drawn_number_counter');
				for (let n = 1; n <= 75; n++) {
					let el;
					if (n <= 15) {
						el = document.querySelector('[numb="' + n + '"]');
					} else if (n <= 30) {
						el = document.querySelector('[numi="' + n + '"]');
					} else if (n <= 45) {
						el = document.querySelector('[numn="' + n + '"]');
					} else if (n <= 60) {
						el = document.querySelector('[numg="' + n + '"]');
					} else {
						el = document.querySelector('[numo="' + n + '"]');
					}
					if (el) {
						bingoUiCache.numCells[n] = el;
					}
				}
			}

			async function waitWhileGameActive() {
				while (bingoGameActive) {
					await new Promise((resolve) => setTimeout(resolve, 250));
				}
			}

			function trackActiveAudio(audio, objectUrl) {
				activeAudios.push(audio);
				const cleanup = () => {
					activeAudios = activeAudios.filter((a) => a !== audio);
					if (objectUrl) {
						URL.revokeObjectURL(objectUrl);
					}
				};
				audio.addEventListener('ended', cleanup, { once: true });
				audio.addEventListener('error', cleanup, { once: true });
			}

			async function preloadVoiceDirectory(directory) {
				const audioBlobs = [];
				const batchSize = 6;
				for (let start = 1; start <= 75; start += batchSize) {
					await waitWhileGameActive();
					const end = Math.min(start + batchSize - 1, 75);
					const batchTasks = [];
					for (let i = start; i <= end; i++) {
						const audioUrl = `${directory}${i}.wav`;
						batchTasks.push((async () => {
							const chunk = [];
							await preloadAudioFile(audioUrl, chunk);
							return chunk;
						})());
					}
					const chunks = await Promise.all(batchTasks);
					for (const chunk of chunks) {
						audioBlobs.push(...chunk);
					}
				}
				if (audioBlobs.length > 0) {
					await storeAudiosInBulk(audioBlobs);
				}
			}

			function scheduleRemainingVoicePreloads(skipDirectory) {
				if (backgroundVoicePreloadPromise) {
					return backgroundVoicePreloadPromise;
				}
				backgroundVoicePreloadPromise = (async () => {
					for (const directory of directories) {
						if (directory === skipDirectory) {
							continue;
						}
						await waitWhileGameActive();
						await preloadVoiceDirectory(directory);
						await new Promise((resolve) => setTimeout(resolve, 150));
					}
				})().catch((err) => {
					console.error('Background voice preload error:', err);
				}).finally(() => {
					backgroundVoicePreloadPromise = null;
				});
				return backgroundVoicePreloadPromise;
			}

			function preloadSelectedVoicePack(voiceIndex) {
				const directory = directories[voiceIndex - 1];
				if (!directory) {
					return Promise.resolve();
				}
				return preloadVoiceDirectory(directory);
			}





			// Preload audio files when the window loads
			window.onload = () => {
				initBingoUiCache();
				preloadAudios()
					.catch(err => console.error('Error during audio preloading:', err));
			};

				async function preloadAudios() {
					const audioBlobs = [];
					// console.log("preonload");

					// Define priority directories (adjust this as necessary)
					const selected_voice = document.getElementById("voiceselect").value;
					const priority_path = directories[selected_voice - 1];


					const priorityDirectories = [
						priority_path,
						//'../assets/afall/sound/addis/',
						//'../assets/afall/sound/foromifa/',
						//'../assets/afall/sound/modern-arada/',
						// Add more priority directories as needed
					];

					// Define special files to preload first
					const specialFiles = {
						'goodbingo.mp3':'../assets/afall/sound/',
						'good.wav': '../assets/afall/sound/',
						'lijemr_new.mp3': '../assets/afall/sound/',
						'locked_card.mp3': '../assets/afall/sound/',
						'notgood.wav': '../assets/afall/sound/',
						'notreg.wav': '../assets/afall/sound/',
						'shuffle.wav': '../assets/afall/sound/',
						'start.mp3': '../assets/afall/sound/',
						'StartupSound.opus': '../assets/afall/sound/',
						'stop.mp3': '../assets/afall/sound/',
						'clapping.mp3': '../assets/afall/sound/',
						'late.mp3': '../assets/afall/sound/'
					};

					// Combine special files with the priority directories (if not already included)
					const priorityFiles = Object.keys(specialFiles).map(file => {
						return {
							file,
							directory: specialFiles[file]
						};
					});

					const progress = document.getElementById('audioPreloadProgress');
					progress.style.display = 'block';
					// Constants for circle math (matches SVG values)
					const radius = 45;
					const circumference = 2 * Math.PI * radius; // ≈ 283 (matches stroke-dasharray)
					let loadedFiles = 0;
					// Progress reflects essential audio only (selected voice + sound effects)
					const totalFiles = Object.keys(specialFiles).length + 75 + 2;
					  function updateProgress() 
					  {
							loadedFiles++;
							const percent = Math.min(Math.round((loadedFiles / totalFiles) * 100), 100);
							
							document.getElementById('progressBar').style.width = percent + '%';
							document.getElementById('progressPercent').textContent = percent + '%';
							
							// Optional: Change color when complete
							if(percent === 100) {
								document.getElementById('progressBar').style.background = '#2E7D32';
							}
						}


					// Step 1: Load and store special files first (if not already loaded in priority directories)
					for (const { file, directory } of priorityFiles) {
						const audioUrl = `${directory}${file}`;
						await preloadAudioFile(audioUrl, audioBlobs);
						// Call updateProgress() after each successful file load
						updateProgress();
					}

					// Step 2: Load selected voice pack in parallel batches
					const voiceBatchSize = 6;
					for (let start = 1; start <= 75; start += voiceBatchSize) {
						const end = Math.min(start + voiceBatchSize - 1, 75);
						const batchTasks = [];
						for (let i = start; i <= end; i++) {
							const audioUrl = `${priority_path}${i}.wav`;
							batchTasks.push((async () => {
								const chunk = [];
								await preloadAudioFile(audioUrl, chunk);
								audioBlobs.push(...chunk);
								updateProgress();
							})());
						}
						await Promise.all(batchTasks);
					}

					// Step 3: Store priority files in IndexedDB
					if (audioBlobs.length > 0) {
						await storeAudiosInBulk(audioBlobs);
						updateProgress();
						console.log(`Preloaded and stored ${audioBlobs.length} priority audio files successfully.`);
					} else {
						console.warn("No valid priority audio files were fetched.");
					}

					document.getElementById('statusText').textContent = 'Audio Loaded!';
					setTimeout(function() {
						progress.style.display = 'none';
					}, 2000);

					// Cache other voice packs in the background without blocking the UI
					scheduleRemainingVoicePreloads(priority_path);
				}


				// Helper function to preload a single audio file
				async function preloadAudioFile(audioUrl, audioBlobs) {
					// Check if the file is already in IndexedDB before fetching
					const isCached = await checkIfFileCached(btoa(`${audioUrl}`));
					if (isCached) {
						// console.log(`File already cached: ${audioUrl}`);
						return; // Skip fetching if already cached
					}

					try {
							const response = await fetch(audioUrl);
							if (!response.ok) {
								// Suppress the URL entirely, log a generic message
								console.warn('Skipped a missing audio file.');
								return; // Skip this file if not found
							}
							const blob = await response.blob();
							audioBlobs.push({ url: btoa(audioUrl), blob }); // Store the encrypted URL
						} catch (error) {
							// Suppress the URL entirely, log a generic message
							console.error('Failed to fetch an audio file.');
						}

				}

				// Check if the file is already cached in IndexedDB
				async function checkIfFileCached(url) {
					const db = await dbPromise; // Assuming you have an IndexedDB instance 'dbPromise'
					const transaction = db.transaction('audios', 'readonly');
					const store = transaction.objectStore('audios');
					const cachedBlob = await store.get(url); // Try to get the file by URL

					return cachedBlob !== undefined; // Return true if cached file exists
				}

				// Helper function to store the fetched audio blobs in IndexedDB
				async function storeAudiosInBulk(audioBlobs) {
					if (audioBlobs.length === 0) return;

					const db = await dbPromise; // Assuming you have an IndexedDB instance 'dbPromise'
					const tx = db.transaction('audios', 'readwrite');

					for (const { url, blob } of audioBlobs) {
						tx.store.put(blob, url);
					}

					await tx.done;
					console.log(`Stored ${audioBlobs.length} audio files in IndexedDB.`);
				}


















				// Get audio blob from IndexedDB
				async function getAudio(url) {
					const db = await dbPromise;
					try {
						return await db.get('audios', url);
					} catch (error) {
						console.error('Failed to retrieve audio from IndexedDB:', error);
						return null;
					}
				}

				function playCachedAudio(encryptedUrl, blob) {
					let cached = audioPlaybackCache.get(encryptedUrl);
					if (!cached) {
						cached = {
							blob: blob,
							objectUrl: URL.createObjectURL(blob),
						};
						audioPlaybackCache.set(encryptedUrl, cached);
						if (audioPlaybackCache.size > 100) {
							const oldestKey = audioPlaybackCache.keys().next().value;
							const oldest = audioPlaybackCache.get(oldestKey);
							if (oldest?.objectUrl) {
								URL.revokeObjectURL(oldest.objectUrl);
							}
							audioPlaybackCache.delete(oldestKey);
						}
					}
					const audio = new Audio(cached.objectUrl);
					audio.preload = 'auto';
					trackActiveAudio(audio, null);
					audio.play().catch(error => console.error('Error playing audio:', error));
				}

				// Play audio file from cache or direct
					async function playAudio(voicePath) {
						const encryptedUrl = btoa(voicePath);
						const memoryHit = audioPlaybackCache.get(encryptedUrl);
						if (memoryHit?.blob) {
							playCachedAudio(encryptedUrl, memoryHit.blob);
							return;
						}

						let blob = await getAudio(encryptedUrl);

						if (!blob) {
							try {
								const response = await fetch(voicePath);
								if (!response.ok) {
									return;
								}
								blob = await response.blob();
							} catch (error) {
								return;
							}
						}

						playCachedAudio(encryptedUrl, blob);
					}



					function voices(rb) {
							// Convert 'rb' to a string to safely check for file extension
							const rbString = String(rb);

							// Get the selected voice index from the dropdown
							const selectvoice = document.getElementById("voiceselect").value;

							// Check if 'rb' is a string and contains a file extension (e.g., .mp3, .wav)
							if (rbString.includes('.')) {
								// If rb has an extension, set the path to ../assets/sound/
								const voicePath = `../assets/afall/sound/${rbString}`;
								playAudio(voicePath); // Play the audio from the sound directory
							} else {
								// Otherwise, use the directories array and voiceFiles for dynamic sounds
								const path = directories[selectvoice - 1];

								// Ensure that voiceFiles[rb - 1] is an object and contains a valid filename
								const voiceFile = voiceFiles[rb - 1] && voiceFiles[rb - 1].file; // Assuming 'file' is the property holding the filename

								if (path && voiceFile) {
									// Play the audio from the selected directory
									const voicePath = `${path}${voiceFile}`;
									playAudio(voicePath);
								} else {
									console.error('Invalid voice selection or file index');
								}
							}
						}










				var hasBeenCalled = false; // Flag to track if function has been called
				function startbingo()
				{
					if (hasBeenCalled) {
						return; // Exit if a request is already in progress or the function has been called
					}







					hasBeenCalled = true;

					var btn=document.getElementById('mybtn');
						btn.disabled=true;

					var n=document.getElementById('sew').innerText;
					var s=document.getElementById('birr').innerText;
					var b=document.getElementById('bala').innerText;
					var profit=document.getElementById('profit').innerText;
					var round_number= document.getElementById("round").innerText;

					var bonus_amount=0;

					document.getElementById("round_number_bellow_5").innerHTML="Round "+round_number;

					var bonus_eligiblity_starts_from = document.getElementById("bonus_eligiblity_starts_from").innerText;
					var start_get_mony_from = document.getElementById("start_get_mony_from").innerText;

					// New bonus
					var new_container = document.getElementById('bonusContainer');
					var new_bonus_btn = document.getElementById('bonus');
					var new_bonus_status = document.getElementById('settings_set_bonus').value;
					var new_container = document.getElementById('bonusContainer');


					var bonusTooltip = document.getElementById('bonusTooltip');

					// Check if the bonus status is "on" to enable the button and show the container
					if (new_bonus_status == "on") {

						new_bonus_btn.disabled = false;
						new_container.style.display = 'block';
					} 
					else 
					{
						new_bonus_btn.style.display = 'none';
					}




					// ============================================================================// ============================================================================
					// ============================================================================// ============================================================================

					function getCommissionFromJson(n, s, tiers) 
					{
						if (!Array.isArray(tiers)) return null;

						for (let tier of tiers) {
							if (
								n >= tier.min && 
								(n <= tier.max || tier.max === undefined)
							) {

								console.log("===============================================\n");
								console.log("Sew", n);
								console.log("Santim", s);
								console.log("Dr", n*s);
								console.log("tier.min", tier.min);
								console.log("tier.max", tier.max);
								console.log("tier.percent", tier.percent);
								console.log("Commission percent ",  (tier.percent/ 100));
								console.log("\n===============================================\n");
								
								commission = tier.percent / 100;
								if((n*s)<=120){ 
									commission = 9/100;
									console.log("Drrrrrr is bellow 100 so commission = ",  9);
								}
								
								return commission;
							}
						}
						return null;
					}

					let profit_json_raw = document.getElementById("profit_json").innerText;
					let partner_id = document.getElementById("partner_id").innerText;
					let partner_settings_json_status =  document.getElementById("partner_settings_json_status").innerText;
					let profit_json = null;
					if (profit_json_raw) {
						try { profit_json = JSON.parse(profit_json_raw);  } catch (e) {
							console.error("Invalid JSON:", e);
						}
					}	

					var roundedTotal = 0;
					var dr = n * s; // Total sale
					
		
					//fir miki  add partner id here
					if(( partner_settings_json_status == "on" ) && profit_json && Array.isArray(profit_json.commission_tiers))
					{	
						console.log("===============================================\n");
						console.log("===============================================\n");
						console.log("=======STARTING CALCULATIONS WITH STEP ONE=====\n");
						console.log("===============================================\n");
						console.log("===============================================\n");
						if(n!=0 && s!=0 && b>0){ btn.disabled=false; }
						else{ btn.disabled=true; }
						
						
						var total = n * s * 0.2; // Initial calculation assuming dr < 320
						const commission = getCommissionFromJson(n, s, profit_json.commission_tiers);

						if (commission !== null) {
							total =  n * s * commission;
							console.warn("Commission tier matched, good work Total =  ", total);
						} else {
							console.warn("Commission tier not matched, falling back to default one for Dr = ", dr);
							if (dr >120 && dr < 320) {
								total = n * s * 0.2;
							} else if (dr >= 320 && dr < 800) {
								total = n * s * 0.22;
							} else if (dr >= 800 && dr < 1000) {
								total = n * s * 0.25;
							} else if (dr >= 1000) {
								total = n * s * 0.3;
							}
						}


						if(n!=0 && s!=0 && b>0)
						{
							
							roundedTotal = roundNetIncomeTotal(total);


							var start_get_mony_from = document.getElementById("start_get_mony_from").innerText;
							if (dr< start_get_mony_from) {
								document.getElementById('amount').innerText=(dr)+" ብር ወሳጅ";
								document.getElementById('amount1').innerText=(dr);
							}
							else{
								document.getElementById('amount').innerText=(dr-roundedTotal)+" ብር ወሳጅ";
								document.getElementById('amount1').innerText=(dr-roundedTotal);
								// console.log(n*s+"    ",start_get_mony_from);
							}
						}
					}
					//==0 means auto
					else if(profit==0)
					{
						console.log("===============================================\n");
						console.log("===============================================\n");
						console.log("==STARTING CALCULATIONS WITH STEP TWO [Default]=\n");
						if(n!=0 && s!=0 && b>0) { btn.disabled=false; }
						else { btn.disabled=true; }

						// Calculate the total amount
						total = n * s * 0.2; // Initial calculation assuming dr < 320

						// Determine the discount rate based on the total sale (dr)
						if (dr >120 && dr < 320) {
							total = n * s * 0.2;
							console.log("=============== SELECTED "+ 20 +" ====================\n");
							console.log("===============================================\n");
						} else if (dr >= 320 && dr < 800) {
							total = n * s * 0.22;
							console.log("=============== SELECTED "+ 22 +" ====================\n");
							console.log("===============================================\n");
						} else if (dr >= 800 && dr < 1000) {
							total = n * s * 0.25;
							console.log("=============== SELECTED "+ 25 +" ====================\n");
							console.log("===============================================\n");
						} else if (dr >= 1000) {
							total = n * s * 0.3;
							console.log("=============== SELECTED "+ 30 +" ====================\n");
							console.log("===============================================\n");
						}

						if(n!=0 && s!=0 && b>0)
						{
							var roundedTotal = 0;
							roundedTotal = roundNetIncomeTotal(total);




						}
					}
					else
					{
						console.log("===============================================\n");
						console.log("===============================================\n");
						console.log("STARTING CALCULATIONS WITH STEP THREE [Custome: "+profit+"]\n");
						console.log("===============================================\n");
						console.log("===============================================\n");

						if(n!=0 && s!=0 && b>0){ btn.disabled=false; }
						else{ btn.disabled=true; }
						// Calculate the total amount
						total = n * s * profit/100; // Initial calculation assuming dr < 320


						if(n!=0 && s!=0 && b>0)
						{
							var roundedTotal = 0;
							roundedTotal = roundNetIncomeTotal(total);
							//===================================
						}
					}


					var cashier_id = localStorage.getItem("cashier_id");
					$.ajax({
								type: 'POST',
								url: '../config/DbFunction.php',
								data: {
									get_bonus_data: "true",
								},
								dataType: "json",
								success: function(response)
								{

									if (response.status === 'success')
									{
										console.log((n * s) ,   bonus_eligiblity_starts_from);

										if (response.bonus_amount > 0 && (n * s) >= bonus_eligiblity_starts_from)
										{
											bonus_amount= response.bonus_amount;
											document.getElementById("gift-bonus").innerHTML="+ ቦነስ "+ response.bonus_amount + " ብር";
											document.getElementById("bonusNotification").style.display = "block";
										}
										else
										{
											bonus_amount=0;
											document.getElementById('gift-bonus').innerHTML = "+ ቦነስ " + bonus_amount + " ብር";
											document.getElementById("bonusNotification").style.display = "none";
										}
									}
									else
									{
										console.error('Error saving transaction:', response.message);
									}
									// save transaction
									if (n * s < start_get_mony_from)
									{
										roundedTotal = 0;
									}
									if(true)
									{
											$.ajax({
													type: 'POST',
													url: '../config/DbFunction.php',
													data: {
														round_number: round_number,
														santim: s,
														sew: n,
														income: roundedTotal,
														bonus_amount: bonus_amount,
														cashier_id: cashier_id
													},
													dataType: "json",
													success: function(response)
													{
														if (response.status === 'success') {
															// Handle success case
															console.log('Transaction saved successfully:', response.message);
															// You can also update the UI or reset form fields if needed
														} else {
															// Handle error case
															console.error('Error saving transaction:', response.message);
														}
													},
													error: function(jqXHR, textStatus, errorThrown) {
														// Log detailed error information
														console.error('Error Details:');
														console.error('Status: ' + textStatus);
														console.error('Error Thrown: ' + errorThrown);
														console.error('Response Text: ' + jqXHR.responseText);
														showAlert( "An error occurred while updating the partner. Check console for details.'","danger");
													}
												});
									}else {
										console.log("Small incom  ==> s X birr", start_get_mony_from, '>', n * s);
									}


								},
									error: function(jqXHR, textStatus, errorThrown) {
										// Log detailed error information
										console.error('Error Details:');
										console.error('Status: ' + textStatus);
										console.error('Error Thrown: ' + errorThrown);
										console.error('Response Text: ' + jqXHR.responseText);
										showAlert( "An error occurred while updating the partner. Check console for details.'","danger");
									}
							});
				}


			</script>
	<style>





		/* Notification bag styling for bonus */
		.bonus-notification {
			position: fixed;
			top: 18%;
			right: 50px;
			margin-right: 10px;
			width: 250px;
			padding: 15px;
			background-color: #fff;
			border-radius: 20px;
			border: 3px solid green;
			box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
			z-index: 9999;
			text-align: center;
			animation: slideIn 1s ease-out forwards, shake 0.5s infinite;
		}
		/* Close button styling */
		.close-btn {
			position: absolute;
			top: -10px;
			right: -10px;
			font-size: 24px;
			font-weight: bold;
			color: white;
			background-color: #ff8c00;
			border-radius: 50%;
			padding: 5px 10px;
			cursor: pointer;
			box-shadow: 0 4px 8px rgba(0, 0, 0, 0.3);
			transition: background-color 0.3s, transform 0.2s;
			z-index: 10000; /* Ensure it's above other elements */
		}

		.close-btn:hover {
			background-color: #ff4500;
			transform: scale(1.2); /* Makes it easier to click by enlarging slightly */
		}

		/* Gift/Bonus styling */
		.bonus-text {
			font-weight: bold;
			letter-spacing: 2px;
			font-size: 30px;
			color: green;
			background: linear-gradient(to right, #ffcc33, #ff8c00);
			-webkit-background-clip: text;
			/* color: transparent; */
			border: 3px solid #ffb400;
			padding: 10px;
			border-radius: 10px;
			box-shadow: 0 0 10px #ffb400, 0 0 15px #ff8c00, 0 0 20px #ff8c00;
			position: relative;
		}

		/* Confetti animation */
		.confetti {
			position: absolute;
			top: -50px;
			left: 0;
			right: 0;
			height: 100px;
			pointer-events: none;
			overflow: hidden;
		}

		.confetti::before {
			content: '';
			position: absolute;
			top: 0;
			left: 0;
			right: 0;
			height: 100%;

			background-size: cover;
			animation: confetti 3s ease-out infinite;
		}

		/* Slide-in and shake animations */
		@keyframes slideIn {
			0% {
				transform: translateX(100%);
				opacity: 0;
			}
			100% {
				transform: translateX(0);
				opacity: 1;
			}
		}

		@keyframes shake {
			0%, 100% {
				transform: translateX(0);
			}
			25% {
				transform: translateX(-5px);
			}
			50% {
				transform: translateX(5px);
			}
			75% {
				transform: translateX(-5px);
			}
		}
		.blink {
				animation: blinker 1s linear infinite;
			}

			@keyframes blinker {
				50% {
					opacity: 0;
				}
			}









			/* modallllllllllll */
			/* Styling for the bingo number buttons */
			.bingo-button {
				display: inline-block;
				width: 85px; /* Fixed width for each button */
				margin: 5px; /* Spacing between buttons */
				font-size: 40px; /* Adjust font size */
				background-color: #007bff; /* Button background */
				color: white; /* Button text color */
				border: none;
				padding: 15px;
				border-radius: 5px; /* Rounded corners */
				opacity: 1;
				visibility: visible;
				text-align: center; /* Center-align text */
				vertical-align: middle;
				box-sizing: border-box; /* Include padding in width */
				font-weight: 700;
			}
			/* Media query for screens smaller than 768px (tablets and below) */
			@media screen and (max-width: 768px) {
				.bingo-button {
					width: 50px; /* Reduce button width */
					font-size: 24px; /* Smaller font size */
					padding: 8px; /* Smaller padding */
				}
			}

			/* Animation for wave effect */
			@keyframes wave {
				0% { transform: translateY(-10px); }
				50% { transform: translateY(10px); }
				100% { transform: translateY(-10px); }
			}

			.bingo-button.wave-animation {
				animation: wave 1s ;
			}

			/* Container layout for the buttons */
			#selected-numbers {
				display: flex;
				flex-wrap: wrap; /* Allow wrapping to new lines */
				justify-content: flex-start; /* Align to the left */
				gap: 10px; /* Add space between buttons */
				padding: 10px; /* Optional padding */
			}



	</style>
</head><body>
			<script>
				document.addEventListener('contextmenu', function (e) {
					e.preventDefault();
					showAlert('Hello! You are using Ethiomark Bingo.', "success"); 
				});
				</script>
			<div id="audioPreloadProgress" style="display:none; position:fixed; bottom:20px; left:20px; z-index:2000; width:260px; font-family:Arial, sans-serif;">
			<!-- Status text with dual boundary colors -->
			<div style="text-align:center; margin-bottom:1px;">
				<div style="display:inline-block; padding:2px 15px; background:#2c3e50; border-radius:20px; border:0px solid #ecf0f1;">
				<span id="statusText" style="color:#ecf0f1; font-weight:500; font-size:15px; letter-spacing:0.5px;">Downloading Audio</span>
				</div>
			</div>

			<!-- Progress bar with professional color scheme -->
			<div style="width:100%; height:26px; background:#e0e5e9; border-radius:13px; overflow:hidden; box-shadow:inset 0 1px 3px rgba(0,0,0,0.2); position:relative;">
				<div id="progressBar" style="height:100%; width:0%; background:linear-gradient(to right, #3498db, #2980b9); transition:width 0.4s cubic-bezier(0.08,0.82,0.17,1);">
				<!-- Percentage text with boundary effect -->
				<div id="progressPercent" style="position:absolute; width:100%; text-align:center; line-height:26px; color:white; font-weight:700; font-size:18px; text-shadow:0 1px 3px rgba(0,0,0,0.4); letter-spacing:0.5px;"></div>
				</div>
			</div>
			</div>


		<div id="customAlert" class="custom-alert" style="display: none; position: fixed; top: 20px; right: 20px; z-index: 2000;"></div>
		<div id="overlay" class="hidden"></div>

		<div style="display:none;" class="bonus-notification" id="bonusNotification">
			<span class="close-btn" onclick="closeNotification()">×</span>
			<h1 id="gift-bonus" class="bonus-text">

			</h1>
			<div class="confetti"></div>
		</div>
			<script>
				function closeNotification() {
					document.getElementById("bonusNotification").style.display = "none";
				}

			</script>

			<!-- ========================================================================== -->


					<?php
                        $query_new_bonusdata = "SELECT COUNT(`bonus`) AS number_of_bonus FROM `transaction` WHERE `cashier_id` = ? AND DATE(date) = CURDATE() AND `bonus` > 0";
                        $stmt_new_bonusdata  = $conn->prepare($query_new_bonusdata);
                        $stmt_new_bonusdata->bind_param("s", $cashier_id);
                        $stmt_new_bonusdata->execute();

                        $stmt_new_bonusdata->bind_result($todays_new_bonus_count);
                        $stmt_new_bonusdata->fetch();
                        $stmt_new_bonusdata->close();

                    ?>


                    <?php  
						// 1. First get the cashier's settings_json
						$query_settings = "SELECT settings_json FROM cashier WHERE cashier_id = ?";
						$stmt_settings = $conn->prepare($query_settings);
						$stmt_settings->bind_param("s", $cashier_id);
						$stmt_settings->execute();
						$stmt_settings->bind_result($settings_json);
						$stmt_settings->fetch();
						$stmt_settings->close();

						// 2. Parse the JSON settings
						$settings = json_decode($settings_json, true);

						//Bonus settings
						$new_bonus_status = $settings['bonus']['status'] ?? 'off';
						$new_bonus_amount = $settings['bonus']['amount'] ?? 20;
						$max_new_bonus_per_day = $settings['bonus']['per_day'] ?? 1;

						//system settings
						$auto_check_result     = $settings['system']['check_result'] ?? "manual";
						$color                 = 'three';
						$good_bingo_sound      =$settings['system']['good_bingo_sound'] ?? 0;
						$income_rounding       = $settings['system']['income_rounding'] ?? 'off';

						//system settings
						$will_start     = $settings['toggles']['will_start'] ?? "true";
						$started        = $settings['toggles']['started'] ?? "true";
						$stopped      = $settings['toggles']['stopped'] ?? "true";
						$show_card_count = $settings['toggles']['show_card_count'] ?? "true";

					?>


					<?php
						// Assuming $conn is your mysqli connection
							$sqlllllll = "SELECT partner_settings FROM partner WHERE partner_id = ?";

							$stmtkkkkkk = $conn->prepare($sqlllllll);
							$stmtkkkkkk->bind_param("s", $partner_id); // or "i" if partner_id is an integer
							$stmtkkkkkk->execute();
							$stmtkkkkkk->bind_result($partner_settings_json);
							$partner_settings_json_status = 'off'; // default
							if ($stmtkkkkkk->fetch()) {
								$settings = json_decode($partner_settings_json, true);
								if (isset($settings['custom_profit_json']['status'])) {
									$partner_settings_json_status = $settings['custom_profit_json']['status'];
								}
							}
							$stmtkkkkkk->close();


					?>
					<p id="ran_voice" hidden><?php echo $sound; ?></p>
					<p id="patt" hidden><?php echo $pattern; ?></p>
					<?php
						$special_cashier_id_to_start_commission_from_zero = ["@temp1", "Dani1", "temesgen", "mek.c1"];
					?>

					<p id="start_get_mony_from" hidden>
						<?php 
						if (in_array($cashier_id, $special_cashier_id_to_start_commission_from_zero)) {
							echo 0; 
						} else { 
							echo $start_get_mony_from; 
						}
						?>
					</p>


					<p id="bonus_eligiblity_starts_from" hidden><?php echo $bonus_eligiblity_starts_from; ?></p>
					<p id="lock_round_up_last_digit" hidden><?php echo $lock_round_up_last_digit; ?></p>
					<p id="income_rounding" hidden><?php echo htmlspecialchars($income_rounding ?? 'off', ENT_QUOTES, 'UTF-8'); ?></p>
					<p id="round" hidden><?php echo $round_number; ?></p>
					<p id="sew" hidden><?php echo $sew; ?></p>
					<p id="birr" hidden><?php echo $birr; ?></p>
					<p id="bala" hidden><?php echo $bala; ?></p>
					<p id="profit" hidden><?php echo $profit; ?></p>


					<p id="new_bonus_status" hidden style="font-size:50px;"><?php echo $new_bonus_status; ?></p>
					<p id="new_bonus_amount" hidden style="font-size:50px;"><?php echo $new_bonus_amount; ?></p>
					<p id="max_new_bonus_per_day" hidden style="font-size:50px;"><?php echo $max_new_bonus_per_day; ?></p>
					
					<p id="todays_new_bonus_count" hidden style="font-size:50px;"><?php echo $todays_new_bonus_count; ?></p>
					<p id="auto_check_result" hidden style="font-size:50px;"><?php echo $auto_check_result; ?></p>
					<p id="color" hidden style="font-size:50px;"><?php echo $color; ?></p>
					<p id="good_bingo_sound" hidden style="font-size:50px;"><?php echo $good_bingo_sound; ?></p>
					<p id="profit_json" hidden style="font-size:50px;"><?php echo $profit_json; ?></p>
					<p id="partner_id" hidden style="font-size:50px;"><?php echo $partner_id; ?></p>
					<p id="partner_settings_json_status" hidden style="font-size:50px;"><?php echo $partner_settings_json_status; ?></p>



			<!-- ========================================================================== -->

	<div id="user-content" style="display: block;" >





				<!-- Container for buttons aligned in a column -->
				<div id="buttonContainer" style="position: absolute; top: 0px; right: 2px; z-index: 9999; display: flex; flex-direction: column; gap: 5px; align-items: flex-end; width: 50px;">

						<!-- Button with embedded toggle switch -->
						<button id="toggleBTN" style="display: flex; align-items: center; justify-content: center; padding: 15px 0; background-color: transparent; color: white; border: 2px solid #28a745; border-radius: 5px; cursor: pointer; width: 100%; text-align: center;">
							<!-- Toggle Switch Icon -->
							<div id="toggleIcon" style="display: flex; align-items: center; justify-content: center; width: 30px; height: 20px; background-color: white; border-radius: 10px; margin-right: 10px; position: relative;">
								<!-- The toggle circle inside the icon -->
								<div id="toggleCircle" style="width: 14px; height: 14px; background-color: #28a745; border-radius: 50%; position: absolute; top: 3px; left: 3px; transition: left 0.3s;"></div>
							</div>
						</button>

						<!-- Fullscreen Button -->
						<button id="fullscreenBtn" style="display: flex; align-items: center; justify-content: center; padding: 0px 0; background-color: transparent; color: white; border: 2px solid #28a745; border-radius: 5px; cursor: pointer; width: 100%; text-align: center;">
							<svg width="14" height="14" fill="#ffffff" class="bi bi-fullscreen" viewBox="0 0 16 16">
								<path d="M1.5 1a.5.5 0 0 0-.5.5v4a.5.5 0 0 1-1 0v-4A1.5 1.5 0 0 1 1.5 0h4a.5.5 0 0 1 0 1zM10 .5a.5.5 0 0 1 .5-.5h4A1.5 1.5 0 0 1 16 1.5v4a.5.5 0 0 1-1 0v-4a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 1-.5-.5M.5 10a.5.5 0 0 1 .5.5v4a.5.5 0 0 0 .5.5h4a.5.5 0 0 1 0 1h-4A1.5 1.5 0 0 1 0 14.5v-4a.5.5 0 0 1 .5-.5m15 0a.5.5 0 0 1 .5.5v4a1.5 1.5 0 0 1-1.5 1.5h-4a.5.5 0 0 1 0-1h4a.5.5 0 0 0 .5-.5v-4a.5.5 0 0 1 .5-.5"/>
							</svg>
						</button>

						<!-- Report Button -->
						<!-- <button  style="display: flex; align-items: center; justify-content: center; padding: 1px 0; background-color: transparent; color: white; border: 2px solid #28a745; border-radius: 5px; cursor: pointer; width: 100%; text-align: center;">
							<a href="report.php" style="color:white;">
								<svg width="14" height="14" fill="currentColor" class="bi bi-currency-exchange" viewBox="0 0 16 16">
									<path d="M0 5a5 5 0 0 0 4.027 4.905 6.5 6.5 0 0 1 .544-2.073C3.695 7.536 3.132 6.864 3 5.91h-.5v-.426h.466V5.05q-.001-.07.004-.135H2.5v-.427h.511C3.236 3.24 4.213 2.5 5.681 2.5c.316 0 .59.031.819.085v.733a3.5 3.5 0 0 0-.815-.082c-.919 0-1.538.466-1.734 1.252h1.917v.427h-1.98q-.004.07-.003.147v.422h1.983v.427H3.93c.118.602.468 1.03 1.005 1.229a6.5 6.5 0 0 1 4.97-3.113A5.002 5.002 0 0 0 0 5m16 5.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0m-7.75 1.322c.069.835.746 1.485 1.964 1.562V14h.54v-.62c1.259-.086 1.996-.74 1.996-1.69 0-.865-.563-1.31-1.57-1.54l-.426-.1V8.374c.54.06.884.347.966.745h.948c-.07-.804-.779-1.433-1.914-1.502V7h-.54v.629c-1.076.103-1.808.732-1.808 1.622 0 .787.544 1.288 1.45 1.493l.358.085v1.78c-.554-.08-.92-.376-1.003-.787zm1.96-1.895c-.532-.12-.82-.364-.82-.732 0-.41.311-.719.824-.809v1.54h-.005zm.622 1.044c.645.145.943.38.943.796 0 .474-.37.8-1.02.86v-1.674z"/>
								</svg>
							</a>
						</button> -->

						<!-- settings Button -->
						<button id="settings" style="display: flex; align-items: center; justify-content: center; padding: 0px 0; background-color: transparent; color: white; border: 3px solid rgb(243, 49, 0); border-radius: 5px; cursor: pointer; width: 100%; text-align: center;">
							<svg width="14" height="8" fill="currentColor" class="bi bi-gear" viewBox="0 0 16 16">
								<path d="M8 4.754a3.246 3.246 0 1 0 0 6.492 3.246 3.246 0 0 0 0-6.492M5.754 8a2.246 2.246 0 1 1 4.492 0 2.246 2.246 0 0 1-4.492 0"/>
								<path d="M9.796 1.343c-.527-1.79-3.065-1.79-3.592 0l-.094.319a.873.873 0 0 1-1.255.52l-.292-.16c-1.64-.892-3.433.902-2.54 2.541l.159.292a.873.873 0 0 1-.52 1.255l-.319.094c-1.79.527-1.79 3.065 0 3.592l.319.094a.873.873 0 0 1 .52 1.255l-.16.292c-.892 1.64.901 3.434 2.541 2.54l.292-.159a.873.873 0 0 1 1.255.52l.094.319c.527 1.79 3.065 1.79 3.592 0l.094-.319a.873.873 0 0 1 1.255-.52l.292.16c1.64.893 3.434-.902 2.54-2.541l-.159-.292a.873.873 0 0 1 .52-1.255l.319-.094c1.79-.527 1.79-3.065 0-3.592l-.319-.094a.873.873 0 0 1-.52-1.255l.16-.292c.893-1.64-.902-3.433-2.541-2.54l-.292.159a.873.873 0 0 1-1.255-.52zm-2.633.283c.246-.835 1.428-.835 1.674 0l.094.319a1.873 1.873 0 0 0 2.693 1.115l.291-.16c.764-.415 1.6.42 1.184 1.185l-.159.292a1.873 1.873 0 0 0 1.116 2.692l.318.094c.835.246.835 1.428 0 1.674l-.319.094a1.873 1.873 0 0 0-1.115 2.693l.16.291c.415.764-.42 1.6-1.185 1.184l-.291-.159a1.873 1.873 0 0 0-2.693 1.116l-.094.318c-.246.835-1.428.835-1.674 0l-.094-.319a1.873 1.873 0 0 0-2.692-1.115l-.292.16c-.764.415-1.6-.42-1.184-1.185l.159-.291A1.873 1.873 0 0 0 1.945 8.93l-.319-.094c-.835-.246-.835-1.428 0-1.674l.319-.094A1.873 1.873 0 0 0 3.06 4.377l-.16-.292c-.415-.764.42-1.6 1.185-1.184l.292.159a1.873 1.873 0 0 0 2.692-1.115z"/>
							</svg>
						</button>

						<!-- Help Button -->
						<button id="helps" style="display: flex; align-items: center; justify-content: center; padding: 0px 0; background-color: transparent; color: white; border: 2px solid #28a745; border-radius: 5px; cursor: pointer; width: 100%; text-align: center;">
							<svg width="16" height="1" fill="currentColor" class="bi bi-info-circle" viewBox="0 0 16 16">
							<path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14m0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16"/>
							<path d="m8.93 6.588-2.29.287-.082.38.45.083c.294.07.352.176.288.469l-.738 3.468c-.194.897.105 1.319.808 1.319.545 0 1.178-.252 1.465-.598l.088-.416c-.2.176-.492.246-.686.246-.275 0-.375-.193-.304-.533zM9 4.5a1 1 0 1 1-2 0 1 1 0 0 1 2 0"/>
							</svg>
						</button>


						<?php
                            // Fetch bonus data separately
                            $bonusQuery = "SELECT winner_number FROM new_bonus WHERE cashier_id = ? AND game_id = ?";
                            $bonusStmt  = $conn->prepare($bonusQuery);
                            $bonusStmt->bind_param('ss', $cashier_id, $round_number);
                            $bonusStmt->execute();
                            $bonusResult = $bonusStmt->get_result();
                            $bonusData   = $bonusResult->fetch_assoc();

                            // Extract winner numbers
                            $winnerNumbers = isset($bonusData['winner_number']) ? explode(',', $bonusData['winner_number']) : [];

                            function getBingoLetter($number)
                            {
                                if ($number >= 1 && $number <= 15) {
                                    return 'B-';
                                }

                                if ($number >= 16 && $number <= 30) {
                                    return 'I-';
                                }

                                if ($number >= 31 && $number <= 45) {
                                    return 'N-';
                                }

                                if ($number >= 46 && $number <= 60) {
                                    return 'G-';
                                }

                                if ($number >= 61 && $number <= 75) {
                                    return 'O-';
                                }

                                return ''; // Default case (shouldn't happen)
                            }
                        ?>

							<!-- Bonus Button -->
							<button id="bonus" style="<?php if ($new_bonus_status == 'off') {echo 'display: none;';}?>">
								<span>ቦነስ								               								                <?php /*echo !empty($winnerNumbers) ? implode(', ', $winnerNumbers) : "No Bonus"; */?></span>
								<div id="bonusTooltip" class="tooltip">
									ቦነስ ከፈለጉ እባክዎት በቀይ የተከበበችዋ <br>
									ጋር በመንካት Bonus status <br>
									የሚለውን ያብሩት!
								</div>
							</button>

							<!-- Bonus Description Container -->
							<div id="bonusContainer">
								<button id="close-bonus">&times;</button>
								<div id="bonusContent">
									<h1>🎉 ቺርስ 🎉</h1>
										<!-- <h2>በ <span class="highlight"> 4 </span> ጥሪ ከጨረሱ <span class="highlight"> 200 </span> ብር🎉</h2> -->
										<p hidden id = 'special_bonus_data'><?php echo implode(', ', $winnerNumbers); ?></p>

									<p class="special-bonus">
										<?php
                                            // Generate bingo-word buttons dynamically with BINGO prefixes
                                            if (! empty($winnerNumbers)) {
                                                foreach ($winnerNumbers as $number) {
                                                    $bingoLetter = getBingoLetter((int) $number);
                                                    echo "<button class='bingo-word'><span  class='bingo-word-text'>{$bingoLetter}{$number}</span></button>";
                                                }
                                                echo '<button class="bingo-word"> ከጨረሱ <span class="highlight">' . $new_bonus_amount . ' ብር🎉</span></button>';
                                            } else {
                                                echo "<button class='bingo-word'>No Bonus</button>";
                                            }
                                        ?>
									</p>
								</div>
							</div>



						

						<div class="settings-menu" id="settings-menu">
							<div class="settings-header">
								<h2>Settings - ማስተካከያ </h2>
								<button class="close-btn" id="close-menu">&times;</button>
							</div>


							<div class="settings-option">
								<label>Bonus status - ቦነስ:</label>
								<select id="settings_set_bonus" class="bonus-toggle">
									<option value="off">ጠፍቷል</option>
									<option value="on">በርቷል</option>
								</select>
							</div>
							<!-- Conditional Bonus Settings (hidden by default) -->
							<div class="bonus-submenu" style="display: none;">
								<div class="settings-option">
									<label for="settings_bonus_amount">Amount of money (20-300):</label>
									<input type="number" id="settings_bonus_amount" min="20" max="300" step = "10" value="50" class="bonus-input">
								</div>
								
								<div class="settings-option">
									<label for="sittings_bonus_options">Number of bonus options (1-4):</label>
									<select id="sittings_bonus_options" class="bonus-input">
									<option value="1">1</option>
									<option value="2">2</option>
									<option value="3">3</option>
									<option value="4">4</option>
									</select>
								</div>
							</div>
							<div class="settings-option">
								<label>Check Result - አሸናፊዉን መለየት :</label>
								<select id="settings_check_result">
									<option value="auto">Auto</option>
									<option value="manual">Manual</option>
								</select>
							</div>
							<div class="settings-option">
								<label for="settings_bingo_claim_mode">Too late — ዘግይቷል (claim rule):</label>
								<select id="settings_bingo_claim_mode">
									<option value="no_restriction">No late-claim restriction</option>
									<option value="allow_later_patterns">Allow winning on new patterns</option>
									<option value="disqualify_on_miss">Disqualify after missed claim</option>
								</select>
							</div>
							<div class="settings-option">
								<label>good bingo sound :</label>
								<select id="settings_good_bingo_sound">
									<option value="0">ይህ ካርቴላ አሸንፏል </option>
									<option value="1">ጭብጨባ</option>
									<option value="2">ጉድ ቢንጎ - Good Bingo</option>
								</select>
							</div>

							<div  class="settings-option">
								<label>Set Profit:</label>
								<select id="settings_cashier_profit">
									<option value="0">Default</option>
									<option value="10">10%</option>
									<option value="12">12%</option>
									<option value="15">15%</option>
									<option value="17">17%</option>
									<option value="20">20%</option>
									<option value="23">23%</option>
									<option value="25">25%</option>
									<option value="27">27%</option>
									<option value="30">30%</option>
									<option value="33">33%</option>
									<option value="35">35%</option>
									<option value="37">37%</option>
									<option value="40">40%</option>
								</select>
							</div>


							<div class="sound-settings-toggles">
								<div class="sound-settings-toggle-row">
									<div class="sound-settings-toggle-group">
									<label class="sound-settings-toggle-label">ሊጀምር ነው ድምጽ</label>
									<label class="sound-settings-switch">
										<input type="checkbox" id="will_start_sound_toggle">
										<span class="sound-settings-slider"></span>
										<span class="sound-settings-state">OFF</span>
									</label>
									</div>
									
									<div class="sound-settings-toggle-group">
									<label class="sound-settings-toggle-label">ጨዋታው ጀምሯል ድምጽ</label>
									<label class="sound-settings-switch">
										<input type="checkbox" id="started_sound_toggle" checked>
										<span class="sound-settings-slider"></span>
										<span class="sound-settings-state">ON</span>
									</label>
									</div>
									
									<div class="sound-settings-toggle-group">
									<label class="sound-settings-toggle-label">ጨዋታው ቁሟል ድምጽ</label>
									<label class="sound-settings-switch">
										<input type="checkbox" id="stopped_sound_toggle">
										<span class="sound-settings-slider"></span>
										<span class="sound-settings-state">OFF</span>
									</label>
									</div>
								</div>

								<div class="sound-settings-toggle-row">
									<div class="sound-settings-toggle-group">
									<label class="sound-settings-toggle-label">የተመዘገበ ቁጥር ብዛት</label>
									<label class="sound-settings-switch">
										<input type="checkbox" id="counte_registerd_card">
										<span class="sound-settings-slider"></span>
										<span class="sound-settings-state">OFF</span>
									</label>
									</div>

									<div class="sound-settings-toggle-group">
									<label class="sound-settings-toggle-label" for="settings_income_rounding">የገቢ ማስተካከል</label>
									<label class="sound-settings-switch">
										<input type="checkbox" id="settings_income_rounding">
										<span class="sound-settings-slider"></span>
										<span class="sound-settings-state" id="settings_income_rounding_state">OFF</span>
									</label>
									</div>
									
								</div>
								<p id="settings_income_rounding_hint" style="display: none; margin: 8px 0 0; font-size: 14px; color: #94a3b8; line-height: 1.4;"></p>
							</div>



							<center> <button id ="submit_settings_form" class="settings-option" style="color:green; font-size: 30px;ፓድዲንግ፡ 5ፕሽ፤"> Save Changes</button> </center>
							<center> <i style="color:green; font-size: 30px;" id="settings_update_response"></i></center>
						</div>


						<script>
							// Get the bonus container
							const bonusContainer = document.getElementById('bonusContainer');

							// Variables to track dragging
							let isDragging = false;
							let offsetX, offsetY;

							document.addEventListener("DOMContentLoaded", function () {
								var bonus_btn = document.getElementById('bonus');
								if (bonus_btn) {
									bonus_btn.disabled = true;
								}
							});



							// Load saved position from local storage
							let savedPosition = JSON.parse(localStorage.getItem('bonusContainerPosition')) || { left: 0, top: 0 };

							// Get current window size
							const windowWidth = window.innerWidth;
							const windowHeight = window.innerHeight;

							let posTop = savedPosition.top < windowHeight ? savedPosition.top : 0;
    						let posLeft = savedPosition.left < windowWidth ? savedPosition.left : 0;


							console.log("Top ", posTop, "left ",posLeft);

							if (JSON.parse(localStorage.getItem('bonusContainerPosition'))) {
								bonusContainer.style.top = `${posTop}px`;
   								bonusContainer.style.left = `${posLeft}px`;
							} else {

								// Default position if no saved position exists
								bonusContainer.style.right = '20px';
								bonusContainer.style.top = '80%';
							}
							// Mouse down event to start dragging
							bonusContainer.addEventListener('mousedown', (e) => {
								isDragging = true;
								offsetX = e.clientX - bonusContainer.getBoundingClientRect().left;
								offsetY = e.clientY - bonusContainer.getBoundingClientRect().top;
							});

							// Mouse move event to drag the container
							document.addEventListener('mousemove', (e) => {
								if (isDragging) {
									const x = e.clientX - offsetX;
									const y = e.clientY - offsetY;

									// Ensure the container stays within the viewport
									const maxX = window.innerWidth - bonusContainer.offsetWidth;
									const maxY = window.innerHeight - bonusContainer.offsetHeight;

									bonusContainer.style.left = `${Math.min(Math.max(x, 0), maxX)}px`;
									bonusContainer.style.top = `${Math.min(Math.max(y, 0), maxY)}px`;
								}
							});




							
							
							// Toggle bonus container visibility on button click
							document.getElementById('bonus').addEventListener('click', function() {
								var container = document.getElementById('bonusContainer');
								if (container.style.display === 'none') {
									container.style.display = 'block';
								} else {
									container.style.display = 'none';
								}
							});
							// Mouse up event to stop dragging
							document.addEventListener('mouseup', () => {
								if (isDragging) {
									isDragging = false;
									// Save the current position to local storage
									const position = {
										left: parseInt(bonusContainer.style.left),
										top: parseInt(bonusContainer.style.top),
									};
									localStorage.setItem('bonusContainerPosition', JSON.stringify(position));
								}
							});

							// Close button functionality
							document.getElementById("close-bonus").addEventListener("click", function () {
								bonusContainer.style.display = "none"; // Hide the container
							});







							$(document).ready(async function() {
									const savedSettings = localStorage.getItem('app_settings');
									if (savedSettings) {
										try {
											applyCashierSettingsToForm(JSON.parse(savedSettings));
										} catch (e) {
											console.error('Invalid app_settings in localStorage', e);
										}
									} else {
										const hiddenRounding = document.getElementById('income_rounding');
										applyIncomeRoundingFromSettings({
											income_rounding: hiddenRounding ? hiddenRounding.innerText.trim() : 'off'
										});
									}
									const incomeRoundingToggle = document.getElementById('settings_income_rounding');
									if (incomeRoundingToggle) {
										incomeRoundingToggle.addEventListener('change', syncIncomeRoundingToggleUi);
									}

									try {
										await fetchAndApplyCashierSettingsToForm();
									} catch (error) {
										console.error("Settings load failed:", error);
										showAlert("Failed to load settings. Please check console for details.", "danger");
									}
								});


								// Open settings
								document.getElementById("settings").addEventListener("click", async function(event) 
							   {
									event.stopPropagation();
									const settingsMenu = document.getElementById("settings-menu");
									settingsMenu.classList.add("active");

									try {
										await fetchAndApplyCashierSettingsToForm();
									} catch (error) {
										console.error("Settings load failed:", error);
										showAlert("Failed to load settings. Please check console for details.", "danger");
									}
								});

								
								// Close the settings menu when clicking outside
								document.addEventListener("click", function(event) {
									var settingsMenu = document.getElementById("settings-menu");
									var settingsButton = document.getElementById("settings");

									// Check if the click was outside the settings menu and button
									if (!settingsMenu.contains(event.target) && !settingsButton.contains(event.target)) {
										settingsMenu.classList.remove("active");
									}
								});

								// Close the settings menu when clicking the close button
								document.getElementById("close-menu").addEventListener("click", function(event) {
									event.stopPropagation(); // Prevent the click from propagating to document
									document.getElementById("settings-menu").classList.remove("active");
								});



									$("#submit_settings_form").on('click', function(event) 
									{
											event.preventDefault();

											var submitBtn = document.getElementById('submit_settings_form'); // or use `this`
											// mycheck_result = (inline block)
											submitBtn.disabled = true;
											submitBtn.innerText = 'Saving changs...';
											submitBtn.style.opacity = '0.6';
											submitBtn.style.cursor = 'not-allowed';

											// 1. Compile all settings into a single object
											const claimMode = $("#settings_bingo_claim_mode").val() || "no_restriction";
											const settings = {
													bonus: {
														status: $("#settings_set_bonus").val(),
														amount: $("#settings_bonus_amount").val(),
														per_day: $("#sittings_bonus_options").val()
													},
													system: {
														check_result: $("#settings_check_result").val(),
														color_mode: 'three',
														bingo_claim_mode: claimMode,
														bingo_claim_limit: claimMode === "no_restriction" ? -1 : 0,
														profit: $("#settings_cashier_profit").val(),
														good_bingo_sound: $("#settings_good_bingo_sound").val(),
														income_rounding: $("#settings_income_rounding").is(":checked") ? "on" : "off"
													},
													toggles: {
														will_start: $("#will_start_sound_toggle").is(":checked"),
														started: $("#started_sound_toggle").is(":checked"),
														stopped: $("#stopped_sound_toggle").is(":checked"),
														show_card_count: $("#counte_registerd_card").is(":checked")
													}
												};

											// 2. Get cashier ID
											const cashier_id = localStorage.getItem("cashier_id");

											// 3. Make AJAX request
											$.ajax({
												type: 'POST',
												url: '../config/DbFunction.php',
												data: {
													action: 'update_settings_cashier_id',
													cashier_id: cashier_id,
													settings: JSON.stringify(settings) // Send as single JSON string
												},
												dataType: "json",
												timeout: 5000, // ⏰ 5 seconds timeout
												success: function(response) {
													const responseEl = $("#settings_update_response");
													
													if(response.status == 'success') {
														// Save ALL settings to localStorage at once
														localStorage.setItem('app_settings', JSON.stringify(settings));
														const colorEl = document.getElementById('color');
														if (colorEl) colorEl.textContent = 'three';
														applyIncomeRoundingFromSettings(settings.system);
														responseEl.html("በተሳካ ሁኔታ ተመዝግቧል!").css("color", "green");
													} else {
														responseEl.html("<i style='color:red;'>መመዝገብ አልተቻለም!</i>");
													}
													
													setTimeout(function() {
														submitBtn.disabled = false;
														submitBtn.innerText = 'Save Changes';
														submitBtn.style.opacity = '1';  // Reset opacity
														submitBtn.style.cursor = 'pointer';  // Reset cursor
														responseEl.empty();
														$("#settings-menu").removeClass("active");
													}, 2000);
												},
												error: function(jqXHR, textStatus, errorThrown) {
													submitBtn.disabled = false;
													submitBtn.innerText = 'Save Changes';
													submitBtn.style.opacity = '1';  // Reset opacity
													submitBtn.style.cursor = 'pointer';  // Reset cursor
													if (textStatus === "timeout") {
														console.error("Request timed out");
														showAlert("የ ኢንተርኔት ፍጥነት ችግር ነው እባክዎትን በድጋሚ ይሞክሩ.", "danger");
													} else {
														// Log detailed error information
														console.error('Error Details:');
														console.error('Status: ' + textStatus);
														console.error('Error Thrown: ' + errorThrown);
														console.error('Response Text: ' + jqXHR.responseText);
														showAlert( "An error occurred while updating the partner. Check console for details.'","danger");
													}
												}
											});
									});

								// Show/hide submenu based on bonus status
								document.getElementById('settings_set_bonus').addEventListener('change', function() {
								const submenu = document.querySelector('.bonus-submenu');
								if (this.value === 'on') {
									submenu.style.display = 'block';
								} else {
									submenu.style.display = 'none';
								}
								});

								// Validate bonus amount input
								document.getElementById('settings_bonus_amount').addEventListener('change', function() {
								if (this.value < 20) this.value = 20;
								if (this.value > 300) this.value = 300;
								});
						</script>
				</div>





				<script>
						const fullscreenBtn = document.getElementById('fullscreenBtn');

					// Function to update the SVG icon based on fullscreen state
					function updateFullscreenIcon(isFullscreen) {
						fullscreenBtn.innerHTML = isFullscreen ? `
							<svg width="16" height="16" fill="#ffffff" class="bi bi-fullscreen-exit" viewBox="0 0 16 16">
								<path d="M5.5 0a.5.5 0 0 1 .5.5v4A1.5 1.5 0 0 1 4.5 6h-4a.5.5 0 0 1 0-1h4a.5.5 0 0 0 .5-.5v-4a.5.5 0 0 1 .5-.5m5 0a.5.5 0 0 1 .5.5v4a.5.5 0 0 0 .5.5h4a.5.5 0 0 1 0 1h-4A1.5 1.5 0 0 1 10 4.5v-4a.5.5 0 0 1 .5-.5M0 10.5a.5.5 0 0 1 .5-.5h4A1.5 1.5 0 0 1 6 11.5v4a.5.5 0 0 1-1 0v-4a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 1-.5-.5m10 1a1.5 1.5 0 0 1 1.5-1.5h4a.5.5 0 0 1 0 1h-4a.5.5 0 0 0-.5.5v4a.5.5 0 0 1-1 0z"/>
							</svg>
						` : `
							<svg width="16" height="16" fill="#ffffff" class="bi bi-fullscreen" viewBox="0 0 16 16">
								<path d="M1.5 1a.5.5 0 0 0-.5.5v4a.5.5 0 0 1-1 0v-4A1.5 1.5 0 0 1 1.5 0h4a.5.5 0 0 1 0 1zM10 .5a.5.5 0 0 1 .5-.5h4A1.5 1.5 0 0 1 16 1.5v4a.5.5 0 0 1-1 0v-4a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 1-.5-.5M.5 10a.5.5 0 0 1 .5.5v4a.5.5 0 0 0 .5.5h4a.5.5 0 0 1 0 1h-4A1.5 1.5 0 0 1 0 14.5v-4a.5.5 0 0 1 .5-.5m15 0a.5.5 0 0 1 .5.5v4a1.5 1.5 0 0 1-1.5 1.5h-4a.5.5 0 0 1 0-1h4a.5.5 0 0 0 .5-.5v-4a.5.5 0 0 1 .5-.5"/>
						`;
					}

					// Check if the page is already in fullscreen mode on load
					if (document.fullscreenElement) {
						updateFullscreenIcon(true); // Set icon to exit fullscreen
					}

					// Event listener for the fullscreen button
					fullscreenBtn.addEventListener('click', function() {
						if (!document.fullscreenElement) {
							document.documentElement.requestFullscreen().then(() => {
								updateFullscreenIcon(true); // Update icon to exit fullscreen
							}).catch((err) => {
								alert(`Error attempting to enable fullscreen mode: ${err.message}`);
							});
						} else {
							document.exitFullscreen().then(() => {
								updateFullscreenIcon(false); // Update icon to enter fullscreen
							});
						}
					});

					// Update the button icon on exiting fullscreen mode
					document.addEventListener('fullscreenchange', () => {
						const isFullscreen = !!document.fullscreenElement;
						updateFullscreenIcon(isFullscreen); // Update icon based on fullscreen state
					});

			    </script>





				<div id="main-content" class="main-content">


				<div id="myModal" class="modal fade" data-keyboard="false" data-backdrop="static" style="display:none;overflow-y:auto;">
												<div class="modal-dialog">
													<div class="modal-content" style="width: 600px; height: 400px; opacity: 0.9;">



													<div class="modal-header">
														<h2 id="modal-round-number">Round														                                 														                                  <?php echo $round_number; ?></h2>
														<div class="hidden-info">

														</div>
														<div class="button-group">
															<button class="modal-button" id="report_button" >Report</button> &nbsp;
															<button class="modal-button" id="logoutbtn">Logout</button>
															<button id="register_game_button" class="modal-button-register"><h3>Register Card</h3></button>
														</div>

														<script>
															document.getElementById('report_button').onclick = function() {
																setTimeout(function() {
																	window.location.href = "../cashier/report.php";
																}, 100);
															};

															document.getElementById('register_game_button').onclick = function() {
																setTimeout(function() {
																	window.location.href = "../cashier/reg_new_game.php";
																}, 100);
															};



														</script>
													</div>

														<div class="modal-body" style="background-color: #f6f7f9;" >
															<h2 id="amount">

																ኢትዮ-ማርክ ቢንጎ
															</h2>
															<div style="min-height:300px;margin: 0px;">

															    <?php

                                                                    if ($new_bonus_status == "off") {

                                                                        echo '<img id="selected-numbers-container-img" src="../assets/images/card1.png" id="img" style="user-drag: none; -webkit-user-drag: none; width: 70%; max-height: 400px;">';
                                                                    } else {
                                                                        echo '<img id="selected-numbers-container-img" src="../assets/images/bonus-removebg.png" id="img" style="user-drag: none; -webkit-user-drag: none; width: 70%; max-height: 400px;">';
                                                                    }
                                                                ?>



																 <!--Container for selected numbers -->
																<div id="selected-numbers-container"
																	style="background: rgba(255, 255, 255, 0.8); padding: 10px; border-radius: 5px; display:none; max-height:300px;overflow-y:auto; ">
																	<h2>የተመዘገቡ ካርድ ቁጥሮች</h2>
																	<div id="selected-numbers" style="font-size: 24px; color: #000;" ></div>
																</div>

															</div>

															<!-- <h1 id="amount" style="font-weight: bold; letter-spacing: 2px; font-size: 60px; text-align: center; color: #828282;">ቦነስ 200 ብር </h1>
															<h1 id="amount" style="font-weight: bold; letter-spacing: 2px; fon
															t-size: 60px; text-align: center; color: #828282;">
																ቦነስ 200 ብር
															</h1> -->
															<?php
                                                                if ($cashier_id) {
                                                                    // Directly using the $cashier_id in the query
                                                                    $query = "
                                                                            SELECT * FROM `cashier` WHERE `cashier_id` = '$cashier_id';
                                                                        ";

                                                                    // Execute the query
                                                                    $result = $conn->query($query);

                                                                    // Check if the query was successful
                                                                    if ($result) {
                                                                        // Fetch the result as an associative array
                                                                        $row = $result->fetch_assoc();

                                                                        // Check if the cashier package is found
                                                                        if ($row) {
                                                                            $cashier_package = $row['cashier_package'];
                                                                        } else {
                                                                            $cashier_package = "No package available for this cashier.";
                                                                        }
                                                                    } else {
                                                                        $cashier_package = "Error executing query.";
                                                                    }
                                                                } else {
                                                                    $cashier_package = "Cashier ID not provided.";
                                                                }

																// $newCashierPackage = base64_encode(openssl_encrypt(10000, 'AES-256-CBC', ENCRYPTION_KEY, 0, ENCRYPTION_IV));
            													$cashier_package = decrypt_cashier_package($cashier_package);
                                                            ?>

                                                                        <style>
                                                                            @keyframes blink {
                                                                                0% { opacity: 1; }
                                                                                50% { opacity: 0; }
                                                                                100% { opacity: 1; }
                                                                            }
                                                                        </style>



                                                                        <!-- Bala Alert Message -->
                                                                        <p id="bala_alert" style="color:red; animation: blink 2s infinite;">
                                                                            <?php if ($cashier_package <= 1000) {echo 'ሒሳበዎ እያለቀ ነው! <i style="color:green;">' . htmlspecialchars($cashier_package) . " ብር</i>";}?>
                                                                        </p>

																 <button  type="submit" class="exe modal-start-btn snake-border" id="mybtn" onclick="return startbingo();">Start</button>

														</div>
													</div>
												</div>
											</div> <!--mymodal -->


							<div class="container" style="margin-left:5px;">
								<div class="row">
								     <div id="col-11"></div>
								     <div id="col-2" class="col-2">
												<div class="contains">
													<div class="ball2">
														<div class="ball3">
															<div class="ball4">
																<div class="ball5">
																	<!-- Bewzew -->
																	<p class="num" id="rand"></p>
																</div>
															</div>
														</div>
													</div>
												</div> <!--contains -->
									 </div>




									<div  id="col-4" class="col-4">
											<p class="lastcall">Recent Results for (<a  href="#" style="color: red;text-align:center;font-size:25px;font-weight: 900;" id="round_number_bellow_5">yyyyy</a>)</p>

											<div class="tgable-container">
												<table id="bingo-table">
													<tr>
														<td class='bingo-call' style="color:red;" t='0'></td>
														<td class='bingo-call' t='1'></td>
														<td class='bingo-call' t='2'></td>
														<td class='bingo-call' t='3'></td>
														<td class='bingo-call' t='4'></td>
													</tr>
												</table>
											</div>  <!--table container -->
									</div>

									<div class="col-3">
										<div class="derash-box">
											<!-- Content -->
											<div class="derash-content">
												<span class="amount">
													<span id="amount1"></span> <span>&nbsp;ደራሽ</span>
												</span>
											</div>

											<!-- Line -->
											<span class="derash-line">-</span>

											<br><br>

											<!-- Details List -->
											<div class="derash-details">
											<span class="total-card" id="cardCounter">ብዛት : <?php echo $sew; ?></span> &nbsp;&nbsp;&nbsp;&nbsp;
											<span class="total-calls">ጥሪ : <span id="drawn_number_counter">0</span></span>
											</div>
										</div>
									</div>
									<script>
											document.addEventListener("DOMContentLoaded", function () 
											{
												const savedSettings = localStorage.getItem('app_settings');
												if (savedSettings) 
												{
													const settings = JSON.parse(savedSettings);
													if(!settings.toggles.show_card_count)
													{
														const checkbox = document.getElementById("counte_registerd_card");
														cardCounter.style.display = "none"; // Hide the entire element
													}
													else{
														cardCounter.style.display = "inline"; // Show if checked
													}
													
												}
											});
									</script>



								</div>

										<br><br>

								<div class="row" >
									<div class="col-12" >
										<div class="brow">
											<div class="callb">
												<p class="txtbox" style='background-color: #ff0404;'>B</p>
												<div class='numrow'><p class='numbox' numb='1'>1</p></div>
												<div class='numrow'><p class='numbox' numb='2'>2</p></div>
												<div class='numrow'><p class='numbox' numb='3'>3</p></div>
												<div class='numrow'><p class='numbox' numb='4'>4</p></div>
												<div class='numrow'><p class='numbox' numb='5'>5</p></div>
												<div class='numrow'><p class='numbox' numb='6'>6</p></div>
												<div class='numrow'><p class='numbox' numb='7'>7</p></div>
												<div class='numrow'><p class='numbox' numb='8'>8</p></div>
												<div class='numrow'><p class='numbox' numb='9'>9</p></div>
												<div class='numrow'><p class='numbox' numb='10'>10</p></div>
												<div class='numrow'><p class='numbox' numb='11'>11</p></div>
												<div class='numrow'><p class='numbox' numb='12'>12</p></div>
												<div class='numrow'><p class='numbox' numb='13'>13</p></div>
												<div class='numrow'><p class='numbox' numb='14'>14</p></div>
												<div class='numrow'><p class='numbox' numb='15'>15</p></div>
											</div>
										</div>

										<div class="irow">
											<div class="callb">
												<p class="txtbox" style='background-color: #0c3d75;'>I</p>
												<div class='numrow'><p class='numbox' numi='16'>16</p></div>
												<div class='numrow'><p class='numbox' numi='17'>17</p></div>
												<div class='numrow'><p class='numbox' numi='18'>18</p></div>
												<div class='numrow'><p class='numbox' numi='19'>19</p></div>
												<div class='numrow'><p class='numbox' numi='20'>20</p></div>
												<div class='numrow'><p class='numbox' numi='21'>21</p></div>
												<div class='numrow'><p class='numbox' numi='22'>22</p></div>
												<div class='numrow'><p class='numbox' numi='23'>23</p></div>
												<div class='numrow'><p class='numbox' numi='24'>24</p></div>
												<div class='numrow'><p class='numbox' numi='25'>25</p></div>
												<div class='numrow'><p class='numbox' numi='26'>26</p></div>
												<div class='numrow'><p class='numbox' numi='27'>27</p></div>
												<div class='numrow'><p class='numbox' numi='28'>28</p></div>
												<div class='numrow'><p class='numbox' numi='29'>29</p></div>
												<div class='numrow'><p class='numbox' numi='30'>30</p></div>
											</div>
										</div>

										<div class="irow">
											<div class="callb">
												<p class="txtbox" style='background-color: #ffffff; color: rgb(15, 185, 0);'>N</p>
												<div class='numrow'><p class='numbox' numn='31'>31</p></div>
												<div class='numrow'><p class='numbox' numn='32'>32</p></div>
												<div class='numrow'><p class='numbox' numn='33'>33</p></div>
												<div class='numrow'><p class='numbox' numn='34'>34</p></div>
												<div class='numrow'><p class='numbox' numn='35'>35</p></div>
												<div class='numrow'><p class='numbox' numn='36'>36</p></div>
												<div class='numrow'><p class='numbox' numn='37'>37</p></div>
												<div class='numrow'><p class='numbox' numn='38'>38</p></div>
												<div class='numrow'><p class='numbox' numn='39'>39</p></div>
												<div class='numrow'><p class='numbox' numn='40'>40</p></div>
												<div class='numrow'><p class='numbox' numn='41'>41</p></div>
												<div class='numrow'><p class='numbox' numn='42'>42</p></div>
												<div class='numrow'><p class='numbox' numn='43'>43</p></div>
												<div class='numrow'><p class='numbox' numn='44'>44</p></div>
												<div class='numrow'><p class='numbox' numn='45'>45</p></div>
											</div>
										</div>

										<div class="irow">
											<div class="callb">
												<p class="txtbox" style='background-color: #dab71c; color: black;'>G</p>
												<div class='numrow'><p class='numbox' numg='46'>46</p></div>
												<div class='numrow'><p class='numbox' numg='47'>47</p></div>
												<div class='numrow'><p class='numbox' numg='48'>48</p></div>
												<div class='numrow'><p class='numbox' numg='49'>49</p></div>
												<div class='numrow'><p class='numbox' numg='50'>50</p></div>
												<div class='numrow'><p class='numbox' numg='51'>51</p></div>
												<div class='numrow'><p class='numbox' numg='52'>52</p></div>
												<div class='numrow'><p class='numbox' numg='53'>53</p></div>
												<div class='numrow'><p class='numbox' numg='54'>54</p></div>
												<div class='numrow'><p class='numbox' numg='55'>55</p></div>
												<div class='numrow'><p class='numbox' numg='56'>56</p></div>
												<div class='numrow'><p class='numbox' numg='57'>57</p></div>
												<div class='numrow'><p class='numbox' numg='58'>58</p></div>
												<div class='numrow'><p class='numbox' numg='59'>59</p></div>
												<div class='numrow'><p class='numbox' numg='60'>60</p></div>
											</div>
										</div>

										<div class="irow">
											<div class="callb">
												<p class="txtbox" style='background-color: rgb(10, 89, 31); color: white;'>O</p>
												<div class='numrow'><p class='numbox' numo='61'>61</p></div>
												<div class='numrow'><p class='numbox' numo='62'>62</p></div>
												<div class='numrow'><p class='numbox' numo='63'>63</p></div>
												<div class='numrow'><p class='numbox' numo='64'>64</p></div>
												<div class='numrow'><p class='numbox' numo='65'>65</p></div>
												<div class='numrow'><p class='numbox' numo='66'>66</p></div>
												<div class='numrow'><p class='numbox' numo='67'>67</p></div>
												<div class='numrow'><p class='numbox' numo='68'>68</p></div>
												<div class='numrow'><p class='numbox' numo='69'>69</p></div>
												<div class='numrow'><p class='numbox' numo='70'>70</p></div>
												<div class='numrow'><p class='numbox' numo='71'>71</p></div>
												<div class='numrow'><p class='numbox' numo='72'>72</p></div>
												<div class='numrow'><p class='numbox' numo='73'>73</p></div>
												<div class='numrow'><p class='numbox' numo='74'>74</p></div>
												<div class='numrow'><p class='numbox' numo='75'>75</p></div>
											</div>
										</div>
									</div><!--col-12 -->
								</div><!--row -->

								<div class= "row">
									<div class = "col-12">
											<!--bingo, bweze , language selection, playsound speed selection -->
													<div class="setting_box" style="display: flex; justify-content: center; align-items: center; width: 80%; margin: 20px auto;">


											        <button  style="border: 5px solid white;max-width:150px;" onclick="change()" id="bingoo" class="btnbingo">Bingo</button>

													<button  style="border: 5px solid white;max-width:150px;" id="shuffle" class="btnshuffle">Shuffle</button>
													<button  style="border: 5px solid red;max-width:150px;" id="finsh_game" class="btnbingo">Finsh</button>
													<div class="sound-input-text">
														<select id="voiceselect" class="voiceselect" onchange="change_language()">
														<option value="11" <?php echo $sound == 11 ? 'selected' : ''; ?>>New voice</option>
														<option value="12" <?php echo $sound == 12 ? 'selected' : ''; ?>>Bereket</option>
														<option hidden value="10" <?php echo $sound == 10 ? 'selected' : ''; ?>>Addis</option>
														<option hidden value="1"  <?php echo $sound == 1 ? 'selected' : ''; ?>>Bereket</option>
														<option hidden value="2"  <?php echo $sound == 2 ? 'selected' : ''; ?>>Nigus</option>
														<option value="3"  <?php echo $sound == 3 ? 'selected' : ''; ?>>Amharic Arada</option>
														<option hidden value="4"  <?php echo $sound == 4 ? 'selected' : ''; ?>>Amharic formal</option>
														<option hidden value="5"  <?php echo $sound == 5 ? 'selected' : ''; ?>>Amharic yordi</option>
														<option hidden value="6"  <?php echo $sound == 6 ? 'selected' : ''; ?>>Amharic Beti</option>
														<option value="7"  <?php echo $sound == 7 ? 'selected' : ''; ?>>Oromifa Female</option>
														<option value="8"  <?php echo $sound == 8 ? 'selected' : ''; ?>>Tigrigna Female</option>
														<option value="9"  <?php echo $sound == 9 ? 'selected' : ''; ?>>Tigrigna Male</option>
														</select>
													</div>


													<div class="check_card">
														<input type="text" placeholder="Card Number..." id="Ecard_no" class="card-input" required>
													</div>

													<button  style="border: 5px solid white;max-width:150px;"  type="submit" class="btnbingo" style="margin-left: 0px" id="mycheck">Check</button>
												</div><!--bingo, bweze , language selection, playsound speed selection -->


													<div class="row">
															<div class="col-1"> </div>
															<div class="col-3">


															</div>

															<div class="slidecontainer col-4" style="display:inline-block;">
																<p style="margin-bottom: -1.0rem; font-size: 32px; font-weight: 600;text-align:center;">
																	Play speed: <span id="demo"><?php echo $speed_range; ?></span>
																</p>
																<input type="range" min="1" max="15" value="<?php echo $speed_range; ?>" class="slider" id="myRange" style="height: 60px; letter-spacing: 1px; margin-top:-2.0rem;">

															</div>


															<div class="col-4"></div>
													</div>


												<canvas id="canvas" style="display:none;"></canvas>
												<script src="../bootstrap/js/confetti.browser.min.js"></script>
												<canvas id="canvas2" style="position: fixed; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; z-index: 2999; display: none;"></canvas>


												<div id="myModalcard" class="modal fade" data-keyboard="false" data-backdrop="static">
													<div class="modal-dialog">
														<div class="modal-content" >
															<div class="modal-header">
																<h1 class="modal-title"><span style="font-size: 20px;">Round																                                                            																                                                             <?php echo $round_number; ?></span> </h1>
																<center>
																<div  id ="claim-bonus-popup" class="claim-bonus-popup">
																	Claim Bonus
																</div>
																</center>
																<button class="modal-button" style="padding: 10px 15px; " id="addbingo">Close</button>
															</div>
															<div class="modal-body">
																<div id="modal-body"></div>


																<div style=" width: 100%;margin-top: 0px;">
																	<button class="modal-button" style="padding: 10px 15px; background: green; color:white;" id="goodbingo">GOOD BINGO</button>
																	<button class="modal-button" style="padding: 10px 15px; background-color: red;color:white;" id="notbingo">NOT BINGO</button>
																	<button class="modal-button" style="padding: 10px 15px; background-color: #f59e0b; color: #1a1a1a;" id="toolatebingo">ዘግይቷል — Too late</button>

																	<button class="modal-button" style="padding: 10px 15px; margin-left: 5px; background-color: yellow; color: black;" id="lock_card">Lock?</button>
																</div>
															</div><!--modal body -->
														</div><!--modal content -->
													</div><!--modal dialog -->
												</div><!--modal -->




												<div id="helpmodal" class="modal fade" style="overflow-y: scroll;" data-keyboard="false" data-backdrop="static">
													<div class="modal-dialog">
														<div class="modal-content" >
															<div class="modal-header">
																<h1 class="modal-title"><span style="font-size: 20px;">Ethiomark - ኢትዮ ማርክ </span> </h1>

																<button class="modal-button" style="padding: 10px 15px; " id="helpmodals">Close</button>
															</div>
															<div class="modal-body" >
																<div style="min-height:500px;">
																	<div class="box1f">
																	<h1>Sample Pattern</h1>
																	<table id="bingoTable">
																		<thead>
																			<tr>
																				<th>B</th>
																				<th>I</th>
																				<th>N</th>
																				<th>G</th>
																				<th>O</th>
																			</tr>
																		</thead>
																		<tbody>
																			<tr>
																				<td>1</td>
																				<td>16</td>
																				<td>31</td>
																				<td>46</td>
																				<td>61</td>
																			</tr>
																			<tr>
																				<td>2</td>
																				<td>17</td>
																				<td>32</td>
																				<td>47</td>
																				<td>62</td>
																			</tr>
																			<tr>
																				<td>3</td>
																				<td>18</td>
																				<td class="free-cell">★</td>
																				<td>48</td>
																				<td>63</td>
																			</tr>
																			<tr>
																				<td>4</td>
																				<td>19</td>
																				<td>34</td>
																				<td>49</td>
																				<td>64</td>
																			</tr>
																			<tr>
																				<td>5</td>
																				<td>20</td>
																				<td>35</td>
																				<td>50</td>
																				<td>65</td>
																			</tr>
																		</tbody>
																	</table>


																	<br><br>
																	<h1>New Pattern [ center corner ]</h1>
																	<img style="user-drag: none; -webkit-user-drag: none; min-height:500px" src="../assets/images/new_pattern.png" alt="">

																	</div>  <!--box1 -->
															</div>
															</div><!--modal body -->
														</div><!--modal content -->
													</div><!--modal dialog -->
												</div><!--modal -->


									</div>
								</div>

							</div>













				</div><!--main content body -->
		</div><!--user content body -->
























		<p id="wc" hidden><?php echo $winner_card; ?></p>
		<p id="fd" hidden><?php echo $first_draw; ?></p>






<script src="../bootstrap/js/jquery.js"></script>
<script src="../bootstrap/js/bootstrap.min.js"></script>
<script src="../bootstrap/js/congura.js"></script>



<script type="text/javascript" >


		// JavaScript to toggle the switch state
		const toggleButton = document.getElementById('toggleBTN');
		const toggleCircle = document.getElementById('toggleCircle');

		// Retrieve the initial state from localStorage, or set it to "off" if not found
		let isOn = localStorage.getItem('toggleState') === 'true';
		const col11 = document.getElementById("col-11");
		const col2 = document.getElementById("col-2");
		// const col3 = document.getElementById("col-3");
		const col4 = document.getElementById("col-4");
		// Check if the elements exist in the DOM before accessing their content
		if (!col2  || !col4) {
			console.error("One or more elements are not found in the DOM.");
		}
		function updateToggleAppearance()
		{
			if (isOn)
			{
				// Move the circle to the "on" position
				toggleCircle.style.left = '16px';

				// Dynamically change the stylesheets
				document.getElementById("lightStyleSheet").setAttribute("href", "../bootstrap/css/light/style.css");
				document.getElementById("modalStyleSheet").setAttribute("href", "../bootstrap/css/light/modal.css");
				document.getElementById("giftStyleSheet").setAttribute("href", "../bootstrap/css/light/gift-unboxing.css");
				document.getElementById("ballStyleSheet").setAttribute("href", "../bootstrap/css/light/ball.css");
				document.getElementById("bingoStyleSheet").setAttribute("href", "../bootstrap/css/light/bingon.css");

				col11.classList.add('col-1');

				col2.classList.remove('col-2');
				col2.classList.add('col-3');

				// col3.style.display = 'none';
				col4.classList.remove('col-4');
				col4.classList.add('col-5');

			} else {
				// Move the circle to the "off" position
				toggleCircle.style.left = '3px';

				// Revert to the default stylesheets
				document.getElementById("lightStyleSheet").setAttribute("href", "../bootstrap/css/style.css");
				document.getElementById("modalStyleSheet").setAttribute("href", "../bootstrap/css/modal.css");
				document.getElementById("giftStyleSheet").setAttribute("href", "../bootstrap/css/gift-unboxing.css");
				document.getElementById("ballStyleSheet").setAttribute("href", "../bootstrap/css/ball.css");
				document.getElementById("bingoStyleSheet").setAttribute("href", "../bootstrap/css/bingon.css");


				// col11.classList.remove('col-1');

				// col2.classList.remove('col-3');
				// col2.classList.add('col-2');

				// // col3.style.display = 'block';
				// col4.classList.remove('col-5');
				// col4.classList.add('col-4');
				col11.classList.add('col-1');

				col2.classList.remove('col-2');
				col2.classList.add('col-3');

				// col3.style.display = 'none';
				col4.classList.remove('col-4');
				col4.classList.add('col-5');


			}
		}
		// Initial update based on the stored state
		updateToggleAppearance();

		// Attach the event listener to the entire button
		toggleButton.addEventListener('click', () => {
			// Toggle the state
			isOn = !isOn;

			// Update the button appearance
			updateToggleAppearance();

			// Store the updated state in localStorage
			localStorage.setItem('toggleState', isOn);
		});

		// Simulate login check (replace this with real check)
		const isLoggedIn = localStorage.getItem('loggedin') === 'true';
		// DOM elements
		const userContent = document.getElementById('user-content');

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


		$("#finsh_game").on('click', function(event)
		{
			//complet game
			var round_number = parseInt(document.getElementById('round').innerText);
			var cashier_id = localStorage.getItem("cashier_id");
			$.ajax({
					type: 'POST',
					url: '../config/DbFunction.php',
					data: {
						game_completed:"true",
						round_number: round_number,
						cashier_id: cashier_id
					},
					dataType: "json",
					success: function(response)
					{
						if (response.status === 'success') {
							// Handle success case
							showAlert( "Game has finshed ","success");
							setTimeout(function() {
								window.location.href = "../cashier/reg_new_game.php";
							}, 1000);
						} else {
								// Create modal HTML
								const modal = document.createElement('div');
								modal.id = 'customConfirmModal';
								modal.innerHTML = `
									<div style="position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); display:flex; align-items:center; justify-content:center; z-index:9999;">
										<div style="background:#fff; padding:20px; border-radius:8px; max-width:400px; text-align:center; box-shadow: 0 2px 10px rgba(0,0,0,0.3);">
											<h3>መልዕክት</h3>
											<p>ምንም አይነት ጥሪ አልጠራም፡፡ <br>ስለዚህ ይህንን ጨዋታ መጨረስ ከፈለጉ ጨዋታዉን ያስጀምሩት!</p>
											<div style="margin-top: 15px;">
												<button id="cancelBtn" style="font-size: 17px; margin-right: 10px; padding: 8px 16px; background-color: #2ecc71; color: white; border: none; border-radius: 4px; cursor: pointer;">
													እሺ
												</button>
												<button hidden id="confirmBtn" style="font-size: 20px; padding: 8px 16px; background-color: #2ecc71; color: white; border: none; border-radius: 4px; cursor: pointer;">
													አዎ, finish
												</button>
											</div>

										</div>
									</div>
								`;
								
								// Append to body
								document.body.appendChild(modal);

								// Handle button events
								document.getElementById('cancelBtn').addEventListener('click', function() {
									modal.remove();
								});

								document.getElementById('confirmBtn').addEventListener('click', function() {
									window.location.href = "../cashier/reg_new_game.php";
								});

								// Optional: Console message
								console.error('Error Game completed:', response.message);
							}

					},
					error: function(jqXHR, textStatus, errorThrown) {
						// Log detailed error information
						console.error('Error Details:');
						console.error('Status: ' + textStatus);
						console.error('Error Thrown: ' + errorThrown);
						console.error('Response Text: ' + jqXHR.responseText);
						showAlert( "An error occurred. Check console for details.'","danger");
					}
				});

		});



		$("#lock_card").on('click', function(event)
		{
			event.preventDefault();
			voices("locked_card.mp3");

			//lock or remove user cartela
			var round_number = parseInt(document.getElementById('round').innerText);
			var cartela_number= document.getElementById('Ecard_no').value;
			var cashier_id = localStorage.getItem("cashier_id");

			$.ajax({
					type: 'POST',
					url: '../config/DbFunction.php',
					data:
					{
						block_user_cartela: cartela_number,
						round_number: round_number,
						cashier_id: cashier_id
					},
					dataType: "json",
					success: function(response)
					{
						if (response.status === 'success') {
							// Handle success case
							showAlert("Successfully blocked!", "success");
						}
 						else {
							showAlert( response.message,"danger");
							// Handle error case
							// console.error('Error to blocked user !:', response.message);
						}
					},
					error: function(jqXHR, textStatus, errorThrown) {
						// Log detailed error information
						console.error('Error Details:');
						console.error('Status: ' + textStatus);
						console.error('Error Thrown: ' + errorThrown);
						console.error('Response Text: ' + jqXHR.responseText);
						showAlert( "An error occurred. Check console for details.'","danger");
					}
				});

		});


    var btn=document.getElementById('mybtn');/* start button id */
	var n=document.getElementById('sew').innerText;
	var s=document.getElementById('birr').innerText;
	var b=document.getElementById('bala').innerText;

	var profit=document.getElementById('profit').innerText;
	var start_get_mony_from = document.getElementById("start_get_mony_from").innerText;

	function getCommissionFromJson(n, s, tiers) 
	{
		if (!Array.isArray(tiers)) return null;

		for (let tier of tiers) {
			if (
				n >= tier.min && 
				(n <= tier.max || tier.max === undefined)
			) {

				console.log("===============================================\n");
				console.log("Sew", n);
				console.log("Santim", s);
				console.log("Dr", n*s);
				console.log("tier.min", tier.min);
				console.log("tier.max", tier.max);
				console.log("tier.percent", tier.percent);
				console.log("Commission percent ",  (tier.percent/ 100));
				console.log("\n===============================================\n");
				
				commission = tier.percent / 100;
				if((n*s)<=120){ 
					commission = 9/100;
					console.log("Drrrrrr is bellow 100 so commission = ",  9);
				 }
				
				return commission;
			}
		}
		return null;
	}

	let profit_json_raw = document.getElementById("profit_json").innerText;
	let partner_id = document.getElementById("partner_id").innerText;
	let partner_settings_json_status =  document.getElementById("partner_settings_json_status").innerText;
	let profit_json = null;
	if (profit_json_raw) {
		try { profit_json = JSON.parse(profit_json_raw);  } catch (e) {
			console.error("Invalid JSON:", e);
		}
	}	

	var roundedTotal = 0;
	var dr = n * s; // Total sale
	
	//fir miki  add partner id here
	if(( partner_settings_json_status == "on" ) && profit_json && Array.isArray(profit_json.commission_tiers))
	{	
		console.log("===============================================\n");
		console.log("===============================================\n");
		console.log("=======STARTING CALCULATIONS WITH STEP ONE=====\n");
		console.log("===============================================\n");
		console.log("===============================================\n");	
		if(n!=0 && s!=0 && b>0){ btn.disabled=false; }
		else{ btn.disabled=true; }
		
		
		var total = n * s * 0.2; // Initial calculation assuming dr < 320
		const commission = getCommissionFromJson(n, s, profit_json.commission_tiers);

		if (commission !== null) {
			total =  n * s * commission;
			console.warn("Commission tier matched, good work Total =  ", total);
		} else {
			console.warn("Commission tier not matched, falling back to default one for Dr = ", dr);
			if (dr >120 && dr < 320) {
				total = n * s * 0.2;
			} else if (dr >= 320 && dr < 800) {
				total = n * s * 0.22;
			} else if (dr >= 800 && dr < 1000) {
				total = n * s * 0.25;
			} else if (dr >= 1000) {
				total = n * s * 0.3;
			}
		}


		if(n!=0 && s!=0 && b>0)
		{
			
			roundedTotal = roundNetIncomeTotal(total);

			var start_get_mony_from = document.getElementById("start_get_mony_from").innerText;
			if (dr< start_get_mony_from) {
				document.getElementById('amount').innerText=(dr)+" ብር ወሳጅ";
				document.getElementById('amount1').innerText=(dr);
			}
			else{
				document.getElementById('amount').innerText=(dr-roundedTotal)+" ብር ወሳጅ";
				document.getElementById('amount1').innerText=(dr-roundedTotal);
				// console.log(n*s+"    ",start_get_mony_from);
			}
		}
	}
	//==0 means auto
	else if(profit==0)
	{
		console.log("===============================================\n");
		console.log("===============================================\n");
		console.log("==STARTING CALCULATIONS WITH STEP TWO [Default]=\n");
		if(n!=0 && s!=0 && b>0){ btn.disabled=false; }
		else{ btn.disabled=true; }

		// Calculate the total amount
		var total = n * s * 0.2; // Initial calculation assuming dr < 320
		var income=n*s;
		// Determine the discount rate based on the total sale (dr)
		var dr = n * s; // Total sale

		// Determine the discount rate based on the total sale (dr)
		if (dr >120 && dr < 320) {
			total = n * s * 0.2;
			console.log("=============== SELECTED "+ 20 +" ====================\n");
			console.log("===============================================\n");
		} else if (dr >= 320 && dr < 800) {
			total = n * s * 0.22;
			console.log("=============== SELECTED "+ 22 +" ====================\n");
			console.log("===============================================\n");
		} else if (dr >= 800 && dr < 1000) {
			total = n * s * 0.25;
			console.log("=============== SELECTED "+ 25 +" ====================\n");
			console.log("===============================================\n");
		} else if (dr >= 1000) {
			total = n * s * 0.3;
			console.log("=============== SELECTED "+ 30 +" ====================\n");
			console.log("===============================================\n");
		}
		if(n!=0 && s!=0 && b>0)
		{

			            var roundedTotal = roundNetIncomeTotal(total);

			if (income< start_get_mony_from) {
				document.getElementById('amount').innerText=(income)+" ብር ወሳጅ";
				document.getElementById('amount1').innerText=(income);
			}
			else{
				document.getElementById('amount').innerText=(income-roundedTotal)+" ብር ወሳጅ";
				document.getElementById('amount1').innerText=(income-roundedTotal);
				// console.log(n*s+"    ",start_get_mony_from);
			}

		}

	}
	else
	{
		console.log("===============================================\n");
		console.log("===============================================\n");
		console.log("STARTING CALCULATIONS WITH STEP THREE [Custome: "+profit+"]\n");
		console.log("===============================================\n");
		console.log("===============================================\n");
		if(n!=0 && s!=0 && b>0){
				btn.disabled=false;
			}
		else{
			btn.disabled=true;
		}
		var total = n * s * profit/100; // Initial calculation assuming dr < 320
		var income=n*s;
		if(n!=0 && s!=0 && b>0)
		{
			var roundedTotal = roundNetIncomeTotal(total);

			var start_get_mony_from = document.getElementById("start_get_mony_from").innerText;
			if (income< start_get_mony_from) {
				document.getElementById('amount').innerText=(income)+" ብር ወሳጅ";
				document.getElementById('amount1').innerText=(income);
			}
			else{
				document.getElementById('amount').innerText=(income-roundedTotal)+" ብር ወሳጅ";
				document.getElementById('amount1').innerText=(income-roundedTotal);
				// console.log(n*s+"    ",start_get_mony_from);
			}
		}

	}

	function applyCashierSettingsToForm(settings) {
		if (!settings) return;
		const setBonusEl = document.getElementById("settings_set_bonus");
		const bonusAmountEl = document.getElementById("settings_bonus_amount");
		const bonusOptionsEl = document.getElementById("sittings_bonus_options");
		const bonusSubMenu = document.querySelector(".bonus-submenu");

		if (setBonusEl) setBonusEl.value = settings.bonus?.status || "off";
		if (bonusAmountEl) bonusAmountEl.value = settings.bonus?.amount || "20";
		if (bonusOptionsEl) bonusOptionsEl.value = settings.bonus?.per_day || "1";
		if (bonusSubMenu) {
			bonusSubMenu.style.display = settings.bonus?.status === "on" ? "block" : "none";
		}

		const checkResultEl = document.getElementById("settings_check_result");
		const profitEl = document.getElementById("settings_cashier_profit");
		const soundEl = document.getElementById("settings_good_bingo_sound");

		if (checkResultEl) checkResultEl.value = settings.system?.check_result || "auto";
		if (profitEl) profitEl.value = settings.system?.profit || "10";
		if (soundEl) soundEl.value = settings.system?.good_bingo_sound || "default";
		applyBingoClaimModeFromSettings(settings.system);
		applyIncomeRoundingFromSettings(settings.system);

		$("#will_start_sound_toggle").prop("checked", settings.toggles?.will_start ?? true);
		$("#started_sound_toggle").prop("checked", settings.toggles?.started ?? true);
		$("#stopped_sound_toggle").prop("checked", settings.toggles?.stopped ?? true);
		$("#counte_registerd_card").prop("checked", settings.toggles?.show_card_count ?? true);
	}

	async function fetchAndApplyCashierSettingsToForm() {
		const cashierId = localStorage.getItem("cashier_id");
		const response = await fetch('../config/DbFunction.php', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/x-www-form-urlencoded',
			},
			body: `get_cashier_data=${cashierId}`
		});

		if (!response.ok) {
			throw new Error(`HTTP error! status: ${response.status}`);
		}

		const responseText = await response.text();
		if (!responseText.trim()) {
			throw new Error("Empty server response");
		}

		const parsedData = JSON.parse(responseText);
		if (!Array.isArray(parsedData)) {
			throw new Error("Expected array in response");
		}

		const cashierData = parsedData[0];
		if (!cashierData?.settings_json) {
			throw new Error("No settings_json found in response");
		}

		const settings = JSON.parse(cashierData.settings_json);
		applyCashierSettingsToForm(settings);
		return settings;
	}

	function resolveBingoClaimMode(system) {
		if (!system) return 'no_restriction';
		const raw = (system.bingo_claim_mode || '').toString().trim().toLowerCase();
		if (raw === 'allow_later_patterns' || raw === 'allow_new_patterns') return 'allow_later_patterns';
		if (raw === 'disqualify_on_miss' || raw === 'strict') return 'disqualify_on_miss';
		if (raw === 'no_restriction' || raw === 'off' || raw === 'instant') return 'no_restriction';
		if (raw) return 'no_restriction';
		const limit = parseInt(system.bingo_claim_limit, 10);
		return (isNaN(limit) || limit < 0) ? 'no_restriction' : 'disqualify_on_miss';
	}

	function applyBingoClaimModeFromSettings(system) {
		const el = document.getElementById('settings_bingo_claim_mode');
		if (el) el.value = resolveBingoClaimMode(system);
	}

	function isPartnerIncomeRoundingLocked() {
		const lockEl = document.getElementById('lock_round_up_last_digit');
		return lockEl && String(lockEl.innerText).trim() === '1';
	}

	function shouldRoundNetIncome() {
		const roundingEl = document.getElementById('income_rounding');
		const on = roundingEl && String(roundingEl.innerText).trim() === 'on';
		return on && !isPartnerIncomeRoundingLocked();
	}

	function roundNetIncomeTotal(total) {
		if (!shouldRoundNetIncome()) {
			return total;
		}
		const lastDigit = total % 10;
		const roundedLastDigit = lastDigit > 5 ? 10 : 0;
		let roundedTotal = total - lastDigit + roundedLastDigit;
		if (roundedTotal < 10 && total <= 10) {
			roundedTotal = 10;
		}
		return roundedTotal;
	}

	function applyIncomeRoundingFromSettings(system) {
		const toggle = document.getElementById('settings_income_rounding');
		const stateEl = document.getElementById('settings_income_rounding_state');
		const hidden = document.getElementById('income_rounding');
		const hint = document.getElementById('settings_income_rounding_hint');
		const locked = isPartnerIncomeRoundingLocked();
		const wantOn = system && system.income_rounding === 'on';
		const effectiveOn = wantOn && !locked;
		if (hidden) {
			hidden.innerText = effectiveOn ? 'on' : 'off';
		}
		if (toggle) {
			toggle.checked = effectiveOn;
			toggle.disabled = locked;
		}
		if (stateEl) {
			stateEl.textContent = effectiveOn ? 'ON' : 'OFF';
		}
		if (hint) {
			hint.style.display = locked ? 'block' : 'none';
		}
	}

	function syncIncomeRoundingToggleUi() {
		const toggle = document.getElementById('settings_income_rounding');
		const stateEl = document.getElementById('settings_income_rounding_state');
		const hidden = document.getElementById('income_rounding');
		if (!toggle || toggle.disabled) {
			return;
		}
		if (stateEl) {
			stateEl.textContent = toggle.checked ? 'ON' : 'OFF';
		}
		if (hidden) {
			hidden.innerText = toggle.checked ? 'on' : 'off';
		}
	}

	function getActiveBingoClaimMode() {
		const fromSelect = $("#settings_bingo_claim_mode").val();
		if (fromSelect) return fromSelect;
		try {
			const saved = JSON.parse(localStorage.getItem('app_settings') || '{}');
			return resolveBingoClaimMode(saved.system);
		} catch (e) {
			return 'no_restriction';
		}
	}

	function lockCheckedCartela(cartelaNumber, roundNumber, cashierId) {
		return $.ajax({
			type: 'POST',
			url: '../config/DbFunction.php',
			data: {
				block_user_cartela: cartelaNumber,
				round_number: roundNumber,
				cashier_id: cashierId
			},
			dataType: 'json',
			timeout: 8000
		});
	}

    $("#mycheck").on('click', function(event)
	{
		var cardNumber = parseInt(document.getElementById('Ecard_no').value);
		var round = parseInt(document.getElementById('round').innerText);
		var round_num = parseInt(document.getElementById('round').innerText);
		var cashier_id = localStorage.getItem("cashier_id");
		var new_bonus_status = document.getElementById('new_bonus_status').innerText;		
		var submitBtn = document.getElementById('mycheck'); // or use `this`
		// mycheck_result = (inline block)
		submitBtn.disabled = true;
		submitBtn.innerText = 'Wait...';
		submitBtn.style.opacity = '0.6';
		submitBtn.style.cursor = 'not-allowed';

		// checkCardLockedStatus(cardNumber,round,cashier_id);
		$.ajax({
				type: 'POST',
				url: '../cashier/fetch_result_data.php',
				data: {
					chack_card:"true",
					card_no: cardNumber,
					round: round_num,
					cashier_id: cashier_id,
					new_bonus_status: new_bonus_status,
					bingo_claim_mode: getActiveBingoClaimMode()
					},
				timeout: 5000, // ⏰ 5 seconds timeout
				success: function(resp)
				{

    				if (resp.status === "success") 
					{
						console.log("Expected : ",resp.expected_pattern, "What we get is : ",resp.count_winning_line);
						
						submitBtn.disabled = false;
						submitBtn.innerText = 'Check';
						submitBtn.style.opacity = '1';  // Reset opacity
						submitBtn.style.cursor = 'pointer';  // Reset cursor

						if(resp.is_locked == "yes" )
						{
							showAlert("ያስገቡት ካርድ የተቆለፈ ነው ", "danger");
							voices("locked_card.mp3");
						}
						else if(resp.message=="No data found.")
						{
							var selectvoice=document.getElementById("voiceselect").value;
							voices("notreg.wav");
						}
						else
						{
							window.lastCardCheckResp = resp;
							event.preventDefault();
							$('#modal-body').html(resp.message);
							$('#myModalcard').modal('show', {backdrop: 'static', keyboard: false});


							let auto_check_result = $("#settings_check_result").val() || document.getElementById("auto_check_result")?.textContent.trim() || "manual";
							let drawn_number_counter = document.getElementById("drawn_number_counter").innerText;
							let special_bonus_element = document.getElementById("special_bonus_data");
							let claim_bonus_btn = document.getElementById('claim-bonus-popup');

							// Get the selected voice
							var good_bingo_sound = $("#settings_good_bingo_sound").val() || document.getElementById("good_bingo_sound").innerText;

							let special_bonus_data = special_bonus_element.innerText.trim();
        					let bonusNumbersArray = special_bonus_data.split(',').map(num => num.trim());

							let isLastCalledInBonus = bonusNumbersArray.includes(String(resp.last_called));
							var new_bonus_status = document.getElementById('new_bonus_status').innerText;
							
							


							if(auto_check_result==="auto" )
							{
								document.getElementById('notbingo')?.style.setProperty('display', 'none', 'important');
								document.getElementById('goodbingo')?.style.setProperty('display', 'none', 'important');
								document.getElementById('toolatebingo')?.style.setProperty('display', 'none', 'important');

								if (resp.win_status==1 && (resp.count_winning_line >= resp.expected_pattern))
								{

									// to get bonus all the pattern must be gon
									if (isLastCalledInBonus && resp.is_new_bonus_available=="yes" && resp.new_bonus_status=="0")
										{
											if (drawn_number_counter < 50 && new_bonus_status=="on") {
												claim_bonus_btn.style.display = 'inline-block';
											} else {
												showAlert("<h1> ጥሪ "+drawn_number_counter+"</h1> የቦነስ ተጠቃሚ አይደሉም ምክንያቱም <br> ጥሪው ከ 50 አልፏል! ","danger")
											}

										}
										else
										{
											claim_bonus_btn.style.display = 'none';
										}

									celebrate();
									setTimeout(() => { celebrate(); }, 300);
									setTimeout(() => { celebrate(); },600);
									// Show the canvas and disable pointer events
									var element = document.getElementById('canvas');
									element.style.display = 'block';
									element.style.pointerEvents = 'none';
									element.style.zIndex = '9999'; // Ensure it appears on top of everything
									element.style.position = 'absolute'; // Ensure z-index works properly

									// Determine the audio file to play
									var audioFile = "good.wav";
										switch (good_bingo_sound) {
										case "0":
											audioFile = "good.wav";
											break;
										case "1":
											audioFile = "clapping.mp3";
											break;
										case "2":
											audioFile = "goodbingo.mp3";
											break;
										}
									// Play the selected voice
									voices(audioFile);

									// Save checked number if it is winning number here.
									$.ajax({
										type: 'POST',
										url: '../config/DbFunction.php',  // Correct if your path is right
										data: {
											save_checked_number: true,   // A flag to know which action to run
											checked_card_no: cardNumber,
											checked_round: round_num,
											checked_cashier_id: cashier_id,
											checked_number: resp.last_called  // send the last winning number
										},
										success: function(saveResp) {
											console.log("Saved checked number: ", saveResp);
										},
										error: function(jqXHR, textStatus, errorThrown) {
											console.error('Save checked number error:', textStatus, errorThrown);
										}
									});


									// Hide the canvas after 2 seconds
									setTimeout(() => {
										element.style.display = 'none';
									}, 3000);
								} else if (resp.is_late_claim === true || resp.is_late_claim === 1 || resp.is_late_claim === '1') {
									if (resp.locks_on_late_claim === true || resp.locks_on_late_claim === 1 || resp.locks_on_late_claim === '1') {
										lockCheckedCartela(cardNumber, round_num, cashier_id).always(function() {
											voices("locked_card.mp3");
										});
									} else {
										voices("late.mp3");
									}
								} else {
									voices("notgood.wav");
								}
							}
							else{
								document.getElementById('notbingo')?.style.setProperty('display', 'inline-block', 'important');
								document.getElementById('goodbingo')?.style.setProperty('display', 'inline-block', 'important');
								document.getElementById('toolatebingo')?.style.setProperty('display', 'inline-block', 'important');

								if (isLastCalledInBonus && resp.is_new_bonus_available=="yes" && resp.new_bonus_status=="0")
								{
									if (drawn_number_counter < 50 && new_bonus_status=="on") {
										claim_bonus_btn.style.display = 'inline-block';
									} else {
										showAlert("<h1> ጥሪ "+drawn_number_counter+"</h1> የቦነስ ተጠቃሚ አይደሉም ምክንያቱም <br> ጥሪው ከ 50 አልፏል! ","danger")
									}

								}
								else
								{
									claim_bonus_btn.style.display = 'none';
								}
							}

						}
					} else {
						submitBtn.disabled = false;
						submitBtn.innerText = 'Check';
						submitBtn.style.opacity = '1';  // Reset opacity
						submitBtn.style.cursor = 'pointer';  // Reset cursor

						// Log detailed error information
						console.log(resp);
						showAlert( "የ ኢንተርኔት ስህተት አጋጥሟል .'","danger");
					}

				},
				error: function(jqXHR, textStatus, errorThrown) {
					submitBtn.disabled = false;
					submitBtn.innerText = 'Check';
					submitBtn.style.opacity = '1';  // Reset opacity
					submitBtn.style.cursor = 'pointer';  // Reset cursor
					if (textStatus === "timeout") {
						console.error("Request timed out");
						showAlert("የ ኢንተርኔት ፍጥነት ችግር ነው እባክዎትን በድጋሚ ይሞክሩ.", "danger");
					} else {
						// Log detailed error information
						console.error('Error Details:');
						console.error('Status: ' + textStatus);
						console.error('Error Thrown: ' + errorThrown);
						console.error('Response Text: ' + jqXHR.responseText);
						showAlert( "An error occurred while updating the partner. Check console for details.'","danger");
					}
				}

			});

    });

	// check result manually
	$(document).ready(function()
	{

			var closeButtonClicked = false;

			$("#goodbingo").on('click', function(event) {
			// Show the canvas and disable pointer events
			var element = document.getElementById('canvas');
			element.style.display = 'block';
			element.style.pointerEvents = 'none';

			element.style.zIndex = '9999'; // Ensure it appears on top of everything
			element.style.position = 'absolute'; // Ensure z-index works properly

			// Get the selected voice
			var good_bingo_sound = $("#settings_good_bingo_sound").val() || document.getElementById("good_bingo_sound").innerText;

			// Determine the audio file to play
			// Determine the audio file to play
			var audioFile = "good.wav";
			switch (good_bingo_sound) {
				case "0":
					audioFile = "good.wav";
					break;
				case "1":
					audioFile = "clapping.mp3";
					break;
				case "2":
					audioFile = "goodbingo.mp3";
					break;
			}

			// Play the selected voice
			voices(audioFile);
			celebrate();
			setTimeout(() => { celebrate(); }, 300);
			setTimeout(() => { celebrate(); },600);

			// Hide the canvas after 2 seconds
			setTimeout(() => {
				element.style.display = 'none';
			}, 2000);
		});

			$("#notbingo").on('click', function (event) 
			{

					event.preventDefault();
					closeButtonClicked = true;
					var selectvoice=document.getElementById("voiceselect").value;
				  if(selectvoice==4){
						// audio = new Audio('../assets/sound/notgood.wav');
						// audio.preload = 'auto'; // Preload the audio
						// audio.play();
						voices("notgood.wav");

				  }else{
						// audio = new Audio('../assets/sound/notgood.wav');
						// audio.preload = 'auto'; // Preload the audio
						// audio.play();
						voices("notgood.wav");

				  }
			});

			$("#toolatebingo").on('click', function (event) {
				event.preventDefault();
				closeButtonClicked = true;
				const resp = window.lastCardCheckResp;
				if (resp && (resp.locks_on_late_claim === true || resp.locks_on_late_claim === 1 || resp.locks_on_late_claim === '1')) {
					const round = parseInt(document.getElementById('round').innerText, 10);
					const cartela = document.getElementById('Ecard_no').value;
					const cashierId = localStorage.getItem("cashier_id");
					lockCheckedCartela(cartela, round, cashierId).always(function() {
						voices("locked_card.mp3");
					});
				} else {
					voices("late.mp3");
				}
			});



			$("#claim-bonus-popup").on('click', function(event)
			{

				var round = parseInt(document.getElementById('round').innerText);
				var cashier_id = localStorage.getItem("cashier_id");
				var new_bonus_amount = document.getElementById("new_bonus_amount").innerText;

				$.ajax({
					type: 'POST',
					url: '../config/DbFunction.php', // New PHP file to handle this
					data: {
						claim_new_bonus_round: round,
						cashier_id: cashier_id,
						new_bonus_amount: new_bonus_amount
					},
					success: function(response) {
						if (response.status=="success")
						{
							showAlert(response.message, "success");
							$("#claim-bonus-popup")
								.html("✔ Verified")  // Change text
								.attr("disabled", "disabled")  // Ensure it's disabled
								.css({
									"background-color": "#4CAF50 !important",  // Green background (force with !important)
									"color": "#fff",                          // White text
									"border-radius": "50px",                  // Circular look
									"padding": "10px 20px",
									"font-weight": "bold",
									"cursor": "not-allowed",                  // Show disabled cursor
									"opacity": "0.6"                          // Make it look disabled
								});

						} else
						{
							showAlert(response.message, "danger");
						}
					},
					error: function(jqXHR, textStatus, errorThrown) {
						console.error('Error on claimed bonus:');
						console.error('Status: ' + textStatus);
						console.error('Error Thrown: ' + errorThrown);
						console.error('Response Text: ' + jqXHR.responseText);
					}
				});
			});

			$("#helps").on('click', function (event) {
				event.preventDefault();
				updatePattern();
				$('#helpmodal').modal('show', {backdrop: 'static', keyboard: false});

			});

			// Close modal with custom button
			$("#helpmodals").on('click', function () {
				$('#helpmodal').modal('hide');
			});


			$("#addbingo").on('click', function (event) {
				event.preventDefault();
				closeButtonClicked = true;
				$('#myModalcard').modal('hide');

			});
			

			$('#myModalcard').on('hide.bs.modal', function (e) {
				if (!closeButtonClicked) {
					e.preventDefault();
					e.stopPropagation();
					return false;
				}
				closeButtonClicked = true;
			});

			$(document).on('click', function (event) {
				const modal = $('#myModalcard');
				const modalContent = modal.find('.modal-content');

				// Check if the modal is visible and the clicked target is NOT inside the modal
				if (modal.is(':visible') && !$(event.target).closest('#myModalcard .modal-content').length) {
					closeButtonClicked = true;
					modal.modal('hide');
				}
			});


			$('#myModal').modal('show', {backdrop: 'static', keyboard: false});



			var closeButtonClicked = false;
			$("#mybtn").on('click', function (event) {

				    // audio = new Audio('../assets/sound/lijemr_new.mp3');
					// audio.preload = 'auto'; // Preload the audio
					// audio.play();
					
					if ($("#will_start_sound_toggle").is(":checked")) {
						voices("lijemr_new.mp3");
					}

					

				event.preventDefault();
				closeButtonClicked = true;
				$('#myModal').modal('hide');
			 });

			$('#myModal').on('hide.bs.modal', function (e) {
				if (!closeButtonClicked) {
					e.preventDefault();
					e.stopPropagation();
					return false;
				}
				closeButtonClicked = false;
			});


	});


	let shuffleInterval;
	let shuffle_status = null;
	let audioCache = {}; // Object to store cached audio objects
	let isAudio1Playing = false;
	let isAudio2Playing = false;



		$("#shuffle").on("dblclick", function () {
			clearInterval(shuffleInterval);
			$(this).prop("disabled", false);
		});

		$("#shuffle").on("click", function () {
			if (shuffle_status === null) {
				// Start shuffling
				clearInterval(shuffleInterval);
				shuffleInterval = setInterval(shuffle, 50);

				shuffle_status = "true";
				$(this).prop("disabled", false).text("STOP");

				// Play startup sound and track it
				const startupSound = voices("StartupSound.opus");
				if (startupSound) activeAudios.push(startupSound);

				// Play shuffle sound and track it
				const shuffleSound = voices("shuffle.wav");
				if (shuffleSound) activeAudios.push(shuffleSound);

				// Stop sounds and shuffling after 8 seconds
				setTimeout(() => stopShuffleSounds(), 8000);
			} else {
				stopShuffleSounds(); // Stop immediately
			}
		});

		function stopShuffleSounds() {
			clearInterval(shuffleInterval);
			shuffle_status = null;
			$("#shuffle").prop("disabled", false).text("Shuffle");

			activeAudios.forEach((audio) => {
				if (audio instanceof Audio) {
					audio.pause();
					audio.currentTime = 0; // Reset playback position
				} else {
					console.warn("Invalid audio object in activeAudios:", audio);
				}
			});

			activeAudios = []; // Clear the active audio list
		}





	function shuffle()
	{
		  const randomNumber = getRandomNumber1();
		  let letter = 'O';
		  if (randomNumber <= 15) {
			letter = 'B';
		  } else if (randomNumber <= 30) {
			letter = 'I';
		  } else if (randomNumber <= 45) {
			letter = 'N';
		  } else if (randomNumber <= 60) {
			letter = 'G';
		  }

		  const element = bingoUiCache.numCells[randomNumber];
		if (element)
		{
			if (bingoUiCache.randEl) {
				bingoUiCache.randEl.innerText = `${letter}-${randomNumber}`;
			}
			element.classList.add("callnum1");

			// Remove the class after 300ms
			setTimeout(() => {
			  element.classList.remove("callnum1");
			}, 500);
		}
	}

	// Function to get a random number
	function getRandomNumber1() {
	  return Math.floor(Math.random() * 75) + 1; // Range from 1 to 75
	}

	function change_language()
	{

		const selectvoice = document.getElementById("voiceselect").value;
		const cashier_id=localStorage.getItem("cashier_id");
		$.ajax({
				type: 'POST',
				url: '../config/DbFunction.php',
				data: { selectvoice:selectvoice,cashier_id:cashier_id},
				dataType: 'JSON',
				success: function(resp) {
					if(resp.status=="success")
					{
						preloadSelectedVoicePack(parseInt(selectvoice, 10)).catch((err) => {
							console.error('Voice pack preload error:', err);
						});
					}
					else{
						console.log(resp.message, "danger")
					}
				},
				error: function(xhr, status, error) {
					// Handle errors if the AJAX request fails
					console.error("AJAX Error: ", xhr.responseText);
					showAlert(error.message, "danger")
				}

			});
	}

	//audio============
	// const dbPromise = idb.openDB('audio-cache-db', 1, {
	// 	upgrade(db) {
	// 		db.createObjectStore('audios');
	// 	}
	// });


	// async function storeAudio(url, blob) {
	// 	const db = await dbPromise;
	// 	const tx = db.transaction('audios', 'readwrite');
	// 	tx.store.put(blob, url);
	// 	await tx.done;
	// }


	// async function getAudio(url) {
	// 	const db = await dbPromise;
	// 	return db.get('audios', url);
	// }


	// async function playAudio(voicePath) {
	// 	const audioUrl =voicePath;
	// 	let blob = await getAudio(audioUrl);

	// 	if (!blob) {
	// 		try {
	// 			const response = await fetch(audioUrl);
	// 			if (!response.ok) throw new Error('Network response was not ok');
	// 			blob = await response.blob();
	// 			await storeAudio(audioUrl, blob);
	// 		} catch (error) {
	// 			console.error('Failed to fetch audio file:', error);
	// 			return;
	// 		}
	// 	}

	// 	const audio = new Audio(URL.createObjectURL(blob));
	// 	audio.preload = 'auto';
	// 	audio.play().catch(error => console.error('Error playing audio:', error));
	// }

	// function voices(rb)
	// {

	// 	const selectvoice = document.getElementById("voiceselect").value;
	// 	const cashier_id=localStorage.getItem("cashier_id");
	// 	console.log("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCc");

	// 	$.ajax({
	// 			type: 'POST',
	// 			url: '../config/DbFunction.php',
	// 			data: { selectvoice:selectvoice,cashier_id:cashier_id},
	// 			dataType: 'JSON',
	// 			success: function(resp) {
	// 				if(resp.status=="success")
	// 				{
	// 					//console.log(resp.message, "success")
	// 				}
	// 				else{
	// 					console.log(resp.message, "danger")
	// 				}
	// 			},
	// 			error: function(xhr, status, error) {
	// 				// Handle errors if the AJAX request fails
	// 				console.error("AJAX Error: ", xhr.responseText);
	// 				showAlert(error.message, "danger")
	// 			}

	// 		});
	// 	// $.ajax({
	// 	// 	type: 'POST',
	// 	// 	url: 'backend/play_lang.php',
	// 	// 	data: { selectvoice:selectvoice},
	// 	// 	success: function(html) { }
	// 	// });
	// 	const voiceFiles = [
	// 		'1.wav', '2.wav', '3.wav', '4.wav', '5.wav', '6.wav', '7.wav', '8.wav', '9.wav', '10.wav',
	// 		'11.wav', '12.wav', '13.wav', '14.wav', '15.wav', '16.wav', '17.wav', '18.wav', '19.wav',
	// 		'20.wav', '21.wav', '22.wav', '23.wav', '24.wav', '25.wav', '26.wav', '27.wav', '28.wav',
	// 		'29.wav', '30.wav', '31.wav', '32.wav', '33.wav', '34.wav', '35.wav', '36.wav', '37.wav',
	// 		'38.wav', '39.wav', '40.wav', '41.wav', '42.wav', '43.wav', '44.wav', '45.wav', '46.wav',
	// 		'47.wav', '48.wav', '49.wav', '50.wav', '51.wav', '52.wav', '53.wav', '54.wav', '55.wav',
	// 		'56.wav', '57.wav', '58.wav', '59.wav', '60.wav', '61.wav', '62.wav', '63.wav', '64.wav',
	// 		'65.wav', '66.wav', '67.wav', '68.wav', '69.wav', '70.wav', '71.wav', '72.wav', '73.wav',
	// 		'74.wav', '75.wav'
	// 	];
	// 	const directories = [
	// 		'../assets/sound/voice/','../assets/sound/nigus/', '../assets/sound/modern-arada/', '../assets/sound/modern-formal/', '../assets/sound/fana/', '../assets/sound/famharic/', '../assets/sound/foromifa/', '../assets/sound/gual/', '../assets/sound/wedi/', '../assets/sound/addis/'
	// 	];

	// 	const path = directories[selectvoice - 1];
	// 	const voiceFile = voiceFiles[rb - 1];

	// 	if (path && voiceFile) {
	// 		playAudio(path + voiceFile);
	// 	} else {
	// 		console.error('Invalid voice selection or file index');
	// 	}
	// }




	var randomNumber;
	var uniqueRandoms = [];
	var max = 75;


	// Get special bonus data
	let special_bonus_element = document.getElementById("special_bonus_data");
	let special_bonus_data = special_bonus_element.innerText.trim();
	let special_bonus_numbers = special_bonus_data.split(',').map(num => parseInt(num, 10)); // Parse special_bonus_numbers
	var new_bonus_status = document.getElementById('new_bonus_status').innerText;

	var todays_new_bonus_count = document.getElementById('todays_new_bonus_count').innerText;
	var max_new_bonus_per_day = document.getElementById('max_new_bonus_per_day').innerText;

	var n=document.getElementById('sew').innerText;
	var s=document.getElementById('birr').innerText;







	let c_round_number = parseInt(document.getElementById('round').innerText.trim(), 10);
	let fd = document.getElementById('fd').innerText.trim();
    let wc = document.getElementById('wc').innerText.trim().replace(/[\n\r\s]+/g, '');


	///////////////////////////////////////////////////////////////
		let wc_sets = wc.split('*').map(set => set.trim()).filter(set => set.length > 0);
		let selected_block = wc_sets.find(set => {
			let first_number = parseInt(set.split(',')[0].trim(), 10);
			return first_number === c_round_number;
		});

		if (selected_block) {
			wc = selected_block;
		} else {
			wc = "";
		}

	///////////////////////////////////////////////////////////////


	let wc_parts = wc.split(',');
	let wc_round = parseInt(wc_parts[0], 10);

	let wc_priorityNumbers = c_round_number === wc_round
		? wc_parts.slice(1).map(num => parseInt(num, 10))
		: [];



	// BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
	if (wc_priorityNumbers.length < 1) {
		if (fd) {
			wc_priorityNumbers = fd ? fd.split(',').map(num => parseInt(num, 10)) : [];

		}
	}
	// console.log("lasttttfd", fd);
	// console.log("lasttttttwc", wc_priorityNumbers);
	// Log the outputs
	// console.log("Round max_new_bonus_per_day:", max_new_bonus_per_day);
	// console.log("todays_new_bonus_count:", todays_new_bonus_count);






	// Overlap Handling: Remove overlapping numbers between wc_priorityNumbers and special_bonus_numbers
	wc_priorityNumbers = wc_priorityNumbers.filter(num => !special_bonus_numbers.includes(num));


	// XXXXXXXXXXXXXXXXXXXXXXXXXX
	//    always make it of and only numbers removed from special_bonus_numbers will be winner
	// XXXXXXXXXXXXXXXXXXXXXXXXX


	new_bonus_status = "off";
    if (n*s<=99) {
		new_bonus_status = "off";
		const randomIndex = Math.floor(Math.random() * special_bonus_numbers.length);
		special_bonus_numbers.splice(randomIndex, 0); // Removes the random number

		console.log('n*s:', s*n);
	}
	else if (todays_new_bonus_count >= max_new_bonus_per_day) {
		new_bonus_status = "off";
		const randomIndex = Math.floor(Math.random() * special_bonus_numbers.length);
		special_bonus_numbers.splice(randomIndex, 0); // Removes the random number
		console.log('todays claim:', todays_new_bonus_count);
	}
	else{
		console.log('Ready to claim:', todays_new_bonus_count);
		const randomIndex = Math.floor(Math.random() * special_bonus_numbers.length);
		special_bonus_numbers.splice(randomIndex, 2); // Removes the random number if wenremove all of the 5 no cjance to win
	}



	// Shuffle function for randomization
	function shuffleArray(array) {
		for (let i = array.length - 1; i > 0; i--) {
			const j = Math.floor(Math.random() * (i + 1));
			[array[i], array[j]] = [array[j], array[i]];
		}
	}


	// Populate uniqueRandoms array if it's empty
	if (!uniqueRandoms.length) {
		for (let i = 1; i <= max; i++) {
			if (new_bonus_status === "off") {
				// Exclude numbers in wc_priorityNumbers  and special_bonus_numbers
				if (!wc_priorityNumbers.includes(i) && !special_bonus_numbers.includes(i)) {
					uniqueRandoms.push(i);
				}
			}
			else{
					// Exclude numbers in wc_priorityNumbers
					if (!wc_priorityNumbers.includes(i)) {
					uniqueRandoms.push(i);
				}
			}
		}
		shuffleArray(uniqueRandoms); // Shuffle the array initially
	}


	 console.log(" =="+special_bonus_numbers.length + "  "+ new_bonus_status, special_bonus_numbers);
	//  console.log("wc_priorityNumbers =="+wc_priorityNumbers.length, wc_priorityNumbers);
	//  console.log("uniqueRandoms =="+uniqueRandoms.length, uniqueRandoms);

	// Function to get a random number with priority handling
	function getRandomNumber() {
				// Draw from priority numbers first
				if (wc_priorityNumbers.length > 0) {
				let priorityNumber = wc_priorityNumbers.shift();
				return priorityNumber;
			}

			// Draw from the remaining numbers (excluding special_bonus_numbers if new_bonus_status is "off")
			if (uniqueRandoms.length > 0) {
				return uniqueRandoms.pop();
			}

			// If no more numbers are left and new_bonus_status is "off", draw from special_bonus_numbers
			if (new_bonus_status === "off" && special_bonus_numbers.length > 0) {
				return special_bonus_numbers.shift();
			}

			// If all numbers are exhausted, return null or handle accordingly
			return;
	}

	let randomstring = "";

	function highlightDrawnNumber(randomNumber) {
		const cell = bingoUiCache.numCells[randomNumber];
		if (cell) {
			cell.classList.add('callnum');
		}
		let letter = 'O';
		if (randomNumber <= 15) {
			letter = 'B';
		} else if (randomNumber <= 30) {
			letter = 'I';
		} else if (randomNumber <= 45) {
			letter = 'N';
		} else if (randomNumber <= 60) {
			letter = 'G';
		}
		if (bingoUiCache.randEl) {
			bingoUiCache.randEl.innerText = letter + '-' + randomNumber;
		}
	}

	function randomnuber() {
		let randomstringArray = randomstring.split(',').filter(value => value !== 'undefined');
		let validRandomstring = randomstringArray.join(',');
		let is_last_drawn = validRandomstring.slice(0, -1).split(',').filter(Boolean).length;
		let drawnCount = randomstringArray.length;

		if (bingoUiCache.drawnCounterEl) {
			bingoUiCache.drawnCounterEl.innerText = drawnCount;
		}

		if (is_last_drawn === 75) {
			change();
		}

		let randomNumber = getRandomNumber();
		voices(randomNumber);
		updateTable(randomNumber);
		randomstring = randomstring + randomNumber + ",";
		if (bingoUiCache.ranVoiceEl) {
			bingoUiCache.ranVoiceEl.innerText = randomNumber;
		}
		highlightDrawnNumber(randomNumber);
	}














	function functionC() {


	 randomnuber();

	  max=max-1;

	}
	var slider = document.getElementById("myRange");
	var output = document.getElementById("demo");

	output.innerHTML = slider.value;
	var cashier_sound_range_value;
	cashier_id= localStorage.getItem('cashier_id');

	var sliderSaveTimer = null;
	slider.oninput = function() {
		output.innerHTML = this.value;
		cashier_sound_range_value = this.value;
		if (sliderSaveTimer) {
			clearTimeout(sliderSaveTimer);
		}
		sliderSaveTimer = setTimeout(function() {
			$.ajax({
				type: 'POST',
				url: '../config/DbFunction.php',
				data: { cashier_sound_range_value: cashier_sound_range_value, cashier_id: cashier_id},
				dataType: 'JSON',
				success: function(resp) {
					if(resp.status=="success")
					{
						showAlert(resp.message, "success")
					}
					else{
						showAlert(resp.message, "danger")
					}
				},
				error: function(xhr, status, error) {
					console.error("AJAX Error: ", xhr.responseText);
					showAlert(error.message, "danger")
				}
			});
		}, 400);
	}

	var light = null;
	var btn=document.getElementById('bingoo');

	//clicked bingo and stop
	function change()
	{
			var slider = document.getElementById("myRange").value;

			if (light === null) {
				if ($("#started_sound_toggle").is(":checked")) {
					voices("start.mp3");
				}

				 btn.style.backgroundColor = '#4CAF50';
				 btn.innerHTML="STOP";
				 bingoGameActive = true;
				 light = setInterval(functionC,slider*1000);

				document.getElementById("shuffle").disabled=true;
				document.getElementById("shuffle").style.color = "#888888";
				document.getElementById("shuffle").style.background = "#444";

				document.getElementById("finsh_game").disabled=true;
				document.getElementById("finsh_game").style.color = "#888888";
				document.getElementById("finsh_game").style.background = "#444";

				document.getElementById("mycheck").disabled=true;
				document.getElementById("mycheck").style.color = "#888888";
				document.getElementById("mycheck").style.background = "#444";
			} else
			{
				document.getElementById("finsh_game").disabled=false;
				document.getElementById("finsh_game").style.color = "";
				document.getElementById("finsh_game").style.background = "";

				document.getElementById("mycheck").disabled=false;
				document.getElementById("mycheck").style.color = "";
				document.getElementById("mycheck").style.background = "";

				if ($("#stopped_sound_toggle").is(":checked")) {
					voices("stop.mp3");
				}

				btn.style.backgroundColor = '#1976D2';
				btn.innerHTML="Bingo";
				window.clearInterval(light);
				light = null;
				bingoGameActive = false;


				// Split the string into an array
				let randomstringArray = randomstring.split(',').filter(value => value !== 'undefined');

				// Join the filtered array back into a string
				let validRandomstring = randomstringArray.join(',');

				if (validRandomstring !== "" && /\d/.test(validRandomstring))
				{

					var round = document.getElementById('round').innerText;
					var cashier_id =localStorage.getItem("cashier_id");
					
					// Disable the button and change its appearance
					const saveBtn = document.getElementById("bingoo"); // your save button's ID

					saveBtn.disabled = true;
					saveBtn.innerText = "Saving..."; // You can also use innerHTML = '<span>Saving...</span>' for richer visuals
					saveBtn.style.opacity = "0.6";
					saveBtn.style.cursor = "not-allowed";

					function completedSaving() {
						// Enable button and restore content
						saveBtn.disabled = false;
						saveBtn.innerHTML = "Bingo";
						saveBtn.style.opacity = "1";
						saveBtn.style.cursor = "pointer";
					}
					function disableSaveButton()
					{
						saveBtn.disabled = true;
						saveBtn.innerText = "Saving..."; // You can also use innerHTML = '<span>Saving...</span>' for richer visuals
						saveBtn.style.opacity = "0.6";
						saveBtn.style.cursor = "not-allowed";
					}

					// Function to submit data
					function submitData(retry = false) {
						disableSaveButton();

						$.ajax({
							type: 'POST',
							url: '../config/DbFunction.php',
							data: {
								result: validRandomstring,
								round: round,
								cashier_id: cashier_id,
							},
							dataType: 'JSON',
							timeout: 5000,
							success: function(resp) {
								if (resp.status == "success") {
									if (resp.status == "success") { showAlert("✅", "success"); } else { console.log(resp.message, "danger"); }
								} else {
									console.log(resp.message, "danger");
									showAlert("የ ኢንተርኔት ችግር!", "danger");
								}
								completedSaving();
							},
							error: function(jqXHR, textStatus, errorThrown) 
							{
								completedSaving();

								if (textStatus === "timeout") {

								}
									// Create modal container
									const modal = document.createElement("div");
									modal.id = "retryModal";
									modal.style = `
										position: fixed; top: 0; left: 0; width: 100%; height: 100%;
										background: rgba(0,0,0,0.5); z-index: 9999;
										display: flex; justify-content: center; align-items: center;
									`;

									// Create modal content
									modal.innerHTML = `
										<div style="background: #fff; padding: 20px; border-radius: 10px; width: 90%; max-width: 300px; text-align: center; box-shadow: 0 4px 12px rgba(0,0,0,0.3);">
											<h3 style="margin-bottom: 10px; font-size: 25px;">የ ኢንተርኔት ፍጥነት ችግር</h3>
											<p style="margin-bottom: 20px;">ሪዛልቱ አልተመዘገበም በድጋሚ ማስገባት ይፈልጋሉ?</p>
											<button id="retryBtn" style="font-size: 20px;padding: 8px 16px; background-color: #27ae60; color: white; border: none; border-radius: 4px; margin-right: 10px; cursor: pointer;">አዎ እፈልጋለሁ</button>
											<button id="cancelBtn" style="font-size: 20px;padding: 8px 16px; background-color: #e74c3c; color: white; border: none; border-radius: 4px; cursor: pointer;">አይ አልፈልግም </button>
										</div>
									`;

									document.body.appendChild(modal);

									// Button handlers
									document.getElementById("retryBtn").onclick = function () {
										modal.remove();
										submitData(); // Replace with your retry function
									};
									document.getElementById("cancelBtn").onclick = function () {
										modal.remove();
										showAlert("❌ ማስገባት ተሰርዟል።", "danger");
									};
							}

						});
					}
					// Call the function
					submitData();
			  }
			}
	}

	// Function to update the interval dynamically when the slider value changes
	document.getElementById("myRange").addEventListener("input", function() {
		if (light !== null) {
			// Clear the current interval
			window.clearInterval(light);

			// Restart the interval with the new slider value
			let slider = this.value;
			console.log("Updated slider value:", slider);
			light = setInterval(functionC, slider * 1000);
		}
	});
	function updateTable(a)
	{
			if (!bingoCallCells) {
				const table = document.getElementById('bingo-table');
				bingoCallCells = table ? table.getElementsByClassName('bingo-call') : [];
			}
			const cells = bingoCallCells;
			if (!cells.length) {
				return;
			}

			// Shift the numbers in the top row to the right
			for (let i = cells.length - 1; i > 0; i--) {
				cells[i].textContent = cells[i - 1].textContent;
				cells[i].setAttribute('t', cells[i - 1].getAttribute('t'));
			}

			// Place the most recent number in cell (0,0)

			cells[0].textContent = a;
			cells[0].setAttribute('t', a);
	}
   
			function patternCombinations(n, k) {
				const result = [];
				const chosen = [];
				function pick(start) {
					if (chosen.length === k) {
						result.push([...chosen]);
						return;
					}
					for (let i = start; i < n; i++) {
						chosen.push(i);
						pick(i + 1);
						chosen.pop();
					}
				}
				pick(0);
				return result;
			}

			function buildPatternAnimationSteps() {
				const singles = [];
				for (let c = 1; c <= 5; c++) singles.push([c]);
				for (let r = 6; r <= 10; r++) singles.push([r]);
				singles.push([19], [20], [21], [22]);

				const comboSteps = (k) => patternCombinations(singles.length, k).map((combo) =>
					combo.flatMap((i) => singles[i])
				);

				return {
					'1': singles,
					'2': comboSteps(2),
					'3': comboSteps(3),
					'4': [[14]],
					'5': [[11]],
					'6': [[13]],
					'7': [[18]],
					'8': [[1], [2], [3], [4], [5]],
					'9': [[6], [7], [8], [9], [10]],
					'10': [[12]],
					'11': [[15]],
					'12': [[16]],
					'13': [[17]],
					'14': singles,
				};
			}

			const allPatterns = buildPatternAnimationSteps();

        let currentPatternSet = 0;
        let patternGroup = '1'; // Default to 'any line' initially
        let patternIndex = 0;
        let intervalId;



		// Global object to store the cell values once set
			const bingoContent = {};

			function clearCircles() {
				const tableBody = document.querySelector('#bingoTable tbody');
				for (let rowIndex = 0; rowIndex < tableBody.rows.length; rowIndex++) {
					for (let cellIndex = 0; cellIndex < tableBody.rows[rowIndex].cells.length; cellIndex++) {
						const cell = tableBody.rows[rowIndex].cells[cellIndex];
						const cellId = `${rowIndex}-${cellIndex}`; // Unique ID for each cell

						// Clear the highlight class and reset any styles
						cell.classList.remove('highlighted');
						cell.removeAttribute('style');

						// Check if the content has already been set
						if (!bingoContent[cellId]) {
							// If not set, set the content
							if (rowIndex === 2 && cellIndex === 2) {
								// Center cell: set star
								cell.innerHTML = '★';
								bingoContent[cellId] = '★'; // Save to prevent future change
							} else {
								// Random content for other cells (numbers in this case)
								const randomContent = Math.floor(Math.random() * 100); // Random number between 0-99
								cell.innerHTML = randomContent;
								bingoContent[cellId] = randomContent; // Save the random number
							}
						} else {
							// If content is already set, just use the stored value
							cell.innerHTML = bingoContent[cellId];
						}
					}
				}
			}




			function drawPattern(patterns) {
				const table = document.getElementById('bingoTable');
				const tableBody = table.querySelector('tbody'); // Target tbody to avoid affecting the thead
				clearCircles();

				patterns.forEach(pattern => {
					switch (pattern) {
						case 1:
						case 2:
						case 3:
						case 4:
						case 5:
							let columnIndex = pattern - 1;
							for (let i = 0; i < 5; i++) {
								const cell = tableBody.rows[i].cells[columnIndex];
								cell.innerHTML = '<div class="circle"></div>';
								cell.classList.add('highlighted'); // Highlight cell
							}
							break;
						case 6: // Horizontal lines
						case 7:
						case 8:
						case 9:
						case 10:
							let rowIndex = pattern - 6;
							for (let i = 0; i < 5; i++) {
								const cell = tableBody.rows[rowIndex].cells[i];
								cell.innerHTML = '<div class="circle"></div>';
								cell.classList.add('highlighted'); // Highlight cell
							}
							break;
						case 11: // T pattern (top row + N column)
							for (let i = 0; i < 5; i++) {
								tableBody.rows[0].cells[i].innerHTML = '<div class="circle"></div>';
								tableBody.rows[0].cells[i].classList.add('highlighted');
								tableBody.rows[i].cells[2].innerHTML = '<div class="circle"></div>';
								tableBody.rows[i].cells[2].classList.add('highlighted');
							}
							break;
						case 12: // Reverse T pattern
							for (let i = 0; i < 5; i++) {
								tableBody.rows[4].cells[i].innerHTML = '<div class="circle"></div>'; // Horizontal line in last row
								tableBody.rows[4].cells[i].classList.add('highlighted');
								tableBody.rows[i].cells[2].innerHTML = '<div class="circle"></div>'; // Vertical line in middle column
								tableBody.rows[i].cells[2].classList.add('highlighted');
							}
							break;
						case 13: // X pattern
							for (let i = 0; i < 5; i++) {
								tableBody.rows[i].cells[i].innerHTML = '<div class="circle"></div>'; // Diagonal from top-left to bottom-right
								tableBody.rows[i].cells[i].classList.add('highlighted');
								tableBody.rows[i].cells[4 - i].innerHTML = '<div class="circle"></div>'; // Diagonal from top-right to bottom-left
								tableBody.rows[i].cells[4 - i].classList.add('highlighted');
							}
							break;
						case 14: // L pattern
							for (let i = 0; i < 5; i++) {
								tableBody.rows[i].cells[0].innerHTML = '<div class="circle"></div>'; // Vertical line in first column
								tableBody.rows[i].cells[0].classList.add('highlighted');
							}
							for (let i = 0; i < 5; i++) {
								tableBody.rows[4].cells[i].innerHTML = '<div class="circle"></div>'; // Horizontal line in last row
								tableBody.rows[4].cells[i].classList.add('highlighted');
							}
							break;
						case 15: // Reverse L pattern
							for (let i = 0; i < 5; i++) {
								tableBody.rows[i].cells[4].innerHTML = '<div class="circle"></div>'; // Vertical line in last column
								tableBody.rows[i].cells[4].classList.add('highlighted');
							}
							for (let i = 0; i < 5; i++) {
								tableBody.rows[4].cells[i].innerHTML = '<div class="circle"></div>'; // Horizontal line in last row
								tableBody.rows[4].cells[i].classList.add('highlighted');
							}
							break;
						case 16: // Half above (top two rows)
							for (let i = 0; i < 2; i++) {
								for (let j = 0; j < 5; j++) {
									tableBody.rows[i].cells[j].innerHTML = '<div class="circle"></div>';
									tableBody.rows[i].cells[j].classList.add('highlighted');
								}
							}
							break;
						case 17: // Half below (bottom two rows)
							for (let i = 3; i < 5; i++) {
								for (let j = 0; j < 5; j++) {
									tableBody.rows[i].cells[j].innerHTML = '<div class="circle"></div>';
									tableBody.rows[i].cells[j].classList.add('highlighted');
								}
							}
							break;
						case 19: // Main diagonal
							for (let i = 0; i < 5; i++) {
								tableBody.rows[i].cells[i].innerHTML = '<div class="circle"></div>';
								tableBody.rows[i].cells[i].classList.add('highlighted');
							}
							break;
						case 20: // Anti diagonal
							for (let i = 0; i < 5; i++) {
								tableBody.rows[i].cells[4 - i].innerHTML = '<div class="circle"></div>';
								tableBody.rows[i].cells[4 - i].classList.add('highlighted');
							}
							break;
						case 21: // Outside corners
							[tableBody.rows[0].cells[0], tableBody.rows[0].cells[4], tableBody.rows[4].cells[0], tableBody.rows[4].cells[4]].forEach((cell) => {
								cell.innerHTML = '<div class="circle"></div>';
								cell.classList.add('highlighted');
							});
							break;
						case 22: // Inside corners (around free space)
							[tableBody.rows[1].cells[1], tableBody.rows[1].cells[3], tableBody.rows[3].cells[1], tableBody.rows[3].cells[3]].forEach((cell) => {
								cell.innerHTML = '<div class="circle"></div>';
								cell.classList.add('highlighted');
							});
							break;
						case 18: // Full pattern
							for (let i = 0; i < 5; i++) {
								for (let j = 0; j < 5; j++) {
									tableBody.rows[i].cells[j].innerHTML = '<div class="circle"></div>';
									tableBody.rows[i].cells[j].classList.add('highlighted');
								}
							}
							break;
						default:
							console.error('Pattern not recognized:', pattern);
							break;
					}
				});
			}



			function updatePattern() {
				patternGroup = document.getElementById("patt").innerText;
				if (patternGroup === '14') {
					patternGroup = '1';
				}
				patternIndex = 0;
				clearInterval(intervalId);
				const steps = allPatterns[patternGroup] || allPatterns['1'];
				drawPattern(steps[patternIndex]);
				if (steps.length > 1) {
					intervalId = setInterval(() => {
						const loopSteps = allPatterns[patternGroup] || allPatterns['1'];
						patternIndex = (patternIndex + 1) % loopSteps.length;
						drawPattern(loopSteps[patternIndex]);
					}, 2000);
				}
			}


			function celebrate() {
				const myCanvas = document.getElementById('canvas2');
				
				// Make sure it's visible and full screen
				myCanvas.style.display = 'block';
				myCanvas.width = window.innerWidth;
				myCanvas.height = window.innerHeight;

				// Create a confetti instance with your own canvas
				const myConfetti = confetti.create(myCanvas, { resize: true, useWorker: false });

				myConfetti({
					particleCount: 1000,
					spread: 200,
					origin: { y: 0.8 }
				});
			}

			// Function to show alert in the top right corner
			function showAlert(message, type) {
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







			var offset = new Date().getTimezoneOffset();
			function showWarning(message, timeout = 10000) 
			{
				// Create a container if it doesn't exist
				let container = document.getElementById('warningContainer');
				if (!container) {
					container = document.createElement('div');
					container.id = 'warningContainer';
					container.style.position = 'fixed';
					container.style.bottom = '5px';
					container.style.right = '5px';
					container.style.display = 'flex';
					container.style.flexDirection = 'column';
					container.style.gap = '5px';
					container.style.zIndex = '10000';
					document.body.appendChild(container);
				}

				// Create the warning box
				const warning = document.createElement('div');
				warning.style.background = ' rgba(196, 251, 17, 0.5)';
				warning.style.color = 'black';
				warning.style.padding = '10px 15px';
				warning.style.borderRadius = '8px';
				warning.style.boxShadow = '0 4px 8px rgba(0, 0, 0, 0.3)';
				warning.style.fontSize = '16px';
				warning.style.maxWidth = '700px';
				warning.style.position = 'relative';
				warning.style.animation = 'fadeIn 0.5s';

				// Close button
				const closeBtn = document.createElement('span');
				closeBtn.innerHTML = '&times;';
				closeBtn.style.position = 'absolute';
				closeBtn.style.top = '-30px';
				closeBtn.style.right = '5px';
				closeBtn.style.color = 'red';
				closeBtn.style.cursor = 'pointer';
				closeBtn.style.fontSize = '40px';
				closeBtn.addEventListener('click', () => {
					container.removeChild(warning);
				});

				warning.innerHTML = message;
				warning.appendChild(closeBtn);
				container.appendChild(warning);

				// Auto remove after timeout
				setTimeout(() => {
					if (container.contains(warning)) {
						container.removeChild(warning);
					}
				}, timeout);
			}

			// Main logic
			if (offset != -180) { showWarning(` Your computer's time zone is incorrect.Please set it to <b>Nairobi (UTC+3) </b>. `, 15000); } 
			// else {
			// 		// Check time with internet instead of transaction
			// 		fetch('https://timeapi.io/api/time/current/zone?timeZone=Africa%2FNairobi', {
			// 			method: 'GET',
			// 			headers: {
			// 				'Accept': 'application/json'
			// 			}
			// 		})
			// 		.then(response => response.json())
			// 		.then(data => {
			// 			try {
			// 				const internetTime = new Date(data.dateTime); // Extract datetime from API response
			// 				const localTime = new Date();
			// 				const timeDifferenceMs = Math.abs(localTime - internetTime);
			// 				const timeDifferenceHours = (timeDifferenceMs / (1000 * 60 * 60)); // Convert to hours
							
			// 				if (timeDifferenceHours > 6 || timeDifferenceHours < -6) { 
			// 					showWarning('Time difference exceeds 6 hours! Your computer time is significantly incorrect. Please adjust it immediately.', 15000);
			// 				} else if (timeDifferenceHours > 0.1 || timeDifferenceHours < -0.1) { 
			// 					let direction = timeDifferenceHours > 0 ? 'ahead' : 'behind';
			// 					showWarning(`Your system clock is ${Math.abs(timeDifferenceHours).toFixed(1)} hours ${direction} of the correct time. Please sync it.`, 15000);
			// 				}
			// 			} catch (error) {
			// 				console.error('Error processing the time difference:', error);
			// 			}
			// 		})
			// 		.catch(error => {
			// 			console.error('Error fetching internet time:', error);
			// 		});
			// 	}








var offset = new Date().getTimezoneOffset();
if(offset!=-180)
{

			// Create a modal dynamically and display it
			var modal = document.createElement('div');
			modal.id = 'timeZoneModal';
			modal.style.position = 'fixed';
			modal.style.top = '0';
			modal.style.left = '0';
			modal.style.width = '100%';
			modal.style.height = '100%';
			modal.style.background = 'rgba(0, 0, 0, 0.93)';
			modal.style.color = 'white';
			modal.style.display = 'flex';
			modal.style.justifyContent = 'center';
			modal.style.alignItems = 'center';
			modal.style.zIndex = '9999';
			modal.style.textAlign = 'center';
			modal.style.padding = '20px';
			modal.style.padding = '20px';
			modal.style.fontSize = '30px';

			// Modal content
			modal.innerHTML = `
				<div>
					<p>Your computer's time zone is incorrect. Please follow these steps to set it to Nairobi (UTC+3):</p>
					<ol style="text-align: left; margin: 0 auto; max-width: 500px;">
						<li>Open your computer's Date & Time settings.</li><br>

						<li>Disable "Set time zone automatically" if enabled.</li><br>

						<li>Select the time zone: <strong> Nairobi</strong>.</li><br>

						<li>Save your changes and refresh this page.</li>

						<div style="text-align: center;">
							<a href="../cashier/report.php"
							style="display: inline-block; text-decoration: none; color: black; background-color: white; padding: 20px; margin-bottom: 20px; width: 200px; font-size: 30px; text-align: center; border: 2px solid black; border-radius: 8px;">
							Go to Report
							</a>
						</div>
					</ol>
				</div>
			`;

			// Append the modal to the body
			document.body.appendChild(modal);

			// Disable scrolling
			document.body.style.overflow = 'hidden';
}
else
{
	$.ajax({
			type: 'POST',
			url: '../config/DbFunction.php',
			data: {
				get_last_transaction_time: "true",
			},
			dataType: "json",
			success: function(response) {
				if (response.success) {
					const lastTransactionTime = new Date(response.lastTransactionTime);
					const currentTime = new Date();

					// Calculate time difference in milliseconds
					const timeDifferenceMs = lastTransactionTime - currentTime;
					const timeDifferenceHours = timeDifferenceMs / (1000 * 60 * 60); // Convert to hours




					const currentDate = new Date(); // Current date (time included)
					const lastTransactionDate = new Date(
						lastTransactionTime.getFullYear(),
						lastTransactionTime.getMonth(),
						lastTransactionTime.getDate()
					); // Only date parts
					const todayDate = new Date(
						currentDate.getFullYear(),
						currentDate.getMonth(),
						currentDate.getDate()
					); // Only date parts


					if ((lastTransactionDate.getTime() < todayDate.getTime()) && response.unclearedGames>0) {
						// The last transaction date is a past date
						const todayDateString = todayDate.toDateString(); // Example: "Fri Jan 24 2025"
						const lastTransactionDateString = lastTransactionDate.toDateString(); // Example: "Thu Jan 23 2025"
						// alert(todayDateString)
						// alert(lastTransactionDateString)
						// Create a modal dynamically
						const modal = document.createElement('div');
						modal.id = 'newDayModal';
						modal.style.position = 'fixed';
						modal.style.top = '0';
						modal.style.left = '0';
						modal.style.width = '100%';
						modal.style.height = '100%';
						modal.style.background = 'rgba(0, 0, 0, 0.8)';
						modal.style.color = 'white';
						modal.style.display = 'flex';
						modal.style.flexDirection = 'column';
						modal.style.justifyContent = 'center';
						modal.style.alignItems = 'center';
						modal.style.zIndex = '9999';
						modal.style.padding = '16px';
						modal.style.boxSizing = 'border-box';

						// Modal content
						modal.innerHTML = `
							<div style="
								width: 100%;
								max-width: 520px;
								background: linear-gradient(180deg, #1e293b 0%, #0f172a 100%);
								color: #f8fafc;
								border-radius: 16px;
								box-shadow: 0 24px 48px rgba(0,0,0,0.45);
								border: 1px solid rgba(255,255,255,0.12);
								overflow: hidden;
								text-align: center;
								font-family: system-ui, -apple-system, 'Segoe UI', sans-serif;
							">
								<div style="
									padding: 20px 22px 14px;
									background: rgba(59, 130, 246, 0.15);
									border-bottom: 1px solid rgba(255,255,255,0.08);
								">
									<div style="font-size: 40px; line-height: 1; margin-bottom: 8px;" aria-hidden="true">📅</div>
									<h1 style="
										margin: 0;
										font-size: clamp(1.35rem, 4vw, 1.75rem);
										font-weight: 700;
										line-height: 1.25;
										letter-spacing: -0.02em;
									">አዲስ ቀን ላይ ነዎት!</h1>
								</div>

								<div style="padding: 18px 22px 8px; text-align: left;">
									<p style="
										margin: 0 0 14px;
										font-size: 0.95rem;
										line-height: 1.55;
										color: #cbd5e1;
										text-align: center;
									">
										የ ኮምፑተርዎ ቀን
									</p>
									<div style="
										margin: 0 auto 18px;
										max-width: 100%;
										padding: 10px 14px;
										background: rgba(255,255,255,0.08);
										border-radius: 10px;
										font-size: clamp(0.85rem, 2.5vw, 1rem);
										font-weight: 600;
										color: #e2e8f0;
										word-break: break-word;
										text-align: center;
									">${todayDateString}</div>

									<p style="margin: 0 0 12px; font-size: 0.95rem; line-height: 1.6; color: #e2e8f0;">
										የመጨረሻውን ታሪክ አፅድተው እንደ አዲስ መጀመር ከፈለጉ ትንሽ ይጠብቁ ?
									</p>
									<p style="margin: 0; font-size: 0.9rem; line-height: 1.6; color: #94a3b8;">
										ካልፈለጉ <strong style="color: #fca5a5;">Logout</strong> የሚለውን ማስፈንጠሪያ ከነኩ በኋላ የኮምፑተርዎን ሰዓት እና ቀን ያስተካክሉ!
									</p>
								</div>

								<div style="
									display: flex;
									flex-wrap: wrap;
									align-items: center;
									justify-content: center;
									gap: 20px;
									padding: 18px 22px 22px;
									border-top: 1px solid rgba(255,255,255,0.08);
									background: rgba(0,0,0,0.2);
								">
									<div id="countdownCircle" style="
										flex-shrink: 0;
										display: flex;
										flex-direction: column;
										justify-content: center;
										align-items: center;
										width: 112px;
										height: 112px;
										background: #ffffff;
										border-radius: 50%;
										color: #0f172a;
										font-weight: 700;
										border: 3px solid #3b82f6;
										box-shadow: 0 4px 14px rgba(59,130,246,0.35);
									">
										<span id="countdown" style="font-size: 2rem; line-height: 1;">15</span>
										<span style="font-size: 0.75rem; font-weight: 600; color: #64748b; margin-top: 2px;">Secs</span>
									</div>

									<button type="button" id="logoutButton" style="
										flex: 1 1 140px;
										min-width: 140px;
										max-width: 220px;
										background: #dc2626;
										color: #fff;
										padding: 14px 22px;
										border: none;
										border-radius: 10px;
										font-size: 1.1rem;
										font-weight: 600;
										cursor: pointer;
										box-shadow: 0 4px 12px rgba(220,38,38,0.35);
									">Logout</button>
								</div>
							</div>
						`;

						// Append the modal to the body
						document.body.appendChild(modal);

						// Disable scrolling
						document.body.style.overflow = 'hidden';

						// Countdown logic
						let countdown = 15;
						const countdownElement = document.getElementById('countdown');
						const interval = setInterval(() => {
							countdown -= 1;
							countdownElement.textContent = countdown;

							if (countdown === 2) {
								clearInterval(interval); // Stop the countdown

								// Automatically delete the game history
								$.ajax({
										type: 'POST',
										url: '../config/DbFunction.php',
										data: {
											delete_game_history: "true",
										},
										dataType: "json",
										success: function(deleteResponse) {
											if (deleteResponse.status === "success") {
												showAlert(deleteResponse.message,"success")
												setTimeout(function() {
													window.location.reload();
												}, 2000);
											} else if (deleteResponse.status === "error") {
												showAlert("Failed to delete game history: " + deleteResponse.message,"danger")
											} else {
												showAlert("Unexpected response from the server.","danger");
											}
										},
										error: function(jqXHR, textStatus, errorThrown) {
											console.error('Error deleting game history:');
											console.error('Status: ' + textStatus);
											console.error('Error Thrown: ' + errorThrown);
											console.error('Response Text: ' + jqXHR.responseText);
										}
									});


								// Remove the modal and re-enable scrolling
								document.body.removeChild(modal);
								document.body.style.overflow = 'auto';
							}
						}, 1000); // Update every second

						// Logout button logic
						const logoutButton = document.getElementById('logoutButton');
						logoutButton.addEventListener('click', () => {
							clearInterval(interval); // Stop the countdown
							window.location.href = '../config/logout.php'; // Redirect to logout page
						});
					}

					// Check if currentTime is less than lastTransactionTime and difference is >= 4 hours
					if (currentTime < lastTransactionTime) {
						// Create a modal dynamically and display it
						var modal = document.createElement('div');
						modal.id = 'timeZoneModal';
						modal.style.position = 'fixed';
						modal.style.top = '0';
						modal.style.left = '0';
						modal.style.width = '100%';
						modal.style.height = '100%';
						modal.style.background = 'rgba(0, 0, 0, 0.93)';
						modal.style.color = 'white';
						modal.style.display = 'flex';
						modal.style.flexDirection = 'column';
						modal.style.justifyContent = 'center';
						modal.style.alignItems = 'center';
						modal.style.zIndex = '9999';
						modal.style.textAlign = 'center';
						modal.style.padding = '20px';
						modal.style.fontSize = '20px';

						// Modal content with circular countdown timer
						modal.innerHTML = `
							<div>
								<h1>Your system clock has been set backward. [${timeDifferenceHours.toFixed(2)} hours]</h1>
								<h1> የ ኮምፑተርዎ ሰዓት በ [${timeDifferenceHours.toFixed(2)} ሰዓት ] ይዘገያል እባክዎትን ያስተካክሉ ! </h1>
								<p>This may cause data inaccuracies. Please ensure your computer's time and time zone are correct.</p>
								<div style="
									display: flex;
									flex-direction: column;
									justify-content: center;
									align-items: center;
									margin: 20px;
								">
									<div id="countdownCircle" style="
										display: flex;
										justify-content: center;
										align-items: center;
										width: 100px;
										height: 100px;
										background-color: white;
										border-radius: 50%;
										color: black;
										font-size: 30px;
										font-weight: bold;
										border: 4px solid black;
									">
										<span id="countdown">20</span>
									</div>
								</div>
							</div>
						`;

						// Append the modal to the body
						document.body.appendChild(modal);

						// Disable scrolling
						document.body.style.overflow = 'hidden';

						// Countdown logic
						let countdown = 20;
						const countdownElement = document.getElementById('countdown');
						const interval = setInterval(() => {
							countdown -= 1;
							countdownElement.textContent = countdown;

							if (countdown === 0) {
								clearInterval(interval); // Stop the countdown
								window.location.href = '../config/logout.php'; // Redirect to logout page
							}
						}, 1000); // Update every second
					}
				} else {
					console.error(response.message);
				}
			},


			error: function(jqXHR, textStatus, errorThrown) {
				console.error('Error Details:');
				console.error('Status: ' + textStatus);
				console.error('Error Thrown: ' + errorThrown);
				console.error('Response Text: ' + jqXHR.responseText);
			}
		});
}



// document.addEventListener("DOMContentLoaded", () => {
//     // Create notification box
//     const box = document.createElement("div");
//     box.className = "notification-box";
//     box.innerHTML = `
//         <p>⚠️ Finish your task within 20 minutes.....<br><br><br></p>
        
//         <p>The system will be shut down after 20 minutes.</p>
//         <button class="ok-btn">OK</button>
//     `;

//     // Add to the body
//     document.body.appendChild(box);

//     // OK button event
//     box.querySelector(".ok-btn").addEventListener("click", () => {
//         box.remove();
//     });
// });

// CSS Styles
const styles = `
.notification-box {
    position: fixed;
    left: 20px;
    bottom: 50%;
    background: #fff3cd;
    color: #856404;
    border: 1px solid #ffeeba;
    padding: 15px 20px;
    border-radius: 8px;
    box-shadow: 0 4px 10px rgba(0,0,0,0.2);
    font-size: 20px;
    max-width: 400px;
    z-index: 3000;
    animation: fadeIn 0.5s ease;
}

.notification-box p {
    margin: 5px 0;
}

.notification-box .ok-btn {
    margin-top: 10px;
    padding: 6px 14px;
    background-color: #28a745;
    color: white;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-size: 14px;
    transition: background-color 0.3s ease;
}

.notification-box .ok-btn:hover {
    background-color: #218838;
}

@keyframes fadeIn {
    from { opacity: 0; transform: translateY(10px); }
    to { opacity: 1; transform: translateY(0); }
}
`;

// Inject CSS
const styleSheet = document.createElement("style");
styleSheet.type = "text/css";
styleSheet.innerText = styles;
document.head.appendChild(styleSheet);


</script>


<footer class="footer">
    <div class="container">
        <div class="footer-content">
            <p>&copy;                                           <?php echo date("Y"); ?> ethiomark. All rights reserved.</p>
        </div>
    </div>
</footer>


</body>
</html>