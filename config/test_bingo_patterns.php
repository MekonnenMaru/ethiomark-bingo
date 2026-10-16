<?php

require __DIR__ . '/BingoPatterns.php';

function sampleCard(): array
{
    return [
        'B' => [1, 2, 3, 4, 5],
        'I' => [16, 17, 18, 19, 20],
        'N' => [31, 32, 0, 34, 35],
        'G' => [46, 47, 48, 49, 50],
        'O' => [61, 62, 63, 64, 65],
    ];
}

function assertTrue(bool $cond, string $msg): void
{
    if (!$cond) {
        fwrite(STDERR, "FAIL: $msg\n");
        exit(1);
    }
}

function assertFalse(bool $cond, string $msg): void
{
    assertTrue(!$cond, $msg);
}

$card = sampleCard();
$failures = 0;

$tests = [
    '1 line – B column' => [
        'pattern' => 1,
        'drawn' => [1, 2, 3, 4, 5],
        'expect' => true,
        'lines' => 1,
    ],
    '2 lines – need two' => [
        'pattern' => 2,
        'drawn' => [1, 2, 3, 4, 5],
        'expect' => false,
        'lines' => 1,
    ],
    '2 lines – B col + row 1' => [
        'pattern' => 2,
        'drawn' => [1, 2, 3, 4, 5, 16, 17, 18, 19, 20],
        'expect' => true,
        'lines' => 2,
    ],
    '3 lines – only two' => [
        'pattern' => 3,
        'drawn' => [1, 2, 3, 4, 5, 16, 17, 18, 19, 20],
        'expect' => false,
        'lines' => 2,
    ],
    'any vertical – B col' => [
        'pattern' => 8,
        'drawn' => [1, 2, 3, 4, 5],
        'expect' => true,
        'lines' => 1,
    ],
    'any horizontal – top row' => [
        'pattern' => 9,
        'drawn' => [1, 16, 31, 46, 61],
        'expect' => true,
        'lines' => 1,
    ],
    'L shape incomplete' => [
        'pattern' => 4,
        'drawn' => [1, 2, 3, 4, 5],
        'expect' => false,
        'lines' => 1,
    ],
    'L shape complete' => [
        'pattern' => 4,
        'drawn' => [1, 2, 3, 4, 5, 65, 50, 35, 20],
        'expect' => true,
        'lines' => 1,
    ],
    'T shape complete' => [
        'pattern' => 5,
        'drawn' => [1, 16, 31, 46, 61, 32, 0, 34, 35],
        'expect' => true,
        'lines' => 1,
    ],
    'X shape – diagonals' => [
        'pattern' => 6,
        'drawn' => [1, 17, 49, 65, 5, 19, 47, 61],
        'expect' => true,
        'lines' => 1,
    ],
    'full card' => [
        'pattern' => 7,
        'drawn' => array_merge(
            [1, 2, 3, 4, 5],
            [16, 17, 18, 19, 20],
            [31, 32, 34, 35],
            [46, 47, 48, 49, 50],
            [61, 62, 63, 64, 65]
        ),
        'expect' => true,
        'lines' => 1,
    ],
    'half above' => [
        'pattern' => 12,
        'drawn' => [1, 2, 16, 17, 31, 32, 46, 47, 61, 62],
        'expect' => true,
        'lines' => 1,
    ],
    'half below' => [
        'pattern' => 13,
        'drawn' => [4, 5, 19, 20, 34, 35, 49, 50, 64, 65],
        'expect' => true,
        'lines' => 1,
    ],
    'main diagonal as 1 line' => [
        'pattern' => 1,
        'drawn' => [1, 17, 49, 65],
        'expect' => true,
        'lines' => 1,
    ],
    'legacy 14 → 1 line' => [
        'pattern' => 14,
        'drawn' => [1, 2, 3, 4, 5],
        'expect' => true,
        'lines' => 1,
    ],
    'reverse T complete' => [
        'pattern' => 10,
        'drawn' => [5, 20, 35, 50, 65, 31, 32, 34],
        'expect' => true,
        'lines' => 1,
    ],
    'reverse L complete' => [
        'pattern' => 11,
        'drawn' => [61, 62, 63, 64, 65, 5, 20, 35, 50],
        'expect' => true,
        'lines' => 1,
    ],
    '3 lines – three distinct lines' => [
        'pattern' => 3,
        'drawn' => [1, 2, 3, 4, 5, 16, 17, 18, 19, 20, 1, 17, 49, 65],
        'expect' => true,
        'lines' => 3,
    ],
];

foreach ($tests as $name => $t) {
    $ev = BingoPatterns::evaluate($card, $t['drawn'], $t['pattern']);
    $ok = ($ev['had_pattern'] === $t['expect']) && ($ev['winning_lines'] === $t['lines']);
    if (!$ok) {
        fwrite(STDERR, sprintf(
            "FAIL: %s — had=%s (want %s), lines=%d (want %d)\n",
            $name,
            $ev['had_pattern'] ? 'true' : 'false',
            $t['expect'] ? 'true' : 'false',
            $ev['winning_lines'],
            $t['lines']
        ));
        $failures++;
    }
}

// Combo counts for animation (match Flutter)
$singles = 14;
$c2 = 91;
$c3 = 364;
$n2 = 0;
$n3 = 0;
function nCk(int $n, int $k): int {
    if ($k < 0 || $k > $n) return 0;
    $r = 1;
    for ($i = 1; $i <= $k; $i++) {
        $r = (int) ($r * ($n - $k + $i) / $i);
    }
    return $r;
}
if (nCk(14, 2) !== $c2 || nCk(14, 3) !== $c3) {
    fwrite(STDERR, "FAIL: combination counts for 2/3 line previews\n");
    $failures++;
}

if ($failures > 0) {
    fwrite(STDERR, "$failures test(s) failed.\n");
    exit(1);
}

echo 'All ' . count($tests) . " pattern checks passed.\n";
