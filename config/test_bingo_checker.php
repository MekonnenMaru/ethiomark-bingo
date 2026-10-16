<?php

require_once __DIR__ . '/BingoChecker.php';

function assertCheck(string $label, bool $ok): void
{
    echo ($ok ? 'PASS' : 'FAIL') . " — $label\n";
    if (!$ok) {
        exit(1);
    }
}

// Minimal card: one row B line pattern 1
$card = [
    'B' => [1, 2, 3, 4, 5],
    'I' => [16, 17, 18, 19, 20],
    'N' => [31, 32, 0, 34, 35],
    'G' => [46, 47, 48, 49, 50],
    'O' => [61, 62, 63, 64, 65],
];

$drawnOnTime = [1, 2, 3, 4, 5];
$drawnLate = [1, 2, 3, 4, 5, 99];

$noRestriction = ['bingo_claim_mode' => 'no_restriction'];
$strict = ['bingo_claim_mode' => 'disqualify_on_miss'];

$r1 = BingoChecker::check($card, $drawnOnTime, 1, false, $strict);
assertCheck('strict on-time winner', $r1['is_winner'] && !$r1['is_late_claim']);

$r2 = BingoChecker::check($card, $drawnLate, 1, false, $strict);
assertCheck('strict late claim', $r2['is_late_claim'] && !$r2['is_winner'] && $r2['locks_on_late_claim']);

$r3 = BingoChecker::check($card, $drawnLate, 1, false, $noRestriction);
assertCheck('no restriction ignores late window', $r3['is_winner'] && !$r3['is_late_claim']);

$userCard = [
    'B' => [15, 11, 12, 3, 10],
    'I' => [16, 28, 20, 30, 24],
    'N' => [39, 40, 0, 35, 37],
    'G' => [59, 51, 56, 60, 53],
    'O' => [66, 68, 67, 72, 64],
];
$userDrawn = [16, 28, 20, 30, 24, 39, 40, 35, 37];
assertCheck(
    'two full columns is not pattern 3 yet',
    BingoChecker::winLineHighlightColor($userCard, $userDrawn, 3, 'col:I', true) === null
);
assertCheck(
    'column N also not highlighted before pattern win',
    BingoChecker::winLineHighlightColor($userCard, $userDrawn, 3, 'col:N', true) === null
);

assertCheck('late forces yellow on winning line', BingoChecker::winLineHighlightColor(
    $card,
    $drawnLate,
    1,
    'col:B',
    true,
    true
) === '#bca106');
assertCheck('on-time winning line stays green', BingoChecker::winLineHighlightColor(
    $card,
    $drawnOnTime,
    1,
    'col:B',
    true,
    false
) === 'green');

$twoLineDrawn = [16, 28, 20, 30, 24, 39, 40, 35, 37];
assertCheck(
    'allow later patterns: both winning columns green on new pattern',
    BingoChecker::winLineHighlightColor($userCard, $twoLineDrawn, 2, 'col:I', true, false, 'allow_later_patterns') === 'green'
    && BingoChecker::winLineHighlightColor($userCard, $twoLineDrawn, 2, 'col:N', true, false, 'allow_later_patterns') === 'green'
);

echo "All BingoChecker checks passed.\n";
