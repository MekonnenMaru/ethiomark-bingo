import 'dart:convert';
import 'dart:math';

import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../core/bootstrap/bootstrap_cache.dart';
import '../../core/bingo/bingo_checker.dart';
import '../../core/bingo/bingo_claim_mode.dart';
import '../../core/bingo/income_calculator.dart';
import '../../core/bingo/player_bonus.dart';
import '../../core/config/app_config.dart';
import '../../core/config/app_currency.dart';
import '../../core/device/stored_date.dart';
import '../../core/crypto/package_crypto.dart';
import '../../core/config/cashier_defaults.dart';
import '../../core/deposit/manual_deposit_codec.dart';
import '../../core/deposit/manual_deposit_lockout.dart';
import '../../core/device/device_id.dart';
import '../../core/trial/trial_prefs.dart';
import '../../core/trial/trial_service.dart';
import '../../services/deposit_service.dart';
import '../database/app_database.dart';
import '../models/cartela.dart';
import '../models/cashier_profile.dart';
import '../models/game_round.dart';

class GameRepository {
  GameRepository(this._db);

  final AppDatabase _db;

  Future<T> _dbRun<T>(Future<T> Function(Database db) action) =>
      _db.run(action);

  String _todayClause() => "date(date) = date('now', 'localtime')";

  Future<String> _readPackageFromRow(Map<String, Object?> row) async {
    final stored = row['cashier_package'] as String?;
    final mid = row['mid'] as String?;
    var balance = PackageCrypto.decryptCashierPackage(
      stored,
      encryptedMid: mid,
    );
    if (balance == '0' &&
        stored != null &&
        stored.trim().isNotEmpty &&
        num.tryParse(stored.trim()) == null) {
      final serial = await DeviceId.getSerial();
      balance = PackageCrypto.decryptCashierPackage(
        stored,
        serial: serial,
        encryptedMid: mid,
      );
    }
    return balance;
  }

  Future<CashierProfile> getCashierProfile(String cashierId) async {
    return _dbRun((db) async {
      final rows = await db.rawQuery(
        '''
        SELECT c.*,
               p.start_get_mony_from,
               p.lock_round_up_last_digit,
               p.partner_settings
        FROM cashier c
        JOIN partner p ON p.partner_id = c.partner_id
        WHERE c.cashier_id = ?
        ''',
        [cashierId],
      );
      if (rows.isEmpty) throw StateError('Cashier not found');
      final row = rows.first;
      final balance = await _readPackageFromRow(row);
      return CashierProfile.fromMap(row, balance);
    });
  }

  Future<String> readPackageBalance(String cashierId) async {
    return _dbRun((db) => _readPackageBalanceExec(db, cashierId));
  }

  Future<String> _readPackageBalanceExec(
    DatabaseExecutor exec,
    String cashierId,
  ) async {
    final rows = await exec.query(
      'cashier',
      where: 'cashier_id = ?',
      whereArgs: [cashierId],
      limit: 1,
    );
    if (rows.isEmpty) return '0';
    return _readPackageFromRow(rows.first);
  }

  Future<String> _deviceSerialForCashier(String? mid) async {
    final fromMid = PackageCrypto.decryptMachineMid(mid);
    if (fromMid.isNotEmpty) return fromMid;
    return DeviceId.getSerial();
  }

  Future<void> writePackageBalance(String cashierId, String plain) async {
    await _dbRun((db) => _writePackageBalanceExec(db, cashierId, plain));
  }

  Future<void> _writePackageBalanceExec(
    DatabaseExecutor exec,
    String cashierId,
    String plain,
  ) async {
    final rows = await exec.query(
      'cashier',
      columns: ['mid'],
      where: 'cashier_id = ?',
      whereArgs: [cashierId],
    );
    if (rows.isEmpty) return;

    final mid = rows.first['mid'] as String?;
    final serial = await _deviceSerialForCashier(mid);
    final encryptedMid = (mid != null && mid.isNotEmpty)
        ? mid
        : PackageCrypto.encryptMachineMid(serial);
    final encrypted = PackageCrypto.encryptCashierPackage(plain, serial);

    final updated = await exec.update(
      'cashier',
      {'cashier_package': encrypted, 'mid': encryptedMid},
      where: 'cashier_id = ?',
      whereArgs: [cashierId],
    );
    if (updated == 0) {
      throw StateError('Failed to save package balance to database.');
    }
  }

  Future<int> getCartelaCount(String category) async {
    return _dbRun((db) async {
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM cartela WHERE category = ?',
        [category],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    });
  }

  Future<List<String>> listCartelaCategories() async {
    return _dbRun((db) async {
      final rows = await db.rawQuery(
        'SELECT DISTINCT category FROM cartela ORDER BY category ASC',
      );
      return rows
          .map((r) => '${r['category']}')
          .where((c) => c.isNotEmpty)
          .toList();
    });
  }

  Future<void> updateCashierCategory({
    required String cashierId,
    required String category,
  }) async {
    await _dbRun((db) async {
      await db.update(
        'cashier',
        {'category': category},
        where: 'cashier_id = ?',
        whereArgs: [cashierId],
      );
    });
  }

  Future<Cartela?> getCartelaByNumber({
    required String category,
    required int number,
  }) async {
    return _dbRun((db) async {
      final rows = await db.query(
        'cartela',
        where: 'category = ? AND cartela_number = ?',
        whereArgs: [category, number],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return Cartela.fromMap(rows.first);
    });
  }

  Future<List<DepositLogRow>> listDepositLogs({
    required String cashierId,
    int limit = 100,
  }) async {
    return _dbRun((db) async {
      final rows = await db.query(
        'transaction_logs',
        where: "cashier_id = ? AND ("
            "event_type IN ('deposit', 'withdrawal') OR "
            "action LIKE '%deposit%' OR "
            "action LIKE '%withdrawal%'"
            ")",
        whereArgs: [cashierId],
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      return rows.map((r) {
        return DepositLogRow(
          transactionId: r['transaction_id'] as int? ?? 0,
          timestamp: r['timestamp'] as String? ?? '',
          action: r['action'] as String? ?? '',
          amount: (r['amount'] as num?)?.toDouble() ?? 0,
          status: r['status'] as String? ?? '',
          message: r['message'] as String? ?? '',
        );
      }).toList();
    });
  }

  Future<int> resolveRoundNumber(String cashierId) async {
    return _dbRun((db) async {
      // Reuse round only when cards are registered but the round has not been started (no transaction).
      final pendingRows = await db.query(
        'game',
        where: 'cashier_id = ? AND iscompleted = 0 AND ${_todayClause()}',
        whereArgs: [cashierId],
        orderBy: 'round_number DESC',
        limit: 1,
      );
      if (pendingRows.isNotEmpty) {
        final round = pendingRows.first['round_number'] as int? ?? 1;
        final tx = await db.query(
          '"transaction"',
          columns: ['id'],
          where: 'cashier_id = ? AND game_round = ? AND ${_todayClause()}',
          whereArgs: [cashierId, round],
          limit: 1,
        );
        if (tx.isEmpty) return round;
      }

      final maxTx = await db.rawQuery(
        'SELECT MAX(game_round) AS m FROM "transaction" WHERE cashier_id = ? AND ${_todayClause()}',
        [cashierId],
      );
      final maxRound = Sqflite.firstIntValue(maxTx) ?? 0;

      final maxGame = await db.rawQuery(
        'SELECT MAX(round_number) AS m FROM game WHERE cashier_id = ? AND ${_todayClause()}',
        [cashierId],
      );
      final maxGameRound = Sqflite.firstIntValue(maxGame) ?? 0;

      return max(maxRound, maxGameRound) + 1;
    });
  }

  /// Cards saved for today but round not started yet (no transaction, not completed).
  Future<GameRound?> getIncompleteGame(String cashierId) async {
    return _dbRun((db) async {
      final rows = await db.query(
        'game',
        where: 'cashier_id = ? AND iscompleted = 0 AND ${_todayClause()}',
        whereArgs: [cashierId],
        orderBy: 'round_number DESC',
        limit: 1,
      );
      if (rows.isEmpty) return null;

      final game = GameRound.fromMap(rows.first);
      final tx = await db.query(
        '"transaction"',
        columns: ['id'],
        where: 'cashier_id = ? AND game_round = ? AND ${_todayClause()}',
        whereArgs: [cashierId, game.roundNumber],
        limit: 1,
      );
      if (tx.isNotEmpty) return null;
      return game;
    });
  }

  /// Most recent today game that already has cards saved (any round).
  Future<GameRound?> getLastRegisteredGame(String cashierId) async {
    return _dbRun((db) async {
      final rows = await db.query(
        'game',
        where:
            "cashier_id = ? AND cartela_number IS NOT NULL AND cartela_number != '' AND ${_todayClause()}",
        whereArgs: [cashierId],
        orderBy: 'round_number DESC',
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return GameRound.fromMap(rows.first);
    });
  }

  /// Latest today game still in play (not finished).
  Future<GameRound?> getActivePlayGame(String cashierId) async {
    return _dbRun((db) async {
      final rows = await db.query(
        'game',
        where: 'cashier_id = ? AND ${_todayClause()}',
        whereArgs: [cashierId],
        orderBy: 'round_number DESC',
        limit: 1,
      );
      if (rows.isEmpty) return null;

      final game = GameRound.fromMap(rows.first);
      final txRows = await db.query(
        '"transaction"',
        columns: ['result'],
        where: 'cashier_id = ? AND game_round = ? AND ${_todayClause()}',
        whereArgs: [cashierId, game.roundNumber],
        limit: 1,
      );
      if (txRows.isEmpty) return game;

      final txResult = (txRows.first['result'] as String? ?? '').trim();
      return txResult.isEmpty ? game : null;
    });
  }

  Future<bool> hasTransactionForRound(String cashierId, int roundNumber) async {
    return _dbRun((db) async {
      final rows = await db.query(
        '"transaction"',
        columns: ['id'],
        where: 'cashier_id = ? AND game_round = ? AND ${_todayClause()}',
        whereArgs: [cashierId, roundNumber],
        limit: 1,
      );
      return rows.isNotEmpty;
    });
  }

  /// House income locked when the round is started — used for derash during play.
  Future<double?> getRoundLockedIncome(String cashierId, int roundNumber) async {
    return _dbRun((db) async {
      final rows = await db.query(
        '"transaction"',
        columns: ['income'],
        where: 'cashier_id = ? AND game_round = ? AND ${_todayClause()}',
        whereArgs: [cashierId, roundNumber],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return (rows.first['income'] as num?)?.toDouble() ?? 0;
    });
  }

  Future<void> updateFirstDraw(
    String cashierId,
    int roundNumber,
    List<int> numbers,
  ) async {
    await _dbRun((db) async {
      await db.update(
        'game',
        {'first_draw': numbers.join(',')},
        where: 'round_number = ? AND cashier_id = ? AND ${_todayClause()}',
        whereArgs: [roundNumber, cashierId],
      );
    });
  }

  Future<GameRound?> getGameForRound(String cashierId, int round) async {
    final db = await _db.database;
    final rows = await db.query(
      'game',
      where: 'cashier_id = ? AND round_number = ? AND ${_todayClause()}',
      whereArgs: [cashierId, round],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return GameRound.fromMap(rows.first);
  }

  Future<Map<String, dynamic>> registerNewGameRound({
    required String cashierId,
    required int roundNumber,
    required List<int> selectedCards,
    required int price,
    required int pattern,
  }) async {
    if (selectedCards.isEmpty) {
      return {'status': 'error', 'message': 'Please select at least one card.'};
    }

    final db = await _db.database;
    final maxTx = await db.rawQuery(
      'SELECT MAX(game_round) AS m FROM "transaction" WHERE cashier_id = ? AND ${_todayClause()}',
      [cashierId],
    );
    final maxRound = Sqflite.firstIntValue(maxTx) ?? 0;
    if (roundNumber < maxRound) {
      return {
        'status': 'error',
        'message': 'Game round must be greater than existing rounds for today.',
      };
    }

    final package = double.tryParse(await readPackageBalance(cashierId)) ?? 0;
    final packageBalance = package.toStringAsFixed(0);
    final roundsUsed = await TrialPrefs.loadRoundsUsed(cashierId);
    final totalCards = selectedCards.length;
    final profile = await getCashierProfile(cashierId);
    final totalIncome = IncomeCalculator.calculateIncome(
      sew: totalCards,
      santim: price,
      cashierProfit: profile.cashierProfit,
      tiers: profile.profitTiers,
      usePartnerCommissionTiers: profile.usePartnerCommissionTiers,
      startGetMoneyFrom: profile.startGetMoneyFrom,
      allowIncomeRounding: profile.allowIncomeRounding,
      lockRoundUpLastDigit: profile.lockRoundUpLastDigit,
    );
    final isFreeTrial = TrialService.isFreeTrialRound(
      packageBalance: packageBalance,
      roundsUsed: roundsUsed,
      cardCount: totalCards,
      pricePerCard: price,
    );

    if (TrialService.isZeroBalance(packageBalance) && !isFreeTrial) {
      if (TrialService.isTrialExhausted(
        packageBalance: packageBalance,
        roundsUsed: roundsUsed,
      )) {
        await _persistGameRound(
          db,
          cashierId: cashierId,
          roundNumber: roundNumber,
          selectedCards: selectedCards,
          price: price,
          pattern: pattern,
        );
        return {
          'status': 'error',
          'code': 'trial_exhausted',
          'package': packageBalance,
          'message': 'Free trial finished. Top up your package to continue.',
        };
      }
      return {
        'status': 'error',
        'code': 'trial_rules',
        'message':
            'During free trial, register exactly 1 card at 10 birr.',
      };
    }

    if (!isFreeTrial && package <= totalIncome + 5) {
      await _persistGameRound(
        db,
        cashierId: cashierId,
        roundNumber: roundNumber,
        selectedCards: selectedCards,
        price: price,
        pattern: pattern,
      );
      return {
        'status': 'error',
        'code': 'wallet_exceeded',
        'package': package.toStringAsFixed(0),
        'message': "Transaction exceeds cashier's package: $package",
      };
    }

    final saved = await _persistGameRound(
      db,
      cashierId: cashierId,
      roundNumber: roundNumber,
      selectedCards: selectedCards,
      price: price,
      pattern: pattern,
    );
    return {
      'status': 'success',
      'message': saved
          ? 'Card updated successfully'
          : 'Card saved successfully',
    };
  }

  /// Saves selected cards for the round so they can be restored after a
  /// failed wallet/trial check or when returning from profile to deposit.
  Future<bool> _persistGameRound(
    Database db, {
    required String cashierId,
    required int roundNumber,
    required List<int> selectedCards,
    required int price,
    required int pattern,
  }) async {
    final selected = selectedCards.join(',');
    final existing = await db.query(
      'game',
      where: 'round_number = ? AND cashier_id = ? AND ${_todayClause()}',
      whereArgs: [roundNumber, cashierId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.update(
        'game',
        {
          'cartela_number': selected,
          'price': '$price',
          'pattern': '$pattern',
          'first_draw': '',
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
      return true;
    }

    await db.insert('game', {
      'cartela_number': selected,
      'cashier_id': cashierId,
      'price': '$price',
      'pattern': '$pattern',
      'round_number': roundNumber,
    });

    final winnerNumber = await _generateBonusWinnerNumber(selectedCards);
    await db.insert('new_bonus', {
      'cashier_id': cashierId,
      'game_id': roundNumber,
      'winner_number': winnerNumber,
    });

    return false;
  }

  Future<String> _generateBonusWinnerNumber(List<int> cardNumbers) async {
    final db = await _db.database;
    final used = <int>{};
    for (final n in cardNumbers) {
      used.add(n);
      final rows = await db.query(
        'cartela',
        where: 'cartela_number = ?',
        whereArgs: [n],
      );
      for (final row in rows) {
        for (final colName in ['b', 'i', 'n', 'g', 'o']) {
          for (final part in '${row[colName]}'.split(',')) {
            final v = int.tryParse(part.trim());
            if (v != null && v > 0) used.add(v);
          }
        }
      }
    }
    final unused = List<int>.generate(
      75,
      (i) => i + 1,
    ).where((n) => !used.contains(n)).toList()..shuffle();
    return unused.take(5).join(',');
  }

  Future<Map<String, dynamic>> saveTransaction({
    required String cashierId,
    required int roundNumber,
    required int santim,
    required int sew,
    required double income,
    required double bonusAmount,
  }) async {
    final packageBalance = await readPackageBalance(cashierId);
    final package = double.tryParse(packageBalance) ?? 0;
    final roundsUsed = await TrialPrefs.loadRoundsUsed(cashierId);
    final isFreeTrial = TrialService.isFreeTrialRound(
      packageBalance: packageBalance,
      roundsUsed: roundsUsed,
      cardCount: sew,
      pricePerCard: santim,
    );

    if (TrialService.isZeroBalance(packageBalance) && !isFreeTrial) {
      if (TrialService.isTrialExhausted(
        packageBalance: packageBalance,
        roundsUsed: roundsUsed,
      )) {
        return {
          'status': 'error',
          'code': 'trial_exhausted',
          'package': package.toStringAsFixed(0),
          'message': 'Free trial finished. Top up your package to continue.',
        };
      }
      return {
        'status': 'error',
        'code': 'trial_rules',
        'message': 'During free trial, use exactly 1 card at 10 birr.',
      };
    }

    final charge = income - bonusAmount;
    if (charge > 0 && package <= charge + 5) {
      return {
        'status': 'error',
        'code': 'wallet_exceeded',
        'package': package.toStringAsFixed(0),
        'message': "Transaction exceeds cashier's package: $package",
      };
    }

    var trialRoundStarted = false;

    return _dbRun((db) async {
      await db.transaction((txn) async {
        final existing = await txn.query(
          '"transaction"',
          where: 'game_round = ? AND cashier_id = ? AND ${_todayClause()}',
          whereArgs: [roundNumber, cashierId],
        );

        if (existing.isNotEmpty) {
          // Round already charged — card counts may sync but house income stays locked.
          await txn.update(
            '"transaction"',
            {
              'santim': '$santim',
              'sew': '$sew',
            },
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        } else {
          trialRoundStarted = isFreeTrial;
          await txn.insert('"transaction"', {
            'cashier_id': cashierId,
            'game_round': roundNumber,
            'santim': '$santim',
            'sew': '$sew',
            'income': income,
            'bonus': bonusAmount,
            'is_trial': isFreeTrial ? 1 : 0,
          });

          final packageInTxn =
              double.tryParse(await _readPackageBalanceExec(txn, cashierId)) ??
              0;
          final newBalance = packageInTxn - (income - bonusAmount);
          await _writePackageBalanceExec(
            txn,
            cashierId,
            newBalance.toStringAsFixed(0),
          );
        }

        // Mark round started — matches ethiomark saveTransaction (iscompleted = 1).
        await txn.update(
          'game',
          {'iscompleted': 1},
          where: 'round_number = ? AND cashier_id = ? AND ${_todayClause()}',
          whereArgs: [roundNumber, cashierId],
        );
      });

      if (trialRoundStarted) {
        await TrialPrefs.increment(cashierId);
      }

      return {
        'status': 'success',
        'message': 'Transaction saved successfully.',
      };
    });
  }

  Future<void> updateGameResult(
    String cashierId,
    int roundNumber,
    List<int> numbers,
  ) async {
    final db = await _db.database;
    await db.update(
      'game',
      {'result': numbers.join(',')},
      where: 'round_number = ? AND cashier_id = ?',
      whereArgs: [roundNumber, cashierId],
    );
  }

  Future<Map<String, dynamic>> completeGame({
    required String cashierId,
    required int roundNumber,
  }) async {
    final game = await getGameForRound(cashierId, roundNumber);
    if (game == null) {
      return {'status': 'error', 'message': 'Game not found.'};
    }
    if (game.result.isEmpty) {
      return {'status': 'error', 'message': 'Play before closing pls.'};
    }

    final db = await _db.database;
    await db.update(
      'game',
      {'iscompleted': 1},
      where: 'round_number = ? AND cashier_id = ?',
      whereArgs: [roundNumber, cashierId],
    );
    await db.update(
      '"transaction"',
      {'result': game.result.join(',')},
      where: 'cashier_id = ? AND game_round = ? AND ${_todayClause()}',
      whereArgs: [cashierId, roundNumber],
    );
    return {
      'status': 'success',
      'message': 'Game marked as completed and results saved.',
    };
  }

  Future<BingoCheckResult?> checkCard({
    required String cashierId,
    required int roundNumber,
    required int cardNumber,
    List<int>? drawnOverride,
    BingoClaimMode claimMode = BingoClaimMode.noRestriction,
    @Deprecated('Use claimMode') int bingoClaimLimit = -1,
  }) async {
    final game = await getGameForRound(cashierId, roundNumber);
    if (game == null || !game.cartelaNumbers.contains(cardNumber)) return null;

    final profile = await getCashierProfile(cashierId);
    final db = await _db.database;
    final rows = await db.query(
      'cartela',
      where: 'cartela_number = ? AND category = ?',
      whereArgs: [cardNumber, profile.category],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final cartela = Cartela.fromMap(rows.first);
    final drawn = drawnOverride ?? game.result;
    return BingoChecker.check(
      cartela: cartela,
      drawn: drawn,
      pattern: game.pattern,
      isLocked: game.lockedCartelas.contains(cardNumber),
      claimMode: claimMode,
      bingoClaimLimit: bingoClaimLimit,
    );
  }

  Future<void> saveCheckedNumber({
    required String cashierId,
    required int roundNumber,
    required int cardNumber,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      '"transaction"',
      where: 'cashier_id = ? AND game_round = ? AND ${_todayClause()}',
      whereArgs: [cashierId, roundNumber],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final existing = (rows.first['checked_number'] as String? ?? '').trim();
    final list = existing.isEmpty ? <String>[] : existing.split(',');
    if (!list.contains('$cardNumber')) list.add('$cardNumber');
    await db.update(
      '"transaction"',
      {'checked_number': list.join(',')},
      where: 'id = ?',
      whereArgs: [rows.first['id']],
    );
  }

  Future<void> lockCartela({
    required String cashierId,
    required int roundNumber,
    required int cardNumber,
  }) async {
    final game = await getGameForRound(cashierId, roundNumber);
    if (game == null) return;
    final locked = [...game.lockedCartelas];
    if (!locked.contains(cardNumber)) locked.add(cardNumber);
    final db = await _db.database;
    await db.update(
      'game',
      {'locked_cartela_number': locked.join(',')},
      where: 'round_number = ? AND cashier_id = ?',
      whereArgs: [roundNumber, cashierId],
    );
  }

  Future<List<Cartela>> listCartelas({
    required String category,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    return _dbRun((db) async {
      final where = StringBuffer('category = ?');
      final args = <Object?>[category];
      if (search != null && search.trim().isNotEmpty) {
        where.write(' AND cartela_number LIKE ?');
        args.add('%${search.trim()}%');
      }
      final rows = await db.query(
        'cartela',
        where: where.toString(),
        whereArgs: args,
        orderBy: 'cartela_number ASC',
        limit: limit,
        offset: offset,
      );
      return rows.map(Cartela.fromMap).toList();
    });
  }

  Future<int> getMaxCartelaNumber(String category) async {
    return _dbRun((db) async {
      final rows = await db.rawQuery(
        'SELECT MAX(cartela_number) AS m FROM cartela WHERE category = ?',
        [category],
      );
      return Sqflite.firstIntValue(rows) ?? 0;
    });
  }

  /// Latest saved game, round, or deposit log timestamp for this cashier.
  Future<DateTime?> getLatestRecordedActivityAt(String cashierId) async {
    return _dbRun((db) async {
      DateTime? latest;

      void consider(String? raw) {
        final parsed = StoredDate.parseDateTime(raw);
        if (parsed == null) return;
        if (latest == null || parsed.isAfter(latest!)) {
          latest = parsed;
        }
      }

      final tx = await db.rawQuery(
        'SELECT MAX(date) AS d FROM "transaction" WHERE cashier_id = ?',
        [cashierId],
      );
      consider(tx.first['d'] as String?);

      final logs = await db.rawQuery(
        'SELECT MAX(timestamp) AS d FROM transaction_logs WHERE cashier_id = ?',
        [cashierId],
      );
      consider(logs.first['d'] as String?);

      final games = await db.rawQuery(
        'SELECT MAX(date) AS d FROM game WHERE cashier_id = ?',
        [cashierId],
      );
      consider(games.first['d'] as String?);

      return latest;
    });
  }

  Future<List<TransactionReportRow>> getReportRows({
    required String cashierId,
    required String startDate,
    required String endDate,
  }) async {
    final startDt = '$startDate 00:00:00';
    final endDt = '$endDate 23:59:59';
    return _dbRun((db) async {
      final rows = await db.rawQuery(
        '''
      SELECT * FROM "transaction"
      WHERE cashier_id = ?
        AND date >= ?
        AND date <= ?
      ORDER BY date DESC
    ''',
        [cashierId, startDt, endDt],
      );

      return rows.map((r) {
        return TransactionReportRow(
          id: r['id'] as int? ?? 0,
          gameRound: r['game_round'] as int? ?? 0,
          santim: int.tryParse('${r['santim']}') ?? 0,
          sew: int.tryParse('${r['sew']}') ?? 0,
          income: (r['income'] as num?)?.toDouble() ?? 0,
          bonus: (r['bonus'] as num?)?.toDouble() ?? 0,
          date: r['date'] as String? ?? '',
          result: r['result'] as String? ?? '',
          checkedNumber: r['checked_number'] as String? ?? '',
        );
      }).toList();
    });
  }

  Future<Map<String, String>?> getLastTransactionLog(String cashierId) async {
    return _dbRun((db) async {
      final rows = await db.query(
        'transaction_logs',
        where: 'cashier_id = ?',
        whereArgs: [cashierId],
        orderBy: 'transaction_id DESC',
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return {
        'action': rows.first['action'] as String? ?? '',
        'amount': '${rows.first['amount']}',
        'message': rows.first['message'] as String? ?? '',
      };
    });
  }

  Future<bool> depositLogExists(String transactionId) async {
    final id = transactionId.trim();
    if (id.isEmpty) return false;
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM transaction_logs WHERE CAST(transaction_id AS TEXT) = ?',
      [id],
    );
    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  Future<bool> insertDepositLog({
    required Map<String, dynamic> transaction,
    required String cashierId,
    required String partnerId,
  }) async {
    final transactionId = '${transaction['transaction_id'] ?? ''}'.trim();
    if (transactionId.isEmpty || await depositLogExists(transactionId)) {
      return false;
    }

    final id = int.tryParse(transactionId);
    if (id == null) return false;

    final db = await _db.database;
    await db.insert('transaction_logs', {
      'transaction_id': id,
      'event_type': transaction['event_type'] ?? 'transaction',
      'timestamp': transaction['timestamp'] ?? DateTime.now().toIso8601String(),
      'done_by': transaction['done_by'] ?? '',
      'role': transaction['role'] ?? 'admin',
      'action': transaction['action'] ?? 'deposit',
      'amount': double.tryParse('${transaction['amount']}') ?? 0,
      'cashier_id': cashierId,
      'partner_id': partnerId,
      'status': transaction['status'] ?? 'success',
      'message': transaction['message'] ?? '',
    });
    return true;
  }

  /// Mirrors ethiomark `deposit_sync_package()` in DepositService.php.
  Future<Map<String, dynamic>> syncPackageDeposit(
    String cashierId,
    DepositService depositService,
  ) async {
    final profile = await getCashierProfile(cashierId);
    final partnerId = '${profile.partnerId}';
    final previousBalance = double.tryParse(profile.packageBalance) ?? 0;
    final domain = await AppConfig.getRemoteDomain();
    final syncInfo = {
      'cashier_id': cashierId,
      'partner_id': partnerId,
      'domain': domain,
    };
    String withSyncInfo(String block) =>
        '$block\n\nSync as:\nCashier: $cashierId\nPartner: $partnerId\nDomain: $domain';

    final remote = await depositService.fetchCashierPackage(
      cashierId: cashierId,
      partnerId: partnerId,
      encryptedMid: profile.mid,
    );

    if (remote['ok'] != true) {
      if (remote['offline'] == true) {
        return {
          'status': 'offline',
          'message': remote['message'],
          'sync_info': syncInfo,
          'code_block': withSyncInfo(
            "╔══════════════════════════════════╗\n║  OFFLINE — NO DEPOSIT FETCHED    ║\n╚══════════════════════════════════╝",
          ),
          'display': {
            'cashier_id': cashierId,
            'previous_balance': previousBalance,
            'new_balance': previousBalance,
          },
        };
      }
      return {
        'status': 'error',
        'message': remote['message'] ?? 'Remote request failed.',
        'sync_info': syncInfo,
        'code_block': withSyncInfo(
          "╔══════════════════════════════════╗\n║        REQUEST FAILED            ║\n╚══════════════════════════════════╝",
        ),
      };
    }

    final response = remote['data'] as Map<String, dynamic>;
    if (response['status'] != 'success') {
      return {
        'status': 'error',
        'message': response['message'] ?? 'Admin server returned an error.',
        'code_block':
            "╔══════════════════════════════════╗\n║        ADMIN ERROR               ║\n╚══════════════════════════════════╝",
      };
    }

    var remoteAmount = double.tryParse('${response['cashier_package']}') ?? 0;
    final transaction = response['transaction'];

    if (remoteAmount == 0) {
      return {
        'status': 'empty',
        'message':
            'No pending package for cashier $cashierId (partner $partnerId) on $domain. '
            'Use the same IDs as admin deposit, then Re-fetch.',
        'sync_info': syncInfo,
        'code_block': withSyncInfo(
          "╔══════════════════════════════════╗\n║  NO PENDING DEPOSIT AVAILABLE    ║\n╚══════════════════════════════════╝",
        ),
        'display': {
          'cashier_id': cashierId,
          'deposit_amount': 0,
          'previous_balance': previousBalance,
          'new_balance': previousBalance,
        },
      };
    }

    if (transaction is! Map<String, dynamic>) {
      return {
        'status': 'error',
        'message': 'Admin response missing transaction — deposit blocked.',
      };
    }

    final transactionId = '${transaction['transaction_id'] ?? ''}'.trim();
    if (transactionId.isEmpty) {
      return {
        'status': 'error',
        'message':
            'Admin response missing transaction_id — deposit blocked to prevent duplicates.',
      };
    }

    if (transaction['amount'] != null) {
      remoteAmount =
          double.tryParse('${transaction['amount']}') ?? remoteAmount;
    }

    if (await depositLogExists(transactionId)) {
      final ack = await depositService.ackRemotePackage(
        cashierId: cashierId,
        partnerId: partnerId,
        transactionId: transactionId,
        duplicateLocal: true,
      );
      final display = {
        'cashier_id': cashierId,
        'deposit_amount': remoteAmount,
        'previous_balance': previousBalance,
        'new_balance': previousBalance,
        'transaction_id': transactionId,
        'confirmed_remote': ack['ok'] == true,
        'timestamp': transaction['timestamp'] ?? '',
      };
      return {
        'status': 'duplicate',
        'message': ack['ok'] == true
            ? 'Already applied on this device. Admin pending deposit cleared.'
            : 'Already applied on this device. Could not clear admin pending — tap Re-fetch.',
        'display': display,
        'code_block': formatDepositCodeBlock(display),
      };
    }

    final newBalance = previousBalance + remoteAmount;
    await writePackageBalance(cashierId, newBalance.toStringAsFixed(0));

    final savedBalance =
        double.tryParse(await readPackageBalance(cashierId)) ?? 0;
    if ((savedBalance - newBalance).abs() > 0.01) {
      return {
        'status': 'error',
        'message':
            'Deposit could not be verified after save. Balance still shows $savedBalance birr.',
      };
    }

    final logged = await insertDepositLog(
      transaction: transaction,
      cashierId: cashierId,
      partnerId: partnerId,
    );
    if (!logged) {
      return {
        'status': 'error',
        'message': 'Package updated but transaction log failed.',
      };
    }

    final ack = await depositService.ackRemotePackage(
      cashierId: cashierId,
      partnerId: partnerId,
      transactionId: transactionId,
    );

    final display = {
      'cashier_id': cashierId,
      'deposit_amount': remoteAmount,
      'previous_balance': previousBalance,
      'new_balance': newBalance,
      'transaction_id': transactionId,
      'action': transaction['action'] ?? 'deposit',
      'timestamp': transaction['timestamp'] ?? '',
      'done_by': transaction['done_by'] ?? '',
      'confirmed_remote': ack['ok'] == true,
    };

    return {
      'status': 'success',
      'message': 'Package deposited and saved securely.',
      'display': display,
      'code_block': formatDepositCodeBlock(display),
    };
  }

  Future<void> applyPackageDeposit({
    required String cashierId,
    required double amount,
    required String doneBy,
  }) async {
    final current = double.tryParse(await readPackageBalance(cashierId)) ?? 0;
    await writePackageBalance(cashierId, (current + amount).toStringAsFixed(0));
    final db = await _db.database;
    await db.insert('transaction_logs', {
      'event_type': 'deposit',
      'done_by': doneBy,
      'role': 'cashier',
      'action': 'package_deposit',
      'amount': amount,
      'cashier_id': cashierId,
      'status': 'success',
      'message': 'Package topped up by $amount birr',
    });
  }

  Future<bool> manualDepositRequestExists(String fingerprint) async {
    final trimmed = fingerprint.trim();
    if (trimmed.isEmpty) return false;
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM transaction_logs "
      "WHERE action IN ('manual_deposit', 'manual_withdrawal') AND message = ?",
      [trimmed],
    );
    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  /// Offline manual deposit: machine id + random + amount + admin response code.
  Future<Map<String, dynamic>> applyManualDeposit({
    required String cashierId,
    required String partnerId,
    required String machineId,
    required int randomNumber,
    required int amount,
    required String responseCode,
  }) async {
    final lockout = await ManualDepositLockout.load();
    if (lockout.isLocked) {
      return {
        'status': 'error',
        'code': 'manual_deposit_locked',
        'remaining_seconds': lockout.remaining.inSeconds,
      };
    }

    // Positive = deposit; negative = withdrawal (deduct from cashier wallet).
    if (amount == 0) {
      return {'status': 'error', 'code': 'invalid_deposit_amount'};
    }

    if (!ManualDepositCodec.verifyResponseCode(
      machineId: machineId,
      randomNumber: randomNumber,
      amount: amount,
      responseInput: responseCode,
    )) {
      final afterFailure = await ManualDepositLockout.recordFailedAttempt();
      return {
        'status': 'error',
        'code': afterFailure.isLocked
            ? 'manual_deposit_locked'
            : 'invalid_deposit_code',
        if (afterFailure.isLocked)
          'remaining_seconds': afterFailure.remaining.inSeconds
        else
          'attempts_remaining': afterFailure.attemptsRemaining,
      };
    }

    final fingerprint = ManualDepositCodec.requestFingerprint(
      machineId: machineId,
      randomNumber: randomNumber,
      amount: amount,
    );

    if (await manualDepositRequestExists(fingerprint)) {
      return {'status': 'duplicate', 'code': 'duplicate_deposit_code'};
    }

    final profile = await getCashierProfile(cashierId);
    final previousBalance = double.tryParse(profile.packageBalance) ?? 0;
    final newBalance = previousBalance + amount;
    if (amount < 0 && newBalance < 0) {
      return {
        'status': 'error',
        'code': 'insufficient_wallet_balance',
        'balance': previousBalance.toStringAsFixed(0),
      };
    }

    await writePackageBalance(cashierId, newBalance.toStringAsFixed(0));

    await ManualDepositLockout.reset();

    final serial = ManualDepositCodec.serialDecimalFromMachineId(machineId);
    final db = await _db.database;
    await db.insert('transaction_logs', {
      'event_type': amount < 0 ? 'withdrawal' : 'deposit',
      'timestamp': DateTime.now().toIso8601String(),
      'done_by': 'manual',
      'role': 'cashier',
      'action': amount < 0 ? 'manual_withdrawal' : 'manual_deposit',
      'amount': amount.toDouble(),
      'cashier_id': cashierId,
      'partner_id': partnerId,
      'status': 'success',
      'message': fingerprint,
    });

    final action = amount < 0 ? 'manual_withdrawal' : 'manual_deposit';
    final display = {
      'cashier_id': cashierId,
      'deposit_amount': amount,
      'previous_balance': previousBalance,
      'new_balance': newBalance,
      'transaction_id': fingerprint,
      'machine_serial': serial,
      'random_number': randomNumber,
      'response_code': responseCode.trim(),
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      'done_by': 'manual',
      'confirmed_remote': false,
    };

    return {
      'status': 'success',
      'message': amount < 0
          ? 'manual_withdrawal_success'
          : 'manual_deposit_success',
      'balance': newBalance.toStringAsFixed(0),
      'display': display,
      'code_block': formatDepositCodeBlock(display),
    };
  }

  Future<void> updateSettings(
    String cashierId,
    Map<String, dynamic> settings,
  ) async {
    await _dbRun((db) async {
      final bonus = settings['bonus'] as Map<String, dynamic>? ?? {};
      final system = settings['system'] as Map<String, dynamic>? ?? {};
      final parsed = PlayerBonusSettings.fromMap(bonus);
      settings['bonus'] = parsed.toMap();
      await db.update(
        'cashier',
        {
          'settings_json': jsonEncode(settings),
          'new_bonus_status': parsed.isEnabled ? 'on' : 'off',
          'auto_check_result': system['check_result'] ?? CashierDefaults.checkMode,
          'color': system['color_mode'] ?? 'three',
          'cashier_profit': int.tryParse('${system['profit']}') ?? 0,
          'good_bingo_sound':
              int.tryParse('${system['good_bingo_sound']}') ?? 0,
          'max_new_bonus_per_day': parsed.perDay,
        },
        where: 'cashier_id = ?',
        whereArgs: [cashierId],
      );
    });
  }

  Future<void> updatePlayPreferences({
    required String cashierId,
    required Map<String, dynamic> currentSettings,
    int? sound,
    int? speedRange,
    String? checkMode,
    int? goodBingoSound,
    int? cashierProfit,
    int? bingoClaimLimit,
    BingoClaimMode? bingoClaimMode,
    String? currency,
    String? language,
    String? incomeRounding,
  }) async {
    final settings = Map<String, dynamic>.from(currentSettings);
    final system = Map<String, dynamic>.from(
      settings['system'] as Map<String, dynamic>? ?? {},
    );
    if (checkMode != null) system['check_result'] = checkMode;
    if (goodBingoSound != null) system['good_bingo_sound'] = goodBingoSound;
    if (cashierProfit != null) system['profit'] = cashierProfit;
    if (bingoClaimMode != null) {
      system[BingoClaimMode.storageKey] = bingoClaimMode.id;
      system['bingo_claim_limit'] = bingoClaimMode.legacyLimit;
    } else if (bingoClaimLimit != null) {
      system['bingo_claim_limit'] = bingoClaimLimit;
      system[BingoClaimMode.storageKey] =
          BingoClaimMode.fromSettings({'bingo_claim_limit': bingoClaimLimit}).id;
    }
    if (currency != null) system['currency'] = AppCurrency.normalize(currency);
    if (language != null) system['language'] = language;
    if (incomeRounding != null) system['income_rounding'] = incomeRounding;
    settings['system'] = system;

    await _dbRun((db) async {
      final data = <String, Object?>{'settings_json': jsonEncode(settings)};
      if (sound != null) data['sound'] = sound;
      if (speedRange != null) data['speed_range'] = speedRange;
      if (checkMode != null) data['auto_check_result'] = checkMode;
      if (goodBingoSound != null) data['good_bingo_sound'] = goodBingoSound;
      if (cashierProfit != null) data['cashier_profit'] = cashierProfit;
      await db.update(
        'cashier',
        data,
        where: 'cashier_id = ?',
        whereArgs: [cashierId],
      );
    });
  }

  /// Old Start-modal package bonus — always 0; player bonus is claimed after Good Bingo.
  Future<double> resolveStartModalPrizeAmount({
    required String cashierId,
    required int cardCount,
    required int pricePerCard,
    required Map<String, dynamic> settings,
  }) async {
    return 0;
  }

  Future<List<int>> getCheckedWinnerNumbers({
    required String cashierId,
    required int roundNumber,
  }) async {
    return _dbRun((db) async {
      final rows = await db.query(
        '"transaction"',
        columns: ['checked_number'],
        where: 'cashier_id = ? AND game_round = ? AND ${_todayClause()}',
        whereArgs: [cashierId, roundNumber],
        limit: 1,
      );
      if (rows.isEmpty) return const [];
      final raw = (rows.first['checked_number'] as String? ?? '').trim();
      if (raw.isEmpty) return const [];
      return raw
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList();
    });
  }

  Future<double> getRoundBonusAmount({
    required String cashierId,
    required int roundNumber,
  }) async {
    return _dbRun((db) async {
      final rows = await db.query(
        '"transaction"',
        columns: ['bonus'],
        where: 'cashier_id = ? AND game_round = ? AND ${_todayClause()}',
        whereArgs: [cashierId, roundNumber],
        limit: 1,
      );
      if (rows.isEmpty) return 0;
      return (rows.first['bonus'] as num?)?.toDouble() ?? 0;
    });
  }

  /// Writes fixed player-bonus amount onto the round transaction (report only).
  Future<void> applyPlayerBonusAmount({
    required String cashierId,
    required int roundNumber,
    required double amount,
  }) async {
    await _dbRun((db) async {
      await db.update(
        '"transaction"',
        {'bonus': amount},
        where: 'cashier_id = ? AND game_round = ? AND ${_todayClause()}',
        whereArgs: [cashierId, roundNumber],
      );
    });
  }

  /// Claim lucky-card bonus after first Good Bingo (excludes known winners).
  Future<PlayerBonusClaimResult> claimPlayerBonus({
    required String cashierId,
    required int roundNumber,
    required List<int> registeredCards,
    required Map<String, dynamic> settings,
  }) async {
    final cfg = PlayerBonusSettings.fromSettings(settings);
    final awardsToday = await countTodayBonusAwards(cashierId);
    if (!cfg.hasDailyQuotaRemaining(awardsToday)) {
      return const PlayerBonusClaimResult(
        luckyCards: [],
        amount: 0,
        skipped: true,
      );
    }

    final winners = await getCheckedWinnerNumbers(
      cashierId: cashierId,
      roundNumber: roundNumber,
    );
    final winnerSet = winners.toSet();
    final nonWinners = registeredCards
        .where((c) => !winnerSet.contains(c))
        .toList();

    if (nonWinners.isEmpty) {
      return const PlayerBonusClaimResult(
        luckyCards: [],
        amount: 0,
        skipped: true,
      );
    }

    nonWinners.shuffle(Random());
    final lucky = nonWinners.take(cfg.count).toList()..sort();
    await applyPlayerBonusAmount(
      cashierId: cashierId,
      roundNumber: roundNumber,
      amount: cfg.amount.toDouble(),
    );
    return PlayerBonusClaimResult(
      luckyCards: lucky,
      amount: cfg.amount,
      skipped: false,
    );
  }

  Future<int> getBonusEligibilityStartsFrom(String cashierId) async {
    return _dbRun((db) async {
      final rows = await db.rawQuery(
        '''
        SELECT p.bonus_eligiblity_starts_from
        FROM cashier c
        JOIN partner p ON p.partner_id = c.partner_id
        WHERE c.cashier_id = ?
        ''',
        [cashierId],
      );
      if (rows.isEmpty) return 0;
      return int.tryParse('${rows.first['bonus_eligiblity_starts_from']}') ?? 0;
    });
  }

  Future<int> countTodayBonusAwards(String cashierId) async {
    return _dbRun((db) async {
      final rows = await db.rawQuery(
        '''
        SELECT COUNT(bonus) AS count
        FROM "transaction"
        WHERE cashier_id = ?
          AND ${_todayClause()}
          AND bonus > 0
        ''',
        [cashierId],
      );
      return (rows.first['count'] as int?) ?? 0;
    });
  }

  /// Active timed game bonus (0 when none or already awarded today).
  Future<double> getAvailableGameBonusAmount(String cashierId) async {
    return _dbRun((db) async {
      final bonusTodayRows = await db.rawQuery(
        '''
        SELECT SUM(bonus) AS total_bonus
        FROM "transaction"
        WHERE cashier_id = ?
          AND ${_todayClause()}
        ''',
        [cashierId],
      );
      final totalBonusToday =
          (bonusTodayRows.first['total_bonus'] as num?)?.toDouble() ?? 0;
      if (totalBonusToday > 0) return 0;

      final partnerRows = await db.rawQuery(
        '''
        SELECT
          c.cashier_bonus_status,
          c.cashier_fixed_bonus_amount,
          p.min_bonus,
          p.max_bonus,
          p.bonus_status,
          p.fixed_bonus_amount
        FROM cashier c
        JOIN partner p ON p.partner_id = c.partner_id
        WHERE c.cashier_id = ?
        ''',
        [cashierId],
      );
      if (partnerRows.isEmpty) return 0;

      final row = partnerRows.first;
      final cashierBonusStatus = row['cashier_bonus_status'] as int? ?? 0;
      int bonusStatus;
      int fixedBonusAmount;
      if (cashierBonusStatus > 0) {
        bonusStatus = cashierBonusStatus;
        fixedBonusAmount = row['cashier_fixed_bonus_amount'] as int? ?? 0;
      } else {
        bonusStatus = row['bonus_status'] as int? ?? 0;
        fixedBonusAmount = row['fixed_bonus_amount'] as int? ?? 0;
      }

      if (bonusStatus == 2) return 0;

      if (bonusStatus != 0 && bonusStatus != 1) return 0;

      final gameBonusRows = await db.rawQuery(
        '''
        SELECT bonus_amount
        FROM game_bonus
        WHERE cashier_id = ?
          AND datetime('now', 'localtime')
            BETWEEN bonus_start_time AND bonus_end_time
        ''',
        [cashierId],
      );
      if (gameBonusRows.isEmpty) return 0;

      var amount =
          (gameBonusRows.first['bonus_amount'] as num?)?.toDouble() ?? 0;
      if (amount <= 0) return 0;

      if (bonusStatus == 1) {
        return fixedBonusAmount.toDouble();
      }

      final minBonus = row['min_bonus'] as int? ?? 0;
      final maxBonus = row['max_bonus'] as int? ?? 0;
      if (amount > maxBonus) amount = maxBonus.toDouble();
      if (amount < minBonus) amount = minBonus.toDouble();
      return amount;
    });
  }

  // —— Cartela management ——

  Future<List<({String name, int count})>> listCartelaCategoriesWithCounts() async {
    return _dbRun((db) async {
      final rows = await db.rawQuery(
        'SELECT category, COUNT(*) AS c FROM cartela GROUP BY category ORDER BY category ASC',
      );
      return rows
          .map((r) => (name: '${r['category']}', count: r['c'] as int? ?? 0))
          .where((e) => e.name.isNotEmpty)
          .toList();
    });
  }

  Future<bool> cartelaCategoryExists(String name) async {
    return _dbRun((db) async {
      final rows = await db.rawQuery(
        'SELECT 1 FROM cartela WHERE category = ? LIMIT 1',
        [name],
      );
      return rows.isNotEmpty;
    });
  }

  Future<void> renameCartelaCategory({
    required String from,
    required String to,
  }) async {
    if (from == to) return;
    await _dbRun((db) async {
      await db.update(
        'cartela',
        {'category': to},
        where: 'category = ?',
        whereArgs: [from],
      );
      await db.update(
        'cashier',
        {'category': to},
        where: 'category = ?',
        whereArgs: [from],
      );
    });
    await _refreshCartelaBootstrapCache();
  }

  Future<void> deleteCartelaCategory(String category) async {
    await _dbRun((db) async {
      await db.delete(
        'cartela',
        where: 'category = ?',
        whereArgs: [category],
      );
      final fallbackRows = await db.rawQuery(
        'SELECT DISTINCT category FROM cartela ORDER BY category ASC LIMIT 1',
      );
      final fallback = fallbackRows.isEmpty
          ? 'default'
          : '${fallbackRows.first['category']}';
      await db.update(
        'cashier',
        {'category': fallback},
        where: 'category = ?',
        whereArgs: [category],
      );
    });
    await _refreshCartelaBootstrapCache();
  }

  Future<bool> cartelaNumberExists({
    required String category,
    required int number,
    int? excludeId,
  }) async {
    return _dbRun((db) async {
      final where = excludeId == null
          ? 'category = ? AND cartela_number = ?'
          : 'category = ? AND cartela_number = ? AND id != ?';
      final args = excludeId == null
          ? [category, number]
          : [category, number, excludeId];
      final rows = await db.query(
        'cartela',
        where: where,
        whereArgs: args,
        limit: 1,
      );
      return rows.isNotEmpty;
    });
  }

  Future<int> insertCartela({
    required String category,
    required int number,
    required List<int> b,
    required List<int> i,
    required List<int> n,
    required List<int> g,
    required List<int> o,
  }) async {
    final id = await _dbRun((db) async {
      return await db.insert('cartela', {
        'cartela_number': number,
        'b': _formatCartelaColumn(b),
        'i': _formatCartelaColumn(i),
        'n': _formatCartelaColumn(n),
        'g': _formatCartelaColumn(g),
        'o': _formatCartelaColumn(o),
        'date': DateTime.now().toIso8601String(),
        'category': category,
      });
    });
    await _refreshCartelaBootstrapCache();
    return id;
  }

  Future<void> updateCartela({
    required int id,
    required int number,
    required List<int> b,
    required List<int> i,
    required List<int> n,
    required List<int> g,
    required List<int> o,
  }) async {
    await _dbRun((db) async {
      await db.update(
        'cartela',
        {
          'cartela_number': number,
          'b': _formatCartelaColumn(b),
          'i': _formatCartelaColumn(i),
          'n': _formatCartelaColumn(n),
          'g': _formatCartelaColumn(g),
          'o': _formatCartelaColumn(o),
          'date': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    await _refreshCartelaBootstrapCache();
  }

  Future<void> deleteCartela(int id) async {
    await _dbRun((db) async {
      await db.delete(
        'cartela',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    await _refreshCartelaBootstrapCache();
  }

  String _formatCartelaColumn(List<int> values) => values.join(',');

  Future<void> _refreshCartelaBootstrapCache() async {
    final count = await _db.countCartelas();
    await BootstrapCache.markCartelasReady(count);
  }
}
