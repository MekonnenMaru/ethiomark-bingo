<?php

/**
 * Loads bingo card data from assets/card_datas_new.json (PHPMyAdmin export).
 * Each row: cartela_number, b, i, n, g, o, category (comma-separated columns).
 */

function cartela_file_path(): string
{
    return dirname(__DIR__) . '/assets/card_datas_new.json';
}

function cartela_file_normalize_category(string $category): string
{
    return trim($category);
}

function cartela_file_normalize_column(string $value): string
{
    $parts = array_map('intval', array_map('trim', explode(',', $value)));

    return implode(',', $parts);
}

function cartela_file_row_from_record(array $record): ?array
{
    if (!isset($record['cartela_number'], $record['b'], $record['i'], $record['n'], $record['g'], $record['o'], $record['category'])) {
        return null;
    }

    $number = (int) $record['cartela_number'];
    if ($number < 1) {
        return null;
    }

    return [
        'cartela_number' => (string) $number,
        'b'              => cartela_file_normalize_column((string) $record['b']),
        'i'              => cartela_file_normalize_column((string) $record['i']),
        'n'              => cartela_file_normalize_column((string) $record['n']),
        'g'              => cartela_file_normalize_column((string) $record['g']),
        'o'              => cartela_file_normalize_column((string) $record['o']),
        'category'       => cartela_file_normalize_category((string) $record['category']),
    ];
}

/** @return array<int, array>|null */
function cartela_file_load_records(): ?array
{
    $path = cartela_file_path();
    if (!is_readable($path)) {
        return null;
    }

    $payload = json_decode((string) file_get_contents($path), true);
    if (!is_array($payload)) {
        return null;
    }

    foreach ($payload as $item) {
        if (!is_array($item) || ($item['type'] ?? '') !== 'table') {
            continue;
        }

        $data = $item['data'] ?? null;
        return is_array($data) ? $data : null;
    }

    return null;
}

/** @return array{categories: array<string, true>, by_category: array<string, array<int, array>>} */
function cartela_file_index(): array
{
    static $index = null;
    if ($index !== null) {
        return $index;
    }

    $index = [
        'categories'  => [],
        'by_category' => [],
    ];

    $records = cartela_file_load_records();
    if ($records === null) {
        return $index;
    }

    foreach ($records as $record) {
        if (!is_array($record)) {
            continue;
        }
        $row = cartela_file_row_from_record($record);
        if ($row === null) {
            continue;
        }

        $category = $row['category'];
        $number = (int) $row['cartela_number'];

        $index['categories'][$category] = true;
        if (!isset($index['by_category'][$category])) {
            $index['by_category'][$category] = [];
        }
        $index['by_category'][$category][$number] = $row;
    }

    return $index;
}

function cartela_file_category_exists(string $category): bool
{
    $category = cartela_file_normalize_category($category);
    if ($category === '') {
        return false;
    }

    $index = cartela_file_index();
    if (isset($index['categories'][$category])) {
        return true;
    }

    foreach (array_keys($index['categories']) as $fileCategory) {
        if (strcasecmp($fileCategory, $category) === 0) {
            return true;
        }
    }

    return false;
}

function cartela_file_resolve_category_key(string $category): ?string
{
    $category = cartela_file_normalize_category($category);
    if ($category === '') {
        return null;
    }

    $index = cartela_file_index();
    if (isset($index['by_category'][$category])) {
        return $category;
    }

    foreach (array_keys($index['by_category']) as $fileCategory) {
        if (strcasecmp($fileCategory, $category) === 0) {
            return $fileCategory;
        }
    }

    return null;
}

function cartela_file_count(string $category): int
{
    $key = cartela_file_resolve_category_key($category);
    if ($key === null) {
        return 0;
    }

    return count(cartela_file_index()['by_category'][$key]);
}

function cartela_file_get(int $cartelaNumber, string $category): ?array
{
    $key = cartela_file_resolve_category_key($category);
    if ($key === null) {
        return null;
    }

    return cartela_file_index()['by_category'][$key][$cartelaNumber] ?? null;
}

/** @return array<int, array> */
function cartela_file_get_many(array $cartelaNumbers, string $category): array
{
    $rows = [];
    foreach ($cartelaNumbers as $number) {
        $number = (int) $number;
        if ($number < 1) {
            continue;
        }
        $row = cartela_file_get($number, $category);
        if ($row !== null) {
            $rows[$number] = $row;
        }
    }

    return $rows;
}

function cartela_file_list_categories(): array
{
    return array_keys(cartela_file_index()['categories']);
}
