<style>
        body {
            transition: background-color 0.5s, color 0.5s;
        }

        .theme {
            padding: 10px;
            margin: 5px;
            cursor: pointer;
            display: inline-block;
        }

        .theme-1 {
            background-color: rgb(3, 46, 59);
            color: #ecf0f1;
        }

        /* Light theme */
        .theme-2 {
            background-color: #586464;
            color: #333;
        }

        /* Dark theme */
        .theme-3 {
            background-color: #34495e;
            color: #bdc3c7;
        }

        /* Blue theme */
        .theme-4 {
            background-color: #2980b9;
            color: white;
        }

        /* Green theme */
        .theme-5 {
            background-color: #2f744b;
            color: white;
        }

        /* Red theme */
        .theme-6 {
            background-color: #e74c3c;
            color: white;
        }

        /* Yellow theme */
        .theme-7 {
            background-color: #9c6c1f;
            color: black;
        }

        /* Purple theme */
        .theme-8 {
            background-color: #8e44ad;
            color: white;
        }

        /* Orange theme */
        .theme-9 {
            background-color: #7e4e25;
            color: white;
        }

        /* Pink theme */
        .theme-10 {
            background-color: #d36d6f;
            color: white;
        }
    </style>
	<!-- Container for buttons aligned in a column -->
	<div id="buttonContainer" style="position: absolute; top: 0px; right: 0px; z-index: 999; display: flex; flex-direction: column; gap: 10px; align-items: flex-end; width: 50px;">


		<!-- Theme Selector Dropdown -->
		<div style="position: relative; display: inline-block;">
			<button id="themeDropdownBtn" style="display: flex; align-items: center; justify-content: center; padding: 10px 0; background-color: transparent; color: white; border: 2px solid #28a745; border-radius: 5px; cursor: pointer; width: 100%; text-align: center;">
				🎨 Themes
			</button>
			<div id="themeDropdown" style="display: none; position: absolute; top: 100%; left: -100; background-color: #222; border: 2px solid #28a745; border-radius: 5px; overflow: hidden; z-index: 1000; width: 150px;">
				<button onclick="setTheme('theme-1')" style="display: block; background-color: rgb(3, 46, 59); color: #ecf0f1; width: 100%; padding: 10px; border: none; text-align: left;">Default</button>
				<button onclick="setTheme('theme-2')" style="display: block; background-color: #586464; color: #fff; width: 100%; padding: 10px; border: none; text-align: left;">Theme 2</button>
				<button onclick="setTheme('theme-3')" style="display: block; background-color: #34495e; color: #bdc3c7; width: 100%; padding: 10px; border: none; text-align: left;">Theme 3</button>
				<button onclick="setTheme('theme-4')" style="display: block; background-color: #2980b9; color: white; width: 100%; padding: 10px; border: none; text-align: left;">Theme 4</button>
				<button onclick="setTheme('theme-5')" style="display: block; background-color: #27ae60; color: white; width: 100%; padding: 10px; border: none; text-align: left;">Theme 5</button>
				<button onclick="setTheme('theme-6')" style="display: block; background-color: #e74c3c; color: white; width: 100%; padding: 10px; border: none; text-align: left;">Theme 6</button>
				<button onclick="setTheme('theme-7')" style="display: block; background-color: #f39c12; color: black; width: 100%; padding: 10px; border: none; text-align: left;">Theme 7</button>
				<button onclick="setTheme('theme-8')" style="display: block; background-color: #8e44ad; color: white; width: 100%; padding: 10px; border: none; text-align: left;">Theme 8</button>
				<button onclick="setTheme('theme-9')" style="display: block; background-color: #7e4e25; color: white; width: 100%; padding: 10px; border: none; text-align: left;">Theme 9</button>
				<button onclick="setTheme('theme-10')" style="display: block; background-color: #d36d6f; color: white; width: 100%; padding: 10px; border: none; text-align: left;">Theme 10</button>
			</div>
		</div>


		<!-- Fullscreen Button -->
		<button id="fullscreenBtn" style="display: flex; align-items: center; justify-content: center; padding: 0px 0; background-color: transparent; color: white; border: 2px solid #28a745; border-radius: 5px; cursor: pointer; width: 100%; text-align: center;">
			<svg width="14" height="14" fill="#ffffff" class="bi bi-fullscreen" viewBox="0 0 16 16">
				<path d="M1.5 1a.5.5 0 0 0-.5.5v4a.5.5 0 0 1-1 0v-4A1.5 1.5 0 0 1 1.5 0h4a.5.5 0 0 1 0 1zM10 .5a.5.5 0 0 1 .5-.5h4A1.5 1.5 0 0 1 16 1.5v4a.5.5 0 0 1-1 0v-4a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 1-.5-.5M.5 10a.5.5 0 0 1 .5.5v4a.5.5 0 0 0 .5.5h4a.5.5 0 0 1 0 1h-4A1.5 1.5 0 0 1 0 14.5v-4a.5.5 0 0 1 .5-.5m15 0a.5.5 0 0 1 .5.5v4a1.5 1.5 0 0 1-1.5 1.5h-4a.5.5 0 0 1 0-1h4a.5.5 0 0 0 .5-.5v-4a.5.5 0 0 1 .5-.5"/>
			</svg>
		</button>
	</div>
	<script>

					document.addEventListener('DOMContentLoaded', function () {
						// Check if there's a saved theme in local storage
						const savedTheme = localStorage.getItem('theme');
						if (savedTheme) {
							document.body.className = savedTheme;
						}
					});


					document.getElementById("themeDropdownBtn").addEventListener("click", function () {
						var dropdown = document.getElementById("themeDropdown");
						dropdown.style.display = dropdown.style.display === "block" ? "none" : "block";
					});

					// Function to apply the theme and save it in local storage
					function setTheme(theme) {
						document.body.className = theme;
						localStorage.setItem('theme', theme);
					}


					// Close dropdown when clicking outside
					document.addEventListener("click", function (event) {
						var dropdown = document.getElementById("themeDropdown");
						var button = document.getElementById("themeDropdownBtn");

						if (dropdown.style.display === "block" && !button.contains(event.target) && !dropdown.contains(event.target)) {
							dropdown.style.display = "none";
						}
					});
		</script>

			<nav class="main-menu-side-nav" >
				<div style="max-height: 100px">
						<a class="logo" >
							<img class="profile-image" style = "user-drag: none; -webkit-user-drag: none;" src="../assets/images/logo.png" alt="User Icon" >
						</a>
					</div>
					<footer class="side-nav-footer">
						Ethiomark Bingo
					</footer>
                        <script>
								const fullscreenBtn = document.getElementById('fullscreenBtn');
								const sideNav = document.querySelector('.main-menu-side-nav'); // Adjust selector as needed

								// Function to update the SVG icon based on fullscreen state
								function updateFullscreenIcon(isFullscreen) {
									fullscreenBtn.innerHTML = isFullscreen ? `
										<svg width="16" height="16" fill="#ffffff" class="bi bi-fullscreen-exit" viewBox="0 0 16 16">
											<path d="M5.5 0a.5.5 0 0 1 .5.5v4A1.5 1.5 0 0 1 4.5 6h-4a.5.5 0 0 1 0-1h4a.5.5 0 0 0 .5-.5v-4a.5.5 0 0 1 .5-.5m5 0a.5.5 0 0 1 .5.5v4a.5.5 0 0 0 .5.5h4a.5.5 0 0 1 0 1h-4A1.5 1.5 0 0 1 10 4.5v-4a.5.5 0 0 1 .5-.5M0 10.5a.5.5 0 0 1 .5-.5h4A1.5 1.5 0 0 1 6 11.5v4a.5.5 0 0 1-1 0v-4a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 1-.5-.5m10 1a1.5 1.5 0 0 1 1.5-1.5h4a.5.5 0 0 1 0 1h-4a.5.5 0 0 0-.5.5v4a.5.5 0 0 1-1 0z"/>
										</svg>
									` : `
										<svg width="16" height="16" fill="#ffffff" class="bi bi-fullscreen" viewBox="0 0 16 16">
											<path d="M1.5 1a.5.5 0 0 0-.5.5v4a.5.5 0 0 1-1 0v-4A1.5 1.5 0 0 1 1.5 0h4a.5.5 0 0 1 0 1zM10 .5a.5.5 0 0 1 .5-.5h4A1.5 1.5 0 0 1 16 1.5v4a.5.5 0 0 1-1 0v-4a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 1-.5-.5M.5 10a.5.5 0 0 1 .5.5v4a.5.5 0 0 0 .5.5h4a.5.5 0 0 1 0 1h-4A1.5 1.5 0 0 1 0 14.5v-4a.5.5 0 0 1 .5-.5m15 0a.5.5 0 0 1 .5.5v4a1.5 1.5 0 0 1-1.5 1.5h-4a.5.5 0 0 1 0-1h4a.5.5 0 0 0 .5-.5v-4a.5.5 0 0 1 .5-.5"/>
										</svg>
									`;
									fullscreenBtn.classList.toggle('pulsate', isFullscreen);
								}

								// Check localStorage to see if the side nav should be hidden
								if (sideNav && localStorage.getItem('sideNavHidden') === 'true') {
									sideNav.style.display = 'none';
									fullscreenBtn.innerHTML = `
										<svg width="16" height="16" fill="#ffffff" class="bi bi-fullscreen-exit" viewBox="0 0 16 16">
											<path d="M5.5 0a.5.5 0 0 1 .5.5v4A1.5 1.5 0 0 1 4.5 6h-4a.5.5 0 0 1 0-1h4a.5.5 0 0 0 .5-.5v-4a.5.5 0 0 1 .5-.5m5 0a.5.5 0 0 1 .5.5v4a.5.5 0 0 0 .5.5h4a.5.5 0 0 1 0 1h-4A1.5 1.5 0 0 1 10 4.5v-4a.5.5 0 0 1 .5-.5M0 10.5a.5.5 0 0 1 .5-.5h4A1.5 1.5 0 0 1 6 11.5v4a.5.5 0 0 1-1 0v-4a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 1-.5-.5m10 1a1.5 1.5 0 0 1 1.5-1.5h4a.5.5 0 0 1 0 1h-4a.5.5 0 0 0-.5.5v4a.5.5 0 0 1-1 0z"/>
										</svg>
									` ;
									fullscreenBtn.classList.toggle('pulsate', true);
								}

								// Check if the page is already in fullscreen mode on load
								if (document.fullscreenElement) {
									updateFullscreenIcon(true); // Set icon to exit fullscreen
								}

								// Event listener for the fullscreen button
								fullscreenBtn.addEventListener('click', function() {
									if (!document.fullscreenElement) {
										document.documentElement.requestFullscreen().then(() => {
											document.body.classList.add('fullscreen'); // Add fullscreen class
											updateFullscreenIcon(true); // Update icon to exit fullscreen

											// Hide the side nav and save state to localStorage
											if (sideNav) {
												sideNav.style.display = 'none';
												localStorage.setItem('sideNavHidden', 'true');

											}
										}).catch((err) => {
											alert(`Error attempting to enable fullscreen mode: ${err.message}`);
										});
									} else {
										document.exitFullscreen().then(() => {
											document.body.classList.remove('fullscreen'); // Remove fullscreen class
											updateFullscreenIcon(false); // Update icon to enter fullscreen

											// Show the side nav when exiting fullscreen
											if (sideNav) {
												sideNav.style.display = 'block';
												localStorage.setItem('sideNavHidden', 'false'); // Reset state in localStorage
											}
										});
									}
								});

								// Optional: Update the button text and icon on exiting fullscreen mode
								document.addEventListener('fullscreenchange', () => {
									const isFullscreen = !!document.fullscreenElement;
									document.body.classList.toggle('fullscreen', isFullscreen); // Toggle fullscreen class
									updateFullscreenIcon(isFullscreen); // Update icon based on fullscreen state

									// Show or hide the side nav based on fullscreen state
									if (sideNav) {
										sideNav.style.display = isFullscreen ? 'none' : 'block';
										localStorage.setItem('sideNavHidden', isFullscreen ? 'true' : 'false'); // Update state in localStorage
									}
								});

								// Additional functionality to toggle side nav visibility in fullscreen
								document.addEventListener('keydown', (event) => {
									if (event.key === 'F' && document.fullscreenElement) {
										if (sideNav) {
											sideNav.style.display = sideNav.style.display === 'none' ? 'block' : 'none'; // Toggle side nav
											localStorage.setItem('sideNavHidden', sideNav.style.display === 'none' ? 'true' : 'false');
										}
									}
								});

								// Add CSS for pulsate animation
								const style = document.createElement('style');
								style.textContent = `
									.pulsate {
										animation: pulsate 0.9s infinite;
									}
									@keyframes pulsate {
										0% {
											box-shadow: 0 0 0px rgba(233, 23, 4, 0.5);
										}
										50% {
											box-shadow: 0 0 60px rgba(246, 254, 2, 0.8);
										}
										100% {
											box-shadow: 0 0 0px rgba(255, 255, 255, 0.5);
										}
									}
								`;
								document.head.appendChild(style);
							</script>



					<div id="cashier_profile_name" class="settings"></div>
					<div class="scrollbar" id="style-1">
						<ul>
							<li>
								<a  onclick="navigateTo('../cashier/report.php')" >
									<i class="fa">
										<svg width="16" height="16" fill="currentColor" class="bi bi-cash-coin" viewBox="0 0 16 16">
											<path fill-rule="evenodd" d="M11 15a4 4 0 1 0 0-8 4 4 0 0 0 0 8m5-4a5 5 0 1 1-10 0 5 5 0 0 1 10 0"/>
											<path d="M9.438 11.944c.047.596.518 1.06 1.363 1.116v.44h.375v-.443c.875-.061 1.386-.529 1.386-1.207 0-.618-.39-.936-1.09-1.1l-.296-.07v-1.2c.376.043.614.248.671.532h.658c-.047-.575-.54-1.024-1.329-1.073V8.5h-.375v.45c-.747.073-1.255.522-1.255 1.158 0 .562.378.92 1.007 1.066l.248.061v1.272c-.384-.058-.639-.27-.696-.563h-.668zm1.36-1.354c-.369-.085-.569-.26-.569-.522 0-.294.216-.514.572-.578v1.1zm.432.746c.449.104.655.272.655.569 0 .339-.257.571-.709.614v-1.195z"/>
											<path d="M1 0a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1h4.083q.088-.517.258-1H3a2 2 0 0 0-2-2V3a2 2 0 0 0 2-2h10a2 2 0 0 0 2 2v3.528c.38.34.717.728 1 1.154V1a1 1 0 0 0-1-1z"/>
											<path d="M9.998 5.083 10 5a2 2 0 1 0-3.132 1.65 6 6 0 0 1 3.13-1.567"/>
										</svg>
									</i>
									<span class="nav-text">Cashier Option</span>
								</a>
							</li>

							<li>
								<a  onclick="navigateTo('../cashier/reg_new_game.php')" id="register_new_pllayer_link">
									<i class="fa">

										<svg width="16" height="16" fill="currentColor" class="bi bi-plus-circle" viewBox="0 0 16 16">
											<path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14m0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16"/>
											<path d="M8 4a.5.5 0 0 1 .5.5v3h3a.5.5 0 0 1 0 1h-3v3a.5.5 0 0 1-1 0v-3h-3a.5.5 0 0 1 0-1h3v-3A.5.5 0 0 1 8 4"/>
										</svg>
									</i>
									<span class="nav-text">Register Players Card</span>
								</a>
							</li>

							<li>
								<a  onclick="navigateTo('../cashier/index.php')" id="play_bingo_link">
									<i class="fa">
										<svg width="16" height="16" fill="currentColor" class="bi bi-play-btn" viewBox="0 0 16 16">
											<path d="M6.79 5.093A.5.5 0 0 0 6 5.5v5a.5.5 0 0 0 .79.407l3.5-2.5a.5.5 0 0 0 0-.814z"/>
											<path d="M0 4a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2zm15 0a1 1 0 0 0-1-1H2a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1z"/>
										</svg>
									</i>
									<span class="nav-text">Play Bingo</span>
								</a>
							</li>

							<li>
								<a  onclick="navigateTo('../cashier/register_new_card.php')" id="card_record_link">
									<i class="fa">
										<svg width="16" height="16" fill="currentColor" class="bi bi-card-checklist" viewBox="0 0 16 16">
											<path d="M14.5 3a.5.5 0 0 1 .5.5v9a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-9a.5.5 0 0 1 .5-.5zm-13-1A1.5 1.5 0 0 0 0 3.5v9A1.5 1.5 0 0 0 1.5 14h13a1.5 1.5 0 0 0 1.5-1.5v-9A1.5 1.5 0 0 0 14.5 2z"/>
											<path d="M7 5.5a.5.5 0 0 1 .5-.5h5a.5.5 0 0 1 0 1h-5a.5.5 0 0 1-.5-.5m-1.496-.854a.5.5 0 0 1 0 .708l-1.5 1.5a.5.5 0 0 1-.708 0l-.5-.5a.5.5 0 1 1 .708-.708l.146.147 1.146-1.147a.5.5 0 0 1 .708 0M7 9.5a.5.5 0 0 1 .5-.5h5a.5.5 0 0 1 0 1h-5a.5.5 0 0 1-.5-.5m-1.496-.854a.5.5 0 0 1 0 .708l-1.5 1.5a.5.5 0 0 1-.708 0l-.5-.5a.5.5 0 0 1 .708-.708l.146.147 1.146-1.147a.5.5 0 0 1 .708 0"/>
										</svg>
									</i>
									<span class="nav-text">View your cartela</span>
								</a>
							</li>

							<li>
								<a  id="contactbtn">
									<i class="fa">
										<svg width="16" height="16" fill="currentColor" class="bi bi-info-circle" viewBox="0 0 16 16">
											<path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14m0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16"/>
											<path d="m8.93 6.588-2.29.287-.082.38.45.083c.294.07.352.176.288.469l-.738 3.468c-.194.897.105 1.319.808 1.319.545 0 1.178-.252 1.465-.598l.088-.416c-.2.176-.492.246-.686.246-.275 0-.375-.193-.304-.533zM9 4.5a1 1 0 1 1-2 0 1 1 0 0 1 2 0"/>
										</svg>
									</i>
									<span class="nav-text">Contact</span>
								</a>
							</li>
							

							<!-- Modal -->
							<div id="addressModal" class="nav-modal">
								<div class="nav-modal-content">
									<span class="nav-close">&times;</span>
									<h2>Ethio Mark</h2>
									<Address>
										<p>+251-918 - 1010 - 37</p>
										<p>meka2967@gmail.com</p>
									</Address>

								</div>
							</div>
							<script>
								const contactBtn = document.getElementById('contactbtn');
								const modal = document.getElementById('addressModal');
								const closeBtn = document.getElementsByClassName('nav-close')[0];

								// Open the modal when the button is clicked
								contactBtn.addEventListener('click', function(event) {
									event.preventDefault(); // Prevent the default anchor click behavior
									modal.style.display = 'block';
								});

								// Close the modal when the close button is clicked
								closeBtn.addEventListener('click', function() {
									modal.style.display = 'none';
								});

								// Close the modal when clicking outside of the modal content
								window.addEventListener('click', function(event) {
									if (event.target === modal) {
										modal.style.display = 'none';
									}
								});

							</script>


							<li>
								<a  onclick="navigateTo('../config/logout.php')" id="logoutbtn">
									<i class="fa">
										<svg width="16" height="16" fill="currentColor"  viewBox="0 0 16 16">
											<path fill-rule="evenodd" d="M6 3.5a.5.5 0 0 1 .5-.5h8a.5.5 0 0 1 .5.5v9a.5.5 0 0 1-.5.5h-8a.5.5 0 0 1-.5-.5v-2a.5.5 0 0 0-1 0v2A1.5 1.5 0 0 0 6.5 14h8a1.5 1.5 0 0 0 1.5-1.5v-9A1.5 1.5 0 0 0 14.5 2h-8A1.5 1.5 0 0 0 5 3.5v2a.5.5 0 0 0 1 0z"/>
											<path fill-rule="evenodd" d="M11.854 8.354a.5.5 0 0 0 0-.708l-3-3a.5.5 0 1 0-.708.708L10.293 7.5H1.5a.5.5 0 0 0 0 1h8.793l-2.147 2.146a.5.5 0 0 0 .708.708z"/>
										</svg>
									</i>
									<span class="nav-text">Logout</span>
								</a>
							</li>
						</ul>
					</div>


					<script>
                        function navigateTo(url) {
                            window.location.href = url;
                        }
                    </script>
				</nav>
