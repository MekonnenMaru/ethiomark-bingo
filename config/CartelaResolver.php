<?php

require_once __DIR__ . '/CartelaFileService.php';

function cartela_should_use_file(string $category): bool
{
    return cartela_file_category_exists($category);
}

function cartela_get_cashier_category($conn, string $cashierId): string
{
    $stmt = $conn->prepare('SELECT category FROM cashier WHERE cashier_id = ? LIMIT 1');
    $stmt->bind_param('s', $cashierId);
    $stmt->execute();
    $stmt->bind_result($category);
    $found = $stmt->fetch();
    $stmt->close();

    return $found ? (string) $category : '';
}

function cartela_count_by_category($conn, string $category): int
{
    if (cartela_should_use_file($category)) {
        return cartela_file_count($category);
    }

    $stmt = $conn->prepare('SELECT COUNT(cartela_number) FROM cartela WHERE category = ?');
    $stmt->bind_param('s', $category);
    $stmt->execute();
    $stmt->bind_result($count);
    $stmt->fetch();
    $stmt->close();

    return (int) $count;
}

function cartela_count_for_cashier($conn, string $cashierId): int
{
    $category = cartela_get_cashier_category($conn, $cashierId);
    if ($category === '') {
        return 0;
    }

    return cartela_count_by_category($conn, $category);
}

function cartela_fetch_one($conn, int $cartelaNumber, string $category): ?array
{
    if (cartela_should_use_file($category)) {
        $row = cartela_file_get($cartelaNumber, $category);
        if ($row !== null) {
            return $row;
        }
    }

    $stmt = $conn->prepare(
        'SELECT cartela_number, b, i, n, g, o, category
         FROM cartela WHERE cartela_number = ? AND category = ? LIMIT 1'
    );
    $num = (string) $cartelaNumber;
    $stmt->bind_param('ss', $num, $category);
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result ? $result->fetch_assoc() : null;
    $stmt->close();

    return $row ?: null;
}

/**
 * @param int[] $cartelaNumbers
 * @return array<int, array>
 */
function cartela_fetch_many($conn, array $cartelaNumbers, string $category): array
{
    $cartelaNumbers = array_values(array_unique(array_map('intval', $cartelaNumbers)));
    $cartelaNumbers = array_values(array_filter($cartelaNumbers, static fn($n) => $n > 0));

    if (empty($cartelaNumbers)) {
        return [];
    }

    $rows = [];

    if (cartela_should_use_file($category)) {
        $rows = cartela_file_get_many($cartelaNumbers, $category);
    }

    $missing = array_values(array_diff($cartelaNumbers, array_map('intval', array_keys($rows))));
    if (empty($missing)) {
        return $rows;
    }

    $placeholders = implode(',', array_fill(0, count($missing), '?'));
    $types = str_repeat('i', count($missing)) . 's';
    $params = $missing;
    $params[] = $category;

    $sql = "SELECT cartela_number, b, i, n, g, o, category
            FROM cartela
            WHERE cartela_number IN ($placeholders) AND category = ?";

    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        return $rows;
    }

    $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();

    while ($result && ($row = $result->fetch_assoc())) {
        $rows[(int) $row['cartela_number']] = $row;
    }

    $stmt->close();

    return $rows;
}

/** @return array<int, array> */
function cartela_fetch_all_for_category($conn, string $category): array
{
    if (cartela_should_use_file($category)) {
        $key = cartela_file_resolve_category_key($category);
        if ($key !== null) {
            return cartela_file_index()['by_category'][$key];
        }
    }

    $stmt = $conn->prepare(
        'SELECT cartela_number, b, i, n, g, o, category FROM cartela WHERE category = ?'
    );
    $stmt->bind_param('s', $category);
    $stmt->execute();
    $result = $stmt->get_result();

    $rows = [];
    while ($result && ($row = $result->fetch_assoc())) {
        $rows[(int) $row['cartela_number']] = $row;
    }
    $stmt->close();

    return $rows;
}
