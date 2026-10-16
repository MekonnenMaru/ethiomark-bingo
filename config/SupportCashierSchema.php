<?php

/**
 * Support-cashier tables for collaborative card selection.
 * support_cashier_id pattern: c1@MAIN_ID, c2@MAIN_ID, ...
 */

const SUPPORT_CASHIER_DEFAULT_PASSWORD_HASH = 'a01610228fe998f515a72dd730294d87';

function support_cashier_ensure_tables($conn): bool
{
    static $ensured = false;
    if ($ensured) {
        return true;
    }

    $statements = [
        "CREATE TABLE IF NOT EXISTS `collaborative_selections` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `round_number` int(11) NOT NULL,
            `main_cashier_id` varchar(50) NOT NULL,
            `support_cashier_id` varchar(50) NOT NULL,
            `cartela_number` int(11) NOT NULL,
            `is_selected` tinyint(1) DEFAULT 1,
            `selected_time` timestamp NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_card_per_round` (`round_number`,`main_cashier_id`,`cartela_number`),
            KEY `idx_main_round` (`main_cashier_id`,`round_number`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci",

        "CREATE TABLE IF NOT EXISTS `support_cashiers` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `main_cashier_id` varchar(50) NOT NULL,
            `support_cashier_id` varchar(50) NOT NULL,
            `password` varchar(256) NOT NULL DEFAULT '" . SUPPORT_CASHIER_DEFAULT_PASSWORD_HASH . "',
            `is_active` tinyint(1) DEFAULT 1,
            `assigned_date` timestamp NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_support` (`main_cashier_id`,`support_cashier_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci",

        "CREATE TABLE IF NOT EXISTS `support_preferences` (
            `support_cashier_id` varchar(50) NOT NULL,
            `color_code` varchar(7) DEFAULT '#FF5733',
            `preferences` text DEFAULT NULL,
            `last_active` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
            PRIMARY KEY (`support_cashier_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci",
    ];

    foreach ($statements as $sql) {
        if (!$conn->query($sql)) {
            error_log('SupportCashierSchema: ' . $conn->error);

            return false;
        }
    }

    $ensured = true;

    return true;
}

function support_cashier_ensure_defaults($conn, string $mainCashierId): void
{
    if (!support_cashier_ensure_tables($conn)) {
        return;
    }

    $mainCashierId = trim($mainCashierId);
    if ($mainCashierId === '') {
        return;
    }

    $stmt = $conn->prepare('SELECT COUNT(*) FROM support_cashiers WHERE main_cashier_id = ?');
    if (!$stmt) {
        return;
    }

    $stmt->bind_param('s', $mainCashierId);
    $stmt->execute();
    $stmt->bind_result($count);
    $stmt->fetch();
    $stmt->close();

    if ((int) $count > 0) {
        return;
    }

    $colors = ['#ff5733', '#1f13c3', '#fff700', '#ee00ff', '#00ffff'];
    $defaultPassword = SUPPORT_CASHIER_DEFAULT_PASSWORD_HASH;

    $insertCashier = $conn->prepare(
        'INSERT IGNORE INTO support_cashiers (main_cashier_id, support_cashier_id, password, is_active)
         VALUES (?, ?, ?, 1)'
    );
    $insertPref = $conn->prepare(
        'INSERT IGNORE INTO support_preferences (support_cashier_id, color_code) VALUES (?, ?)'
    );

    if (!$insertCashier || !$insertPref) {
        return;
    }

    for ($i = 1; $i <= 5; $i++) {
        $supportId = 'c' . $i . '@' . $mainCashierId;
        $color = $colors[$i - 1] ?? '#FF5733';

        $insertCashier->bind_param('sss', $mainCashierId, $supportId, $defaultPassword);
        $insertCashier->execute();

        $insertPref->bind_param('ss', $supportId, $color);
        $insertPref->execute();
    }

    $insertCashier->close();
    $insertPref->close();
}
