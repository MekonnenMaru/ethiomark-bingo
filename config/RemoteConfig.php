<?php

const REMOTE_DEFAULT_DOMAIN = 'ethiomark.com';

function remote_domain_file(): string
{
    return __DIR__ . '/remote.domain.php';
}

function remote_normalize_domain(string $value): string
{
    $value = trim($value);
    $value = preg_replace('#^https?://#i', '', $value);
    $value = preg_replace('#/.*$#', '', $value);
    $value = trim($value, '.');

    // If user pasted full host like off1919.ethiomark.com, keep only the base domain.
    if (preg_match('/^off1919\.(.+)$/i', $value, $m)) {
        $value = $m[1];
    }

    return strtolower($value);
}

function remote_get_domain(): string
{
    static $domain = null;
    if ($domain !== null) {
        return $domain;
    }

    $domain = REMOTE_DEFAULT_DOMAIN;
    $domainFile = remote_domain_file();

    if (is_file($domainFile)) {
        $value = require $domainFile;
        if (is_string($value)) {
            $domain = remote_normalize_domain($value);
        } elseif (is_array($value) && !empty($value['domain'])) {
            $domain = remote_normalize_domain((string) $value['domain']);
        }
    }

    if ($domain === '') {
        $domain = REMOTE_DEFAULT_DOMAIN;
    }

    return $domain;
}

function remote_save_domain(string $domain): bool
{
    $domain = remote_normalize_domain($domain);
    if ($domain === '' || !preg_match('/^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$/i', $domain)) {
        return false;
    }

    $content = '<?php

/**
 * Remote admin base domain — change this when your domain changes.
 *
 * Full URL (built automatically):
 *   https://off1919.{domain}/admin/sync_cashier_package.php
 *
 * Default: ethiomark.com
 * You can also edit this in cashier Settings (password required).
 */
return ' . var_export($domain, true) . ';
';

    return file_put_contents(remote_domain_file(), $content) !== false;
}

function remote_sync_url(): string
{
    $domain = trim(remote_get_domain(), '.');
    $host = 'off1919.' . $domain;

    return 'https://' . $host . '/admin/sync_cashier_package.php';
}
