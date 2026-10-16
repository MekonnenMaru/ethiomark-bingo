<?php

/**
 * Win pattern ids and rules — aligned with lib/core/bingo/bingo_patterns.dart
 * and lib/core/bingo/bingo_checker.dart.
 */
final class BingoPatterns
{
    public const ALL_IN_ONE = 14;
    public const LINE_ONE = 1;
    public const LINE_TWO = 2;
    public const LINE_THREE = 3;
    public const L_SHAPE = 4;
    public const T_SHAPE = 5;
    public const X_SHAPE = 6;
    public const FULL = 7;
    public const ANY_VERTICAL = 8;
    public const ANY_HORIZONTAL = 9;
    public const REVERSE_T_SHAPE = 10;
    public const REVERSE_L_SHAPE = 11;
    public const HALF_ABOVE = 12;
    public const HALF_BELOW = 13;

    public static function normalize(int $pattern): int
    {
        return $pattern === self::ALL_IN_ONE ? self::LINE_ONE : $pattern;
    }

    public static function englishName(int $pattern): string
    {
        $p = self::normalize($pattern);
        return match ($p) {
            self::LINE_ONE => 'any one line',
            self::LINE_TWO => 'any two lines',
            self::LINE_THREE => 'any three lines',
            self::L_SHAPE => 'L',
            self::T_SHAPE => 'T',
            self::X_SHAPE => 'X',
            self::FULL => 'Full',
            self::ANY_VERTICAL => 'any vertical',
            self::ANY_HORIZONTAL => 'any horizontal',
            self::REVERSE_T_SHAPE => 'reverse T',
            self::REVERSE_L_SHAPE => 'reverse L',
            self::HALF_ABOVE => 'half above',
            self::HALF_BELOW => 'half below',
            default => (string) $p,
        };
    }

    public static function requiredWinScore(int $pattern): int
    {
        $p = self::normalize($pattern);
        if ($p >= self::LINE_ONE && $p <= self::LINE_THREE) {
            return $p;
        }
        return 1;
    }

    public static function isShapePattern(int $pattern): bool
    {
        return in_array($pattern, [
            self::L_SHAPE,
            self::T_SHAPE,
            self::X_SHAPE,
            self::REVERSE_T_SHAPE,
            self::REVERSE_L_SHAPE,
            self::HALF_ABOVE,
            self::HALF_BELOW,
            self::FULL,
        ], true);
    }

    /** @return array{had_pattern: bool, winning_lines: int} */
    public static function evaluate(array $card, array $drawnNumbers, int $pattern): array
    {
        $pattern = self::normalize($pattern);
        $drawnSet = array_fill_keys(array_map('intval', $drawnNumbers), true);

        if ($pattern === self::ANY_VERTICAL) {
            $columns = self::completeVerticalColumns($card, $drawnSet);
            return ['had_pattern' => count($columns) > 0, 'winning_lines' => count($columns)];
        }

        if ($pattern === self::ANY_HORIZONTAL) {
            $rows = self::completeHorizontalRows($card, $drawnSet);
            return ['had_pattern' => count($rows) > 0, 'winning_lines' => count($rows)];
        }

        if (self::isShapePattern($pattern)) {
            $cells = self::completedShapeCells($card, $drawnSet, $pattern);
            $required = count(self::cellsFor($pattern));
            return [
                'had_pattern' => count($cells) === $required && $required > 0,
                'winning_lines' => count($cells) > 0 ? 1 : 0,
            ];
        }

        $lines = self::countWinningLines($card, $drawnSet);
        $required = max(1, min(3, $pattern));

        return [
            'had_pattern' => $lines >= $required,
            'winning_lines' => $lines,
        ];
    }

    public static function checkPattern(array $card, array $drawnNumbers, int $pattern): bool
    {
        return self::evaluate($card, $drawnNumbers, $pattern)['had_pattern'];
    }

    /** @return list<string> */
    public static function listWinningLineKeys(array $card, array $drawnNumbers): array
    {
        $drawnSet = array_fill_keys(array_map('intval', $drawnNumbers), true);

        return self::winningLineKeys($card, $drawnSet);
    }

    /** First draw index (0-based) when [lineKey] becomes complete, or null if never. */
    public static function lineFirstCompleteDrawIndex(array $card, array $drawnNumbers, string $lineKey): ?int
    {
        $count = count($drawnNumbers);
        for ($i = 0; $i < $count; $i++) {
            $prefix = array_slice($drawnNumbers, 0, $i + 1);
            if (in_array($lineKey, self::listWinningLineKeys($card, $prefix), true)) {
                return $i;
            }
        }

        return null;
    }

    private static function isMarked(int $n, array $drawnSet): bool
    {
        return $n === 0 || isset($drawnSet[(int) $n]);
    }

    /** @return array<string, true> */
    private static function completeVerticalColumns(array $card, array $drawnSet): array
    {
        $columns = [];
        foreach ($card as $colKey => $numbers) {
            $complete = true;
            foreach ($numbers as $n) {
                if (!self::isMarked((int) $n, $drawnSet)) {
                    $complete = false;
                    break;
                }
            }
            if ($complete) {
                $columns[$colKey] = true;
            }
        }

        return $columns;
    }

    /** @return array<int, true> */
    private static function completeHorizontalRows(array $card, array $drawnSet): array
    {
        $rows = [];
        for ($i = 0; $i < 5; $i++) {
            $horizontal = [
                (int) $card['B'][$i],
                (int) $card['I'][$i],
                (int) $card['N'][$i],
                (int) $card['G'][$i],
                (int) $card['O'][$i],
            ];
            $complete = true;
            foreach ($horizontal as $n) {
                if (!self::isMarked($n, $drawnSet)) {
                    $complete = false;
                    break;
                }
            }
            if ($complete) {
                $rows[$i] = true;
            }
        }

        return $rows;
    }

    private static function countWinningLines(array $card, array $drawnSet): int
    {
        return count(self::winningLineKeys($card, $drawnSet));
    }

    /** @return list<string> */
    private static function winningLineKeys(array $card, array $drawnSet): array
    {
        $lines = [];

        foreach ($card as $colKey => $numbers) {
            $complete = true;
            foreach ($numbers as $n) {
                if (!self::isMarked((int) $n, $drawnSet)) {
                    $complete = false;
                    break;
                }
            }
            if ($complete) {
                $lines[] = 'col:' . $colKey;
            }
        }

        for ($i = 0; $i < 5; $i++) {
            $vertical = [
                (int) $card['B'][$i],
                (int) $card['I'][$i],
                (int) $card['N'][$i],
                (int) $card['G'][$i],
                (int) $card['O'][$i],
            ];
            $complete = true;
            foreach ($vertical as $n) {
                if (!self::isMarked($n, $drawnSet)) {
                    $complete = false;
                    break;
                }
            }
            if ($complete) {
                $lines[] = 'row:' . $i;
            }
        }

        $d1 = [
            (int) $card['B'][0], (int) $card['I'][1], (int) $card['N'][2],
            (int) $card['G'][3], (int) $card['O'][4],
        ];
        $d2 = [
            (int) $card['B'][4], (int) $card['I'][3], (int) $card['N'][2],
            (int) $card['G'][1], (int) $card['O'][0],
        ];
        if (self::lineComplete($d1, $drawnSet)) {
            $lines[] = 'diag:0';
        }
        if (self::lineComplete($d2, $drawnSet)) {
            $lines[] = 'diag:1';
        }

        if (count(self::completedCellSet($card, $drawnSet, self::outsideCornersCells())) === 4) {
            $lines[] = 'corners:outside';
        }
        if (count(self::completedCellSet($card, $drawnSet, self::insideCornersCells())) === 4) {
            $lines[] = 'corners:inside';
        }

        return $lines;
    }

    /** @param list<int> $numbers */
    private static function lineComplete(array $numbers, array $drawnSet): bool
    {
        foreach ($numbers as $n) {
            if (!self::isMarked($n, $drawnSet)) {
                return false;
            }
        }

        return true;
    }

    /** @return list<string> */
    private static function cellsFor(int $pattern): array
    {
        return match ($pattern) {
            self::L_SHAPE => ['B:0', 'B:1', 'B:2', 'B:3', 'B:4', 'I:4', 'N:4', 'G:4', 'O:4'],
            self::T_SHAPE => ['B:0', 'I:0', 'N:0', 'G:0', 'O:0', 'N:1', 'N:2', 'N:3', 'N:4'],
            self::REVERSE_T_SHAPE => ['B:4', 'I:4', 'N:4', 'G:4', 'O:4', 'N:0', 'N:1', 'N:2', 'N:3'],
            self::X_SHAPE => ['B:0', 'I:1', 'N:2', 'G:3', 'O:4', 'B:4', 'I:3', 'G:1', 'O:0'],
            self::REVERSE_L_SHAPE => ['O:0', 'O:1', 'O:2', 'O:3', 'O:4', 'B:4', 'I:4', 'N:4', 'G:4'],
            self::HALF_ABOVE => self::cellsForRows([0, 1]),
            self::HALF_BELOW => self::cellsForRows([3, 4]),
            self::FULL => self::cellsForRows([0, 1, 2, 3, 4]),
            default => [],
        };
    }

    /** @param list<int> $rows @return list<string> */
    private static function cellsForRows(array $rows): array
    {
        $cells = [];
        foreach (['B', 'I', 'N', 'G', 'O'] as $col) {
            foreach ($rows as $row) {
                $cells[] = $col . ':' . $row;
            }
        }

        return $cells;
    }

    /** @return list<string> */
    private static function outsideCornersCells(): array
    {
        return ['B:0', 'O:0', 'B:4', 'O:4'];
    }

    /** @return list<string> */
    private static function insideCornersCells(): array
    {
        return ['I:1', 'G:1', 'I:3', 'G:3'];
    }

    /** @param list<string> $required @return list<string> */
    private static function completedCellSet(array $card, array $drawnSet, array $required): array
    {
        $completed = [];
        foreach ($required as $key) {
            $parts = explode(':', $key);
            if (count($parts) !== 2) {
                continue;
            }
            [$col, $rowStr] = $parts;
            $row = (int) $rowStr;
            if (!isset($card[$col][$row])) {
                continue;
            }
            if (self::isMarked((int) $card[$col][$row], $drawnSet)) {
                $completed[] = $key;
            }
        }

        return $completed;
    }

    /** @return list<string> */
    private static function completedShapeCells(array $card, array $drawnSet, int $pattern): array
    {
        return self::completedCellSet($card, $drawnSet, self::cellsFor($pattern));
    }
}
