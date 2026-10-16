<?php
session_start();
include_once '../config/Database.php';
require_once '../config/SupportCashierSchema.php';

$db = Database::getInstance();
$conn = $db->getConnection();

$main_cashier_from_url = $_GET['main'] ?? '';
support_cashier_ensure_defaults($conn, (string) ($main_cashier_from_url ?: ($_SESSION['main_cashier_id'] ?? '')));

// Initialize error variable
$error = '';

// Check for saved credentials in localStorage (will be handled by JavaScript)
$saved_cashier_id = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $cashier_id = $_POST['cashier_id'] ?? '';
    $password = $_POST['password'] ?? '';
    $remember_me = isset($_POST['remember_me']) && $_POST['remember_me'] === 'on';
    
    // Debug: Check what's being received
    error_log("Login attempt: cashier_id=$cashier_id, remember_me=" . ($remember_me ? 'yes' : 'no'));
    
    if ($cashier_id && $password) {
        // First, check if cashier exists
        $query = "SELECT * FROM support_cashiers WHERE support_cashier_id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("s", $cashier_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 1) {
            $cashier = $result->fetch_assoc();
            
            // Verify password (using MD5 as in your system)
            if (md5($password) === $cashier['password']) {
                
                // Get the main cashier ID assigned to this supportive cashier from database
                $main_cashier_query = "SELECT main_cashier_id FROM support_cashiers WHERE support_cashier_id = ? AND is_active = 1";
                $stmt2 = $conn->prepare($main_cashier_query);
                $stmt2->bind_param("s", $cashier_id);
                $stmt2->execute();
                $main_result = $stmt2->get_result();
                
                if ($main_result->num_rows === 1) {
                    $main_data = $main_result->fetch_assoc();
                    $main_cashier_id_from_db = $main_data['main_cashier_id'];
                    
                    // If there's a URL parameter, verify it matches the database assignment
                    if (!empty($main_cashier_from_url)) {
                        if ($main_cashier_from_url !== $main_cashier_id_from_db) {
                            $error = "This supportive cashier is assigned to a different main cashier. Please use the correct invitation link.";
                            error_log("Main cashier mismatch: Expected $main_cashier_from_url, but assigned to $main_cashier_id_from_db");
                        }
                    }
                    
                    if (empty($error)) {
                        // Verify the main cashier actually exists
                        $verify_main_query = "SELECT cashier_id FROM cashier WHERE cashier_id = ?";
                        $stmt3 = $conn->prepare($verify_main_query);
                        $stmt3->bind_param("s", $main_cashier_id_from_db);
                        $stmt3->execute();
                        $verify_result = $stmt3->get_result();
                        
                        if ($verify_result->num_rows === 1) {
                            // Login successful
                            $_SESSION['loggedin'] = true;
                            $_SESSION['cashier_id'] = $cashier_id;
                            $_SESSION['role'] = 'support_cashier';
                            $_SESSION['main_cashier_id'] = $main_cashier_id_from_db;
                            
                            // Store remember me preference in session (for JavaScript to handle)
                            $_SESSION['remember_me'] = $remember_me;
                            
                            // Get or assign color
                            $color_query = "SELECT color_code FROM support_preferences WHERE support_cashier_id = ?";
                            $stmt4 = $conn->prepare($color_query);
                            $stmt4->bind_param("s", $cashier_id);
                            $stmt4->execute();
                            $color_result = $stmt4->get_result();
                            
                            if ($color_result->num_rows === 1) {
                                $color_data = $color_result->fetch_assoc();
                                $_SESSION['support_color'] = $color_data['color_code'];
                            } else {
                                // Assign random color
                                $colors = ['#FF5733', '#33FF57', '#3357FF', '#F333FF', '#33FFF3', '#FFD733', '#FF33A1', '#33FFA1'];
                                $random_color = $colors[array_rand($colors)];
                                
                                $insert_color = "INSERT INTO support_preferences (support_cashier_id, color_code) VALUES (?, ?)";
                                $stmt5 = $conn->prepare($insert_color);
                                $stmt5->bind_param("ss", $cashier_id, $random_color);
                                $stmt5->execute();
                                
                                $_SESSION['support_color'] = $random_color;
                            }
                            
                            // Store main cashier info in session
                            $_SESSION['main_cashier_info'] = $main_cashier_id_from_db;
                            
                            // Debug: Log successful login
                            error_log("Login successful for $cashier_id assisting $main_cashier_id_from_db");
                            
                            // Redirect to support interface
                            header("Location: support_interface.php");
                            exit();
                        } else {
                            $error = "The assigned main cashier ($main_cashier_id_from_db) no longer exists. Please contact administrator.";
                            error_log("Main cashier not found: $main_cashier_id_from_db");
                        }
                    }
                } else {
                    $error = "This supportive cashier is not currently assigned to any main cashier.";
                    error_log("No main cashier assignment found for: $cashier_id");
                }
            } else {
                $error = "Invalid password.";
                error_log("Invalid password for $cashier_id");
            }
        } else {
            $error = "Supportive cashier ID not found.";
            error_log("Supportive cashier ID not found: $cashier_id");
        }
    } else {
        $error = "Please enter both cashier ID and password.";
    }
}

// Check if main cashier from URL exists and if it has supportive cashiers
$main_cashier_info = null;
if (!empty($main_cashier_from_url)) {
    // Check if main cashier exists
    $check_main_query = "SELECT cashier_id FROM cashier WHERE cashier_id = ?";
    $stmt = $conn->prepare($check_main_query);
    $stmt->bind_param("s", $main_cashier_from_url);
    $stmt->execute();
    $check_result = $stmt->get_result();
    
    if ($check_result->num_rows === 1) {
        $main_cashier_info = [
            'id' => $main_cashier_from_url,
            'exists' => true,
            'has_supportive_cashiers' => false
        ];
        
        // Check if this main cashier has supportive cashiers
        $check_support_query = "SELECT COUNT(*) as count FROM support_cashiers WHERE main_cashier_id = ? AND is_active = 1";
        $stmt2 = $conn->prepare($check_support_query);
        $stmt2->bind_param("s", $main_cashier_from_url);
        $stmt2->execute();
        $support_result = $stmt2->get_result();
        $support_data = $support_result->fetch_assoc();
        
        $main_cashier_info['has_supportive_cashiers'] = $support_data['count'] > 0;
    } else {
        $main_cashier_info = [
            'id' => $main_cashier_from_url,
            'exists' => false,
            'has_supportive_cashiers' => false
        ];
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Supportive Cashier Login</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <meta name="mobile-web-app-capable" content="yes">
    <style>
        :root {
            --primary-color: #077C6C;
            --primary-dark: #065c50;
            --primary-light: #4ECDC4;
            --error-color: #c62828;
            --error-bg: #ffebee;
            --success-color: #2e7d32;
            --success-bg: #e8f5e9;
            --warning-color: #f57c00;
            --warning-bg: #fff3e0;
            --text-color: #333;
            --text-light: #666;
            --border-color: #ddd;
            --bg-color: white;
            --input-bg: #f8f9fa;
            --shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            -webkit-tap-highlight-color: transparent;
        }
        
        body {
            background: linear-gradient(135deg, var(--primary-color), var(--primary-light));
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            line-height: 1.4;
            color: var(--text-color);
            height: 100vh;
            height: -webkit-fill-available;
            display: flex;
            flex-direction: column;
        }
        
        /* Safe area support for iOS notch */
        @supports (padding: max(0px)) {
            body {
                padding-top: env(safe-area-inset-top);
                padding-bottom: env(safe-area-inset-bottom);
                padding-left: env(safe-area-inset-left);
                padding-right: env(safe-area-inset-right);
            }
        }
        
        .login-container {
            background: var(--bg-color);
            border-radius: 0;
            width: 100%;
            max-width: 100%;
            height: 100%;
            display: flex;
            flex-direction: column;
            overflow-y: auto;
            -webkit-overflow-scrolling: touch;
        }
        
        @media (min-width: 768px) {
            body {
                padding: 20px;
                justify-content: center;
                align-items: center;
            }
            
            .login-container {
                border-radius: 20px;
                max-width: 500px;
                max-height: 90vh;
                box-shadow: var(--shadow);
            }
        }
        
        .login-header {
            background: var(--primary-color);
            color: white;
            padding: clamp(20px, 6vw, 30px);
            text-align: center;
            position: sticky;
            top: 0;
            z-index: 100;
        }
        
        .login-header h1 {
            margin: 0;
            font-size: clamp(20px, 5vw, 24px);
            font-weight: 600;
        }
        
        .login-header p {
            margin: 8px 0 0 0;
            opacity: 0.9;
            font-size: clamp(14px, 4vw, 16px);
        }
        
        .login-body {
            padding: clamp(20px, 5vw, 30px);
            flex: 1;
            overflow-y: auto;
        }
        
        .info-box {
            padding: 16px;
            margin-bottom: 20px;
            border-radius: 10px;
            border-left: 4px solid;
            animation: slideIn 0.3s ease;
        }
        
        .info-box.success {
            background-color: var(--success-bg);
            border-left-color: var(--success-color);
        }
        
        .info-box.warning {
            background-color: var(--warning-bg);
            border-left-color: var(--warning-color);
        }
        
        .info-box.error {
            background-color: var(--error-bg);
            border-left-color: var(--error-color);
        }
        
        .info-box h4 {
            margin-top: 0;
            margin-bottom: 8px;
            font-size: clamp(16px, 4vw, 18px);
        }
        
        .info-box p {
            font-size: clamp(14px, 4vw, 15px);
            margin-bottom: 8px;
        }
        
        .info-box:last-child {
            margin-bottom: 0;
        }
        
        .form-group {
            margin-bottom: clamp(16px, 4vw, 20px);
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: var(--text-color);
            font-weight: 500;
            font-size: clamp(14px, 4vw, 15px);
        }
        
        .form-control {
            width: 100%;
            padding: 14px 16px;
            border: 1.5px solid var(--border-color);
            border-radius: 10px;
            font-size: clamp(16px, 4vw, 17px);
            transition: all 0.3s ease;
            background: var(--input-bg);
            -webkit-appearance: none;
            appearance: none;
        }
        
        .form-control:focus {
            border-color: var(--primary-color);
            outline: none;
            box-shadow: 0 0 0 3px rgba(7, 124, 108, 0.1);
            background: white;
        }
        
        /* Improve touch targets */
        .form-control,
        .login-btn {
            min-height: 48px;
        }
        
        .error-message {
            background-color: var(--error-bg);
            color: var(--error-color);
            padding: 14px 16px;
            border-radius: 10px;
            margin-bottom: 20px;
            border-left: 4px solid var(--error-color);
            font-size: clamp(14px, 4vw, 15px);
            animation: slideIn 0.3s ease;
        }
        
        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(-10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .login-btn {
            background: var(--primary-color);
            color: white;
            border: none;
            padding: 16px;
            border-radius: 10px;
            font-size: clamp(16px, 4vw, 18px);
            font-weight: 600;
            cursor: pointer;
            width: 100%;
            transition: all 0.3s ease;
            margin-top: 10px;
            touch-action: manipulation;
            user-select: none;
        }
        
        .login-btn:active {
            background: var(--primary-dark);
            transform: scale(0.98);
        }
        
        .login-btn:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
        }
        
        .login-footer {
            text-align: center;
            padding: 20px;
            color: var(--text-light);
            border-top: 1px solid #eee;
            font-size: clamp(13px, 3.5vw, 14px);
            background: var(--bg-color);
            position: sticky;
            bottom: 0;
        }
        
        .login-footer a {
            color: var(--primary-color);
            text-decoration: none;
            font-weight: 600;
            display: inline-block;
            padding: 8px 16px;
            border-radius: 8px;
            transition: background-color 0.3s ease;
        }
        
        .login-footer a:active {
            background-color: rgba(7, 124, 108, 0.1);
        }
        
        .required {
            color: #f44336;
        }
        
        .form-hint {
            font-size: clamp(12px, 3.5vw, 13px);
            color: var(--text-light);
            margin-top: 6px;
        }
        
        /* Loading spinner */
        .spinner {
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 3px solid rgba(255,255,255,.3);
            border-radius: 50%;
            border-top-color: white;
            animation: spin 1s ease-in-out infinite;
            margin-right: 10px;
            vertical-align: middle;
        }
        
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        
        /* Remember me checkbox */
        .remember-me {
            display: flex;
            align-items: center;
            margin-bottom: 20px;
            cursor: pointer;
            user-select: none;
        }
        
        .remember-me input[type="checkbox"] {
            margin-right: 10px;
            width: 18px;
            height: 18px;
            cursor: pointer;
            accent-color: var(--primary-color);
        }
        
        .remember-me label {
            margin: 0;
            cursor: pointer;
            font-size: clamp(14px, 4vw, 15px);
            color: var(--text-color);
        }
        
        /* Clear saved data button */
        .clear-saved {
            text-align: center;
            margin-top: 15px;
        }
        
        .clear-saved button {
            background: none;
            border: none;
            color: var(--text-light);
            font-size: clamp(12px, 3.5vw, 13px);
            text-decoration: underline;
            cursor: pointer;
            padding: 5px 10px;
        }
        
        .clear-saved button:hover {
            color: var(--error-color);
        }
        
        /* Keyboard avoiding for iOS */
        @media screen and (max-width: 768px) {
            .login-container {
                height: 100vh;
                height: -webkit-fill-available;
            }
            
            .login-body {
                padding-bottom: max(20px, env(safe-area-inset-bottom));
            }
        }
        
        /* Landscape mode adjustments */
        @media screen and (orientation: landscape) and (max-height: 600px) {
            .login-container {
                max-height: 95vh;
            }
            
            .login-header {
                padding: 15px;
            }
            
            .login-body {
                padding: 15px;
                overflow-y: auto;
            }
            
            .form-group {
                margin-bottom: 12px;
            }
        }
        
        /* High DPI devices */
        @media (-webkit-min-device-pixel-ratio: 2), (min-resolution: 192dpi) {
            .form-control {
                border-width: 0.75px;
            }
        }
        
        /* Dark mode support */
        @media (prefers-color-scheme: dark) {
            :root {
                --text-color: #e0e0e0;
                --text-light: #a0a0a0;
                --bg-color: #1e1e1e;
                --input-bg: #2d2d2d;
                --border-color: #404040;
                --success-bg: #1b5e20;
                --warning-bg: #ff6f00;
                --error-bg: #b71c1c;
            }
            
            body {
                background: linear-gradient(135deg, #065c50, #077C6C);
            }
            
            .login-header {
                background: #065c50;
            }
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="login-header">
            <h1>🔧 Supportive Cashier Login</h1>
            <p>Login to assist with number selection</p>
        </div>
        
        <div class="login-body">
            <?php if (!empty($error)): ?>
                <div class="error-message">
                    <strong>Error:</strong> <?php echo htmlspecialchars($error); ?>
                </div>
            <?php endif; ?>
            
            <?php if (!empty($main_cashier_info)): ?>
                <?php if (!$main_cashier_info['exists']): ?>
                    <div class="info-box error">
                        <h4>⚠️ Invalid Main Cashier</h4>
                        <p>The main cashier ID "<strong><?php echo htmlspecialchars($main_cashier_info['id']); ?></strong>" was not found.</p>
                        <p class="form-hint">Please check the invitation link or contact your main cashier.</p>
                    </div>
                <?php elseif (!$main_cashier_info['has_supportive_cashiers']): ?>
                    <div class="info-box warning">
                        <h4>ℹ️ No Supportive Cashiers</h4>
                        <p>Main cashier "<strong><?php echo htmlspecialchars($main_cashier_info['id']); ?></strong>" does not have any supportive cashiers assigned.</p>
                        <p class="form-hint">Please contact the main cashier to be added as a supportive cashier.</p>
                    </div>
                <?php else: ?>
                    <div class="info-box success">
                        <h4>✅ Login to Assist</h4>
                        <p>You are logging in to assist <strong><?php echo htmlspecialchars($main_cashier_info['id']); ?></strong></p>
                        <p class="form-hint">Please enter your supportive cashier credentials below.</p>
                    </div>
                <?php endif; ?>
            <?php endif; ?>
            
            <form method="POST" id="loginForm" autocomplete="on">
                <div class="form-group">
                    <label for="cashier_id">
                        Your Supportive Cashier ID <span class="required">*</span>
                    </label>
                    <input type="text" id="cashier_id" name="cashier_id" 
                           class="form-control" required 
                           placeholder="Enter your supportive cashier ID"
                           value="<?php echo isset($_POST['cashier_id']) ? htmlspecialchars($_POST['cashier_id']) : ''; ?>"
                           autocomplete="username"
                           autocapitalize="none">
                    <p class="form-hint">Your unique supportive cashier ID</p>
                </div>
                
                <div class="form-group">
                    <label for="password">
                        Password <span class="required">*</span>
                    </label>
                    <input type="password" id="password" name="password" 
                           class="form-control" required 
                           placeholder="Enter your password"
                           autocomplete="current-password">
                </div>
                
                <div class="remember-me">
                    <input type="checkbox" id="remember_me" name="remember_me">
                    <label for="remember_me">Remember me on this device</label>
                </div>
                
                <button type="submit" class="login-btn" id="loginButton">
                    Login as Supportive Cashier
                </button>
                
                <div class="clear-saved">
                    <button type="button" id="clearSavedData">Clear saved login data</button>
                </div>
            </form>
        </div>
        
        <div class="login-footer">
            <p>Need help? Contact your main cashier for assistance.</p>
            <p><a href="https://ethiomark.com/">↶ Back to main login</a></p>
        </div>
    </div>
    
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const loginForm = document.getElementById('loginForm');
            const loginButton = document.getElementById('loginButton');
            const cashierIdInput = document.getElementById('cashier_id');
            const passwordInput = document.getElementById('password');
            const rememberMeCheckbox = document.getElementById('remember_me');
            const clearSavedBtn = document.getElementById('clearSavedData');
            
            // Load saved credentials from localStorage
            function loadSavedCredentials() {
                try {
                    const savedData = localStorage.getItem('support_cashier_login');
                    if (savedData) {
                        const { cashier_id, remember_me } = JSON.parse(savedData);
                        if (cashier_id) {
                            cashierIdInput.value = cashier_id;
                        }
                        if (remember_me) {
                            rememberMeCheckbox.checked = true;
                            // Focus on password field if username is filled
                            if (cashier_id) {
                                passwordInput.focus();
                            }
                        }
                    }
                } catch (e) {
                    console.error('Error loading saved credentials:', e);
                    // Clear corrupted data
                    localStorage.removeItem('support_cashier_login');
                }
            }
            
            // Save credentials to localStorage
            function saveCredentials(cashierId, remember) {
                try {
                    if (remember) {
                        const data = {
                            cashier_id: cashierId,
                            remember_me: true,
                            timestamp: new Date().getTime()
                        };
                        localStorage.setItem('support_cashier_login', JSON.stringify(data));
                    } else {
                        localStorage.removeItem('support_cashier_login');
                    }
                } catch (e) {
                    console.error('Error saving credentials:', e);
                }
            }
            
            // Clear saved credentials
            function clearSavedCredentials() {
                localStorage.removeItem('support_cashier_login');
                cashierIdInput.value = '';
                passwordInput.value = '';
                rememberMeCheckbox.checked = false;
                showToast('Saved login data cleared');
            }
            
            // Show toast notification
            function showToast(message) {
                // Remove existing toast
                const existingToast = document.querySelector('.toast-notification');
                if (existingToast) {
                    existingToast.remove();
                }
                
                // Create new toast
                const toast = document.createElement('div');
                toast.className = 'toast-notification';
                toast.textContent = message;
                toast.style.cssText = `
                    position: fixed;
                    bottom: 80px;
                    left: 50%;
                    transform: translateX(-50%);
                    background: var(--primary-color);
                    color: white;
                    padding: 12px 20px;
                    border-radius: 8px;
                    font-size: 14px;
                    z-index: 1000;
                    animation: slideUp 0.3s ease;
                    box-shadow: 0 4px 12px rgba(0,0,0,0.2);
                    max-width: 90%;
                    text-align: center;
                `;
                
                // Add animation
                const style = document.createElement('style');
                style.textContent = `
                    @keyframes slideUp {
                        from { transform: translate(-50%, 100%); opacity: 0; }
                        to { transform: translate(-50%, 0); opacity: 1; }
                    }
                    @keyframes slideDown {
                        from { transform: translate(-50%, 0); opacity: 1; }
                        to { transform: translate(-50%, 100%); opacity: 0; }
                    }
                `;
                document.head.appendChild(style);
                
                document.body.appendChild(toast);
                
                // Remove toast after 3 seconds
                setTimeout(() => {
                    toast.style.animation = 'slideDown 0.3s ease';
                    setTimeout(() => toast.remove(), 300);
                }, 3000);
            }
            
            // Load saved credentials on page load
            loadSavedCredentials();
            
            // Focus on first empty field
            if (!cashierIdInput.value && window.innerWidth > 768) {
                cashierIdInput.focus();
            } else if (cashierIdInput.value && window.innerWidth > 768) {
                passwordInput.focus();
            }
            
            // Form validation
            loginForm.addEventListener('submit', function(e) {
                const cashierId = cashierIdInput.value.trim();
                const password = passwordInput.value.trim();
                const rememberMe = rememberMeCheckbox.checked;
                
                if (!cashierId || !password) {
                    e.preventDefault();
                    showMobileAlert('Please enter both cashier ID and password.');
                    return;
                }
                
                // Save credentials if remember me is checked
                saveCredentials(cashierId, rememberMe);
                
                // Show loading state
                loginButton.disabled = true;
                loginButton.innerHTML = '<span class="spinner"></span>Logging in...';
                loginButton.style.opacity = '0.7';
            });
            
            // Clear saved data button
            clearSavedBtn.addEventListener('click', clearSavedCredentials);
            
            // Clear saved data on checkbox uncheck
            rememberMeCheckbox.addEventListener('change', function() {
                if (!this.checked) {
                    // Only clear the saved data if user manually unchecks
                    const savedData = localStorage.getItem('support_cashier_login');
                    if (savedData) {
                        try {
                            const data = JSON.parse(savedData);
                            if (data.cashier_id === cashierIdInput.value) {
                                localStorage.removeItem('support_cashier_login');
                            }
                        } catch (e) {
                            // Ignore parsing errors
                        }
                    }
                }
            });
            
            // Function to show mobile-friendly alerts
            function showMobileAlert(message) {
                if ('Notification' in window && Notification.permission === 'granted') {
                    new Notification('Login Error', { body: message });
                } else {
                    alert(message);
                }
            }
            
            // Add visual feedback for touch
            document.querySelectorAll('.form-control').forEach(input => {
                input.addEventListener('touchstart', function() {
                    this.style.borderColor = 'var(--primary-color)';
                });
                
                input.addEventListener('touchend', function() {
                    if (!this.matches(':focus')) {
                        this.style.borderColor = 'var(--border-color)';
                    }
                });
            });
            
            // Handle virtual keyboard appearance
            let viewportHeight = window.innerHeight;
            window.addEventListener('resize', function() {
                if (window.innerHeight < viewportHeight) {
                    // Keyboard is showing
                    document.activeElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
                }
                viewportHeight = window.innerHeight;
            });
            
            // Auto-fill main cashier from URL if available
            const urlParams = new URLSearchParams(window.location.search);
            if (urlParams.has('main')) {
                // Already showing info box above
            }
            
            // Check for old saved data and migrate if needed
            function checkForOldSavedData() {
                try {
                    const oldCashierId = localStorage.getItem('cashier_id');
                    const oldRememberMe = localStorage.getItem('remember_me');
                    
                    if (oldCashierId) {
                        // Migrate old data to new format
                        const newData = {
                            cashier_id: oldCashierId,
                            remember_me: oldRememberMe === 'true',
                            timestamp: new Date().getTime()
                        };
                        localStorage.setItem('support_cashier_login', JSON.stringify(newData));
                        
                        // Clean up old data
                        localStorage.removeItem('cashier_id');
                        localStorage.removeItem('remember_me');
                        
                        // Reload the saved credentials
                        loadSavedCredentials();
                    }
                } catch (e) {
                    console.error('Error migrating old saved data:', e);
                }
            }
            
            // Run migration check
            checkForOldSavedData();
        });
        
        // Prevent form resubmission on page refresh
        if (window.history.replaceState) {
            window.history.replaceState(null, null, window.location.href);
        }
    </script>
</body>
</html>