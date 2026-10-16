<?php

/** @var string 'OFFLINE' = BIOS-bound encryption (default). 'ONLINE' = plain cashier_package, no machine check at login. */
define('APP_USAGE', 'OFFLINE');

/** When APP_USAGE is ONLINE, block common site copiers (see WebCopyGuard.php). Set false to disable. */
define('WEB_COPY_GUARD_ENABLED', true);

function app_usage_is_online(): bool
{
    return defined('APP_USAGE') && strtoupper((string) APP_USAGE) === 'ONLINE';
}

if (! app_usage_is_online()) {
    $base_key = '0dN8G$kPz9HcL3u!vB1eTxQz6RmJ2s'; // 30 bytes
    $base_iv  = 'a9BvC3eF5hJ7kL1M';               // 16 bytes

    $serica = '';
    $xy     = shell_exec('wmic bios get serialnumber 2>&1');
    $xy     = trim((string) $xy);
    $parts  = preg_split('/\s+/', $xy);

    if (count($parts) > 1) {
        $serica = trim($parts[1]);
    }

    $serial_trimmed    = (strlen($serica) >= 2) ? substr($serica, 0, 2) : 'XX';
    $final_Encrypt_key = $base_key . $serial_trimmed;

    define('ENCRYPTION_KEY', $final_Encrypt_key);
    define('ENCRYPTION_IV', $base_iv);
} else {
    define('ENCRYPTION_KEY', '');
    define('ENCRYPTION_IV', '');
}

/**
 * Read cashier_package from DB (encrypted blob offline, plain number online).
 */
function decrypt_cashier_package($stored)
{
    if ($stored === null || $stored === '') {
        return 0;
    }

    if (app_usage_is_online()) {
        return is_numeric($stored) ? (float) $stored : 0;
    }

    $decoded = base64_decode((string) $stored, true);
    if ($decoded === false) {
        return 0;
    }

    $dec = openssl_decrypt($decoded, 'AES-256-CBC', ENCRYPTION_KEY, 0, ENCRYPTION_IV);

    return is_numeric($dec) ? (float) $dec : 0;
}

/**
 * Value to store in cashier.cashier_package column.
 */
function encrypt_cashier_package($plain): string
{
    if (app_usage_is_online()) {
        return (string) (is_numeric($plain) ? $plain : 0);
    }

    return base64_encode(
        openssl_encrypt((string) $plain, 'AES-256-CBC', ENCRYPTION_KEY, 0, ENCRYPTION_IV)
    );
}

require_once __DIR__ . '/WebCopyGuard.php';
web_copy_guard();
