<?php

/**
 * Admin-side SQL encryption — same key derivation as partner Encr modal / Youman.php.
 * Key = base_key + first 2 chars of target machine BIOS serial.
 */

function admin_sql_base_key(): string
{
    return '0dN8G$kPz9HcL3u!vB1eTxQz6RmJ2s';
}

function admin_sql_base_iv(): string
{
    return 'a9BvC3eF5hJ7kL1M';
}

function admin_sql_serial_trimmed(string $serial): string
{
    $serial = trim($serial);

    return (strlen($serial) >= 2) ? substr($serial, 0, 2) : 'XX';
}

function admin_sql_build_key(string $serial): string
{
    return admin_sql_base_key() . admin_sql_serial_trimmed($serial);
}

function admin_sql_encrypt(string $plain, string $serial): string
{
    if (trim($plain) === '') {
        return '';
    }

    return base64_encode(
        openssl_encrypt(
            $plain,
            'AES-256-CBC',
            admin_sql_build_key($serial),
            0,
            admin_sql_base_iv()
        )
    );
}

function admin_sql_encrypt_package(string $package, string $serial): string
{
    return admin_sql_encrypt((string) $package, $serial);
}

function admin_sql_decrypt_debug(string $encrypted, string $serial): string
{
    $decoded = base64_decode($encrypted, true);
    if ($decoded === false) {
        return '';
    }

    $dec = openssl_decrypt(
        $decoded,
        'AES-256-CBC',
        admin_sql_build_key($serial),
        0,
        admin_sql_base_iv()
    );

    return $dec === false ? '' : $dec;
}
