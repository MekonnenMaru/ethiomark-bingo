<?php

require_once __DIR__ . '/BingoPatterns.php';

/**
 * Card check + late claim — aligned with lib/core/bingo/bingo_checker.dart
 * and lib/core/bingo/bingo_claim_mode.dart.
 */
final class BingoChecker
{
    /** Result color mode Three enables yellow cells in fetch_result HTML (display only). */
    public static function usesThreeColorResultMode(?array $system, string $cashierColorColumn = 'two'): bool
    {
        $raw = is_array($system) ? trim((string) ($system['color_mode'] ?? '')) : '';
        if ($raw === '') {
            $raw = trim($cashierColorColumn);
        }

        return strtolower($raw) === 'three';
    }

    public static function claimModeFromSystem(?array $system): string
    {
        if (!is_array($system)) {
            return 'no_restriction';
        }

        $rawMode = isset($system['bingo_claim_mode']) ? trim((string) $system['bingo_claim_mode']) : '';
        if ($rawMode !== '') {
            return match (strtolower($rawMode)) {
                'allow_later_patterns', 'allow_new_patterns' => 'allow_later_patterns',
                'disqualify_on_miss', 'strict' => 'disqualify_on_miss',
                'no_restriction', 'off', 'instant' => 'no_restriction',
                default => 'no_restriction',
            };
        }

        $limit = (int) ($system['bingo_claim_limit'] ?? -1);

        return $limit < 0 ? 'no_restriction' : 'disqualify_on_miss';
    }

    public static function usesClaimWindow(string $mode): bool
    {
        return $mode === 'allow_later_patterns' || $mode === 'disqualify_on_miss';
    }

    /** First draw index (0-based) when the card first satisfies the active pattern. */
    public static function firstWinningDrawIndex(array $card, array $drawnNumbers, int $pattern): ?int
    {
        return self::firstQualifyingIndex($card, $drawnNumbers, BingoPatterns::normalize($pattern));
    }

    /**
     * Highlight color for cells on a winning line.
     * Returns null when the pattern is not yet satisfied (caller should use red for called cells).
     *
     * allow_later_patterns: all green on a valid (on-time) claim; yellow only when late.
     * disqualify_on_miss: green on the line that completed on first win; yellow on older lines.
     */
    public static function winLineHighlightColor(
        array $card,
        array $drawnNumbers,
        int $pattern,
        string $lineKey,
        bool $allowStaleLineYellow,
        bool $lateClaimForcesYellow = false,
        string $claimMode = 'no_restriction'
    ): ?string {
        $patternNorm = BingoPatterns::normalize($pattern);
        $evaluation = BingoPatterns::evaluate($card, $drawnNumbers, $patternNorm);
        if (!$evaluation['had_pattern']) {
            return null;
        }

        $activeKeys = BingoPatterns::listWinningLineKeys($card, $drawnNumbers);
        if (!in_array($lineKey, $activeKeys, true)) {
            return null;
        }

        if ($lateClaimForcesYellow) {
            return '#bca106';
        }

        if ($claimMode === 'allow_later_patterns') {
            return 'green';
        }

        $firstWin = self::firstWinningDrawIndex($card, $drawnNumbers, $patternNorm);
        $lineAt = BingoPatterns::lineFirstCompleteDrawIndex($card, $drawnNumbers, $lineKey);
        if ($firstWin === null || $lineAt === null || $lineAt === $firstWin) {
            return 'green';
        }

        return $allowStaleLineYellow ? '#bca106' : 'green';
    }

    /**
     * @return array{
     *   is_winner: bool,
     *   had_winning_pattern: bool,
     *   is_late_claim: bool,
     *   calls_after_pattern: int,
     *   winning_lines: int,
     *   expected_pattern: int,
     *   claim_mode: string,
     *   uses_claim_window: bool,
     *   locks_on_late_claim: bool
     * }
     */
    public static function check(
        array $card,
        array $drawnNumbers,
        int $pattern,
        bool $isLocked,
        ?array $system
    ): array {
        $claimMode = self::claimModeFromSystem($system);
        $patternNorm = BingoPatterns::normalize($pattern);
        $evaluation = BingoPatterns::evaluate($card, $drawnNumbers, $patternNorm);
        $hadPattern = $evaluation['had_pattern'];
        $winningLines = $evaluation['winning_lines'];
        $required = BingoPatterns::requiredWinScore($patternNorm);

        $isLateClaim = false;
        $callsAfterPattern = 0;

        if (self::usesClaimWindow($claimMode) && $hadPattern && count($drawnNumbers) > 0) {
            $opportunityAt = $claimMode === 'allow_later_patterns'
                ? self::lastQualifyingUpgradeIndex($card, $drawnNumbers, $patternNorm)
                : self::firstQualifyingIndex($card, $drawnNumbers, $patternNorm);

            if ($opportunityAt !== null) {
                $callsAfterPattern = (count($drawnNumbers) - 1) - $opportunityAt;
                $isLateClaim = $callsAfterPattern > 0;
            }
        }

        $locksOnLateClaim = ($claimMode === 'disqualify_on_miss') && $isLateClaim && !$isLocked;

        return [
            'is_winner'             => $hadPattern && !$isLateClaim,
            'had_winning_pattern'   => $hadPattern,
            'is_late_claim'         => $isLateClaim,
            'calls_after_pattern'   => $callsAfterPattern,
            'winning_lines'         => $winningLines,
            'expected_pattern'      => $required,
            'claim_mode'            => $claimMode,
            'uses_claim_window'     => self::usesClaimWindow($claimMode),
            'locks_on_late_claim'   => $locksOnLateClaim,
        ];
    }

    /** @deprecated Use check() */
    public static function isLateClaim(array $card, array $drawnNumbers, int $pattern, string $claimMode): bool
    {
        $result = self::check($card, $drawnNumbers, $pattern, false, [
            'bingo_claim_mode' => $claimMode,
        ]);

        return $result['is_late_claim'];
    }

    private static function scoreQualifies(int $score, int $pattern): bool
    {
        if (BingoPatterns::isShapePattern($pattern)) {
            return $score >= 1;
        }
        if ($pattern === BingoPatterns::ANY_VERTICAL || $pattern === BingoPatterns::ANY_HORIZONTAL) {
            return $score >= 1;
        }

        $required = max(1, min(3, $pattern));

        return $score >= $required;
    }

    private static function firstQualifyingIndex(array $card, array $drawnNumbers, int $pattern): ?int
    {
        $count = count($drawnNumbers);
        for ($i = 0; $i < $count; $i++) {
            $prefix = array_slice($drawnNumbers, 0, $i + 1);
            $score = BingoPatterns::evaluate($card, $prefix, $pattern)['winning_lines'];
            if (self::scoreQualifies($score, $pattern)) {
                return $i;
            }
        }

        return null;
    }

    private static function lastQualifyingUpgradeIndex(array $card, array $drawnNumbers, int $pattern): ?int
    {
        $count = count($drawnNumbers);
        $peak = 0;
        $lastUpgrade = null;

        for ($i = 0; $i < $count; $i++) {
            $prefix = array_slice($drawnNumbers, 0, $i + 1);
            $score = BingoPatterns::evaluate($card, $prefix, $pattern)['winning_lines'];
            if ($score > $peak && self::scoreQualifies($score, $pattern)) {
                $peak = $score;
                $lastUpgrade = $i;
            } elseif ($score > $peak) {
                $peak = $score;
            }
        }

        return $lastUpgrade;
    }
}
