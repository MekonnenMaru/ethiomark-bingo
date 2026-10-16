<?php

/**
 * Dev router for: php -S localhost:8000 router.php
 * Serves static assets directly so PHP does not handle every .wav/.css request.
 */

$uri = urldecode(parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?? '/');
$path = __DIR__ . $uri;

if ($uri !== '/' && is_file($path)) {
    return false;
}

$cashierIndex = __DIR__ . '/cashier/index.php';
if ($uri === '/' || $uri === '/index.php') {
    require $cashierIndex;
    return true;
}

if (is_dir(__DIR__ . $uri)) {
    $try = __DIR__ . rtrim($uri, '/') . '/index.php';
    if (is_file($try)) {
        require $try;
        return true;
    }
}

http_response_code(404);
echo 'Not found';
