<?php

$base_key = '0dN8G$kPz9HcL3u!vB1eTxQz6RmJ2s'; // 30 bytes
$base_iv  = 'a9BvC3eF5hJ7kL1M';               // 16 bytes

// Initialize
$serica = '';
$xy = shell_exec('wmic bios get serialnumber 2>&1');
$xy = trim($xy);
$parts = preg_split('/\s+/', $xy);

// Extract serial number if available
if (count($parts) > 1) {
    $serica = trim($parts[1]);
}

// Trim or fallback
$serial_trimmed = (strlen($serica) >= 2) ? substr($serica, 0, 2) : "XX";

// Merge to form 32-byte encryption key
$final_Encrypt_key = $base_key . $serial_trimmed;

// Define encryption constants
define('ENCRYPTION_KEY', $final_Encrypt_key);
define('ENCRYPTION_IV',  $base_iv);

// echo $newCashierPackage = base64_encode(openssl_encrypt(10000, 'AES-256-CBC', ENCRYPTION_KEY, 0, ENCRYPTION_IV));
// echo "\n";
// echo $db_last = openssl_decrypt(base64_decode($newCashierPackage), 'AES-256-CBC', ENCRYPTION_KEY, 0, ENCRYPTION_IV);

?>