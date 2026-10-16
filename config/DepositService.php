<?php

require_once __DIR__ . '/RemoteConfig.php';
require_once __DIR__ . '/Youman.php';

function deposit_remote_session_start(): void
{
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
}

/** Report page only: remote admin reachable while package modal is open. */
function deposit_remote_is_allowed(): bool
{
    deposit_remote_session_start();
    if (empty($_SESSION['package_remote_enabled'])) {
        return false;
    }
    $openedAt = (int) $_SESSION['package_remote_enabled'];
    if (time() - $openedAt > 300) {
        unset($_SESSION['package_remote_enabled']);
        return false;
    }
    return true;
}

function deposit_remote_enable(): void
{
    deposit_remote_session_start();
    $_SESSION['package_remote_enabled'] = time();
}

function deposit_remote_disable(): void
{
    deposit_remote_session_start();
    unset($_SESSION['package_remote_enabled']);
}

function deposit_remote_post(array $data): array
{
    if (!deposit_remote_is_allowed()) {
        return [
            'ok'      => false,
            'blocked' => true,
            'message' => 'Remote connection is only available while the package modal is open.',
        ];
    }

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, remote_sync_url());
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 12);
    curl_setopt($ch, CURLOPT_TIMEOUT, 20);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);

    $body = curl_exec($ch);
    $errno = curl_errno($ch);
    $error = curl_error($ch);
    curl_close($ch);

    if ($errno) {
        return [
            'ok'      => false,
            'offline' => true,
            'message' => 'Unable to reach admin server. Check internet connection.',
            'curl_error' => $error,
        ];
    }

    $decoded = json_decode((string) $body, true);
    if (!is_array($decoded)) {
        return [
            'ok' => false,
            'message' => 'Invalid response from admin server.',
        ];
    }

    return [
        'ok'   => true,
        'data' => $decoded,
    ];
}

function read_cashier_package_balance($conn, string $cashierId): float
{
    $stmt = $conn->prepare('SELECT cashier_package FROM cashier WHERE cashier_id = ?');
    $stmt->bind_param('s', $cashierId);
    $stmt->execute();
    $stmt->bind_result($encrypted);
    $found = $stmt->fetch();
    $stmt->close();

    if (!$found || $encrypted === null || $encrypted === '') {
        return 0.0;
    }

    $value = openssl_decrypt(
        base64_decode($encrypted),
        'AES-256-CBC',
        ENCRYPTION_KEY,
        0,
        ENCRYPTION_IV
    );

    return is_numeric($value) ? (float) $value : 0.0;
}

function write_cashier_package_balance($conn, string $cashierId, float $balance): bool
{
    $encrypted = base64_encode(
        openssl_encrypt(
            (string) $balance,
            'AES-256-CBC',
            ENCRYPTION_KEY,
            0,
            ENCRYPTION_IV
        )
    );

    $stmt = $conn->prepare('UPDATE cashier SET cashier_package = ? WHERE cashier_id = ?');
    $stmt->bind_param('ss', $encrypted, $cashierId);
    $ok = $stmt->execute();
    $stmt->close();

    return $ok;
}

/**
 * Apply a signed package change. Positive = deposit, negative = withdrawal.
 *
 * @return array{ok:bool, message?:string, code?:string, previous_balance?:float, new_balance?:float, balance?:float}
 */
function deposit_apply_package_delta($conn, string $cashierId, float $delta): array
{
    if ($delta == 0.0) {
        return [
            'ok'      => false,
            'code'    => 'invalid_deposit_amount',
            'message' => 'Amount cannot be zero.',
        ];
    }

    $previousBalance = read_cashier_package_balance($conn, $cashierId);
    $newBalance      = $previousBalance + $delta;

    if ($delta < 0 && $newBalance < 0) {
        return [
            'ok'               => false,
            'code'             => 'insufficient_wallet_balance',
            'message'          => 'Insufficient wallet balance for withdrawal.',
            'previous_balance' => $previousBalance,
            'balance'          => $previousBalance,
        ];
    }

    if (!write_cashier_package_balance($conn, $cashierId, $newBalance)) {
        return [
            'ok'      => false,
            'message' => 'Failed to save encrypted package balance locally.',
        ];
    }

    return [
        'ok'               => true,
        'previous_balance' => $previousBalance,
        'new_balance'      => $newBalance,
    ];
}

function deposit_add_cashier_package($conn, string $cashierId, float $depositAmount): bool
{
    $result = deposit_apply_package_delta($conn, $cashierId, $depositAmount);

    return !empty($result['ok']);
}

function deposit_log_exists($conn, $transactionId): bool
{
    $transactionId = trim((string) $transactionId);
    if ($transactionId === '') {
        return false;
    }

    $stmt = $conn->prepare('SELECT COUNT(*) FROM transaction_logs WHERE transaction_id = ?');
    $stmt->bind_param('s', $transactionId);
    $stmt->execute();
    $stmt->bind_result($count);
    $stmt->fetch();
    $stmt->close();

    return (int) $count > 0;
}

function deposit_insert_log($conn, array $transaction, string $cashierId, $partnerId): bool
{
    $transactionId = trim((string) ($transaction['transaction_id'] ?? ''));
    if ($transactionId === '' || deposit_log_exists($conn, $transactionId)) {
        return false;
    }

    $stmt = $conn->prepare(
        'INSERT INTO transaction_logs
        (transaction_id, event_type, timestamp, done_by, role, action, amount, cashier_id, partner_id, status, message)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
    );

    $stmt->bind_param(
        'ssssssdssss',
        $transactionId,
        $transaction['event_type'],
        $transaction['timestamp'],
        $transaction['done_by'],
        $transaction['role'],
        $transaction['action'],
        $transaction['amount'],
        $cashierId,
        $partnerId,
        $transaction['status'],
        $transaction['message']
    );

    $ok = $stmt->execute();
    $stmt->close();

    return $ok;
}

function deposit_ack_remote_package(string $cashierId, $partnerId, string $transactionId = '', bool $duplicateLocal = false): array
{
    $payload = [
        'cashier_id'    => $cashierId,
        'partner_id'    => $partnerId,
        'request_type'  => 'cashier_package_confirm_is_ok',
        'clear_pending' => '1',
    ];

    if ($transactionId !== '') {
        $payload['transaction_id'] = $transactionId;
    }
    if ($duplicateLocal) {
        $payload['duplicate_local'] = '1';
    }

    $result = deposit_remote_post($payload);

    return [
        'ok'      => $result['ok'] && (($result['data']['status'] ?? '') === 'success'),
        'message' => (string) ($result['data']['message'] ?? $result['message'] ?? ''),
    ];
}

function deposit_format_code_block(array $display): string
{
    $amount = (float) ($display['deposit_amount'] ?? 0);
    $isWithdrawal = $amount < 0;
    $title = $isWithdrawal ? 'PACKAGE WITHDRAWAL RESULT' : 'PACKAGE DEPOSIT RESULT';
    $amountLabel = $isWithdrawal ? 'Withdrawal' : 'Deposit';

    $lines = [
        '==========================================',
        '         ' . $title,
        '==========================================',
        'Cashier     : ' . (string) ($display['cashier_id'] ?? ''),
        $amountLabel . str_repeat(' ', max(1, 11 - strlen($amountLabel))) . ': '
            . number_format($amount, 2) . ' Birr',
        'Old balance : ' . number_format((float) ($display['previous_balance'] ?? 0), 2) . ' Birr',
        'New balance : ' . number_format((float) ($display['new_balance'] ?? 0), 2) . ' Birr',
        '------------------------------------------',
        'Remote OK   : ' . (($display['confirmed_remote'] ?? false) ? 'Yes' : 'No'),
        '==========================================',
    ];

    return implode("\n", $lines);
}

function deposit_sync_cashier_settings($conn, string $cashierId, $partnerId): void
{
    $result = deposit_remote_post([
        'cashier_id'   => $cashierId,
        'partner_id'   => $partnerId,
        'request_type' => 'get_cashier_information_for_update',
    ]);

    if (!$result['ok'] || ($result['data']['status'] ?? '') !== 'success') {
        return;
    }

    $remote = $result['data']['data'] ?? [];
    if (!$remote) {
        return;
    }

    $stmt = $conn->prepare(
        'SELECT is_locked, is_active, login_attempts, category, cashier_profit, cashier_bonus_status, cashier_fixed_bonus_amount
         FROM cashier WHERE cashier_id = ? AND partner_id = ?'
    );
    $stmt->bind_param('ss', $cashierId, $partnerId);
    $stmt->execute();
    $local = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$local) {
        return;
    }

    $shouldUpdate = (
        (string) ($remote['is_locked'] ?? '') !== (string) $local['is_locked']
        || (string) ($remote['is_active'] ?? '') !== (string) $local['is_active']
        || (string) ($remote['login_attempts'] ?? '') !== (string) $local['login_attempts']
        || (string) ($remote['category'] ?? '') !== (string) $local['category']
        || (string) ($remote['cashier_profit'] ?? '') !== (string) $local['cashier_profit']
        || (string) ($remote['cashier_bonus_status'] ?? '') !== (string) $local['cashier_bonus_status']
        || (string) ($remote['cashier_fixed_bonus_amount'] ?? '') !== (string) $local['cashier_fixed_bonus_amount']
    );

    if (!$shouldUpdate) {
        return;
    }

    $update = $conn->prepare(
        'UPDATE cashier SET
            is_locked = ?, is_active = ?, login_attempts = ?, category = ?,
            cashier_profit = ?, cashier_bonus_status = ?, cashier_fixed_bonus_amount = ?
         WHERE cashier_id = ? AND partner_id = ?'
    );
    $update->bind_param(
        'sssssssss',
        $remote['is_locked'],
        $remote['is_active'],
        $remote['login_attempts'],
        $remote['category'],
        $remote['cashier_profit'],
        $remote['cashier_bonus_status'],
        $remote['cashier_fixed_bonus_amount'],
        $cashierId,
        $partnerId
    );
    $update->execute();
    $update->close();
}

function deposit_sync_package($conn, string $cashierId): array
{
    $stmt = $conn->prepare('SELECT partner_id FROM cashier WHERE cashier_id = ?');
    $stmt->bind_param('s', $cashierId);
    $stmt->execute();
    $stmt->bind_result($partnerId);
    $found = $stmt->fetch();
    $stmt->close();

    if (!$found) {
        return [
            'status'  => 'error',
            'message' => 'Cashier not found on this device.',
        ];
    }

    $previousBalance = read_cashier_package_balance($conn, $cashierId);

    $remote = deposit_remote_post([
        'cashier_id'   => $cashierId,
        'partner_id'   => $partnerId,
        'request_type' => 'fetch_cashier_package',
    ]);

    if (!$remote['ok']) {
        if (!empty($remote['blocked'])) {
            return [
                'status'  => 'error',
                'message' => $remote['message'],
            ];
        }
        if (!empty($remote['offline'])) {
            return [
                'status'  => 'offline',
                'message' => $remote['message'],
                'display' => [
                    'cashier_id'       => $cashierId,
                    'previous_balance' => $previousBalance,
                    'new_balance'      => $previousBalance,
                ],
                'code_block' => "======================================\n  OFFLINE - NO DEPOSIT FETCHED\n======================================",
            ];
        }

        return [
            'status'  => 'error',
            'message' => $remote['message'] ?? 'Remote request failed.',
        ];
    }

    $response = $remote['data'];
    if (($response['status'] ?? '') !== 'success') {
        return [
            'status'  => 'error',
            'message' => $response['message'] ?? 'Admin server returned an error.',
        ];
    }

    $remoteAmount = (float) ($response['cashier_package'] ?? 0);
    $transaction  = $response['transaction'] ?? null;

    if ($remoteAmount == 0.0) {
        deposit_sync_cashier_settings($conn, $cashierId, $partnerId);

        return [
            'status'  => 'empty',
            'message' => 'No pending package change on admin server.',
            'display' => [
                'cashier_id'       => $cashierId,
                'deposit_amount'   => 0,
                'previous_balance' => $previousBalance,
                'new_balance'      => $previousBalance,
            ],
            'code_block' => "======================================\n  NO PENDING PACKAGE AVAILABLE\n======================================",
        ];
    }

    if (!is_array($transaction) || trim((string) ($transaction['transaction_id'] ?? '')) === '') {
        return [
            'status'  => 'error',
            'message' => 'Admin response missing transaction_id — deposit blocked to prevent duplicates.',
        ];
    }

    $transactionId = trim((string) $transaction['transaction_id']);

    if (isset($transaction['amount']) && is_numeric($transaction['amount'])) {
        $remoteAmount = (float) $transaction['amount'];
    }

    if (deposit_log_exists($conn, $transactionId)) {
        $ack = deposit_ack_remote_package($cashierId, $partnerId, $transactionId, true);
        deposit_sync_cashier_settings($conn, $cashierId, $partnerId);

        $display = [
            'cashier_id'       => $cashierId,
            'deposit_amount'   => $remoteAmount,
            'previous_balance' => $previousBalance,
            'new_balance'      => $previousBalance,
            'transaction_id'   => $transactionId,
            'confirmed_remote' => $ack['ok'],
        ];

        return [
            'status'     => 'duplicate',
            'message'    => $ack['ok']
                ? 'Already applied on this device. Admin pending deposit cleared.'
                : 'Already applied on this device. Could not clear admin pending — tap Re-fetch.',
            'display'    => $display,
            'code_block' => deposit_format_code_block($display),
        ];
    }

    $apply = deposit_apply_package_delta($conn, $cashierId, $remoteAmount);
    if (empty($apply['ok'])) {
        return [
            'status'  => 'error',
            'message' => $apply['message'] ?? 'Failed to update package balance.',
            'code'    => $apply['code'] ?? null,
            'display' => [
                'cashier_id'       => $cashierId,
                'deposit_amount'   => $remoteAmount,
                'previous_balance' => $apply['previous_balance'] ?? $previousBalance,
                'new_balance'      => $apply['previous_balance'] ?? $previousBalance,
            ],
        ];
    }

    $newBalance = (float) $apply['new_balance'];

    if (!deposit_insert_log($conn, $transaction, $cashierId, $partnerId)) {
        return [
            'status'  => 'error',
            'message' => 'Package updated but transaction log failed.',
        ];
    }

    $ack = deposit_ack_remote_package($cashierId, $partnerId, $transactionId, false);
    deposit_sync_cashier_settings($conn, $cashierId, $partnerId);

    $display = [
        'cashier_id'       => $cashierId,
        'deposit_amount'   => $remoteAmount,
        'previous_balance' => $previousBalance,
        'new_balance'      => $newBalance,
        'transaction_id'   => $transactionId,
        'confirmed_remote' => $ack['ok'],
    ];

    $successMessage = $remoteAmount < 0
        ? 'Package withdrawal applied and saved securely.'
        : 'Package deposited and saved securely.';

    return [
        'status'     => 'success',
        'message'    => $successMessage,
        'display'    => $display,
        'code_block' => deposit_format_code_block($display),
    ];
}
