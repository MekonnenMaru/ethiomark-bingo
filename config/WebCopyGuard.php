<?php

/**
 * Blocks common site copiers / mirroring tools when APP_USAGE is ONLINE.
 * Not foolproof — deters HTTrack-style rips; browsers are unaffected.
 */
function web_copy_guard(): void
{
    static $ran = false;
    if ($ran || php_sapi_name() === 'cli') {
        return;
    }
    $ran = true;

    if (! defined('APP_USAGE') || strtoupper((string) APP_USAGE) !== 'ONLINE') {
        return;
    }

    if (defined('WEB_COPY_GUARD_ENABLED') && WEB_COPY_GUARD_ENABLED === false) {
        return;
    }

    $ua = strtolower(trim((string) ($_SERVER['HTTP_USER_AGENT'] ?? '')));

    if ($ua === '') {
        web_copy_guard_deny('empty user agent');

        return;
    }

    $blocked = [
        'httrack',
        'webcopier',
        'teleport pro',
        'teleportpro',
        'webzip',
        'sitesucker',
        'offline explorer',
        'blackwidow',
        'webstripper',
        'webcapture',
        'webdownloader',
        'webdup',
        'webwhacker',
        'netants',
        'flashget',
        'mass downloader',
        'pagegrabber',
        'sitesnagger',
        'tweakmaster',
        'extractorpro',
        'webbandit',
        'webmirror',
        'webcopy',
        'sitecopy',
        'mirror',
        'libwww-perl',
        'lwp-trivial',
        'python-urllib',
        'python-requests',
        'scrapy',
        'aiohttp',
        'httpclient',
        'go-http-client',
        'java/',
        'okhttp',
        'colly',
        'node-fetch',
        'nikto',
        'sqlmap',
        'masscan',
    ];

    foreach ($blocked as $needle) {
        if (str_contains($ua, $needle)) {
            web_copy_guard_deny('blocked client');

            return;
        }
    }

    header('X-Robots-Tag: noindex, noarchive, nosnippet, noimageindex', true);
}

function web_copy_guard_deny(string $reason = ''): void
{
    if ($reason !== '') {
        header('X-WebCopy-Guard: ' . $reason, true);
    }
    http_response_code(403);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Access denied.';
    exit;
}
