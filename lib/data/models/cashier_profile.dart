import 'dart:convert';

import '../../core/bingo/bet_calculator.dart';
import '../../core/config/cashier_defaults.dart';

class CashierProfile {
  const CashierProfile({
    required this.cashierId,
    required this.partnerId,
    required this.category,
    required this.packageBalance,
    required this.speedRange,
    required this.sound,
    required this.cashierProfit,
    required this.settings,
    required this.profitTiers,
    required this.usePartnerCommissionTiers,
    required this.startGetMoneyFrom,
    required this.lockRoundUpLastDigit,
    required this.isLocked,
    required this.isActive,
    required this.mid,
  });

  final String cashierId;
  final int partnerId;
  final String category;
  final String packageBalance;
  final int speedRange;
  final int sound;
  final int cashierProfit;
  final Map<String, dynamic> settings;
  final List<CommissionTier> profitTiers;
  final bool usePartnerCommissionTiers;
  final int startGetMoneyFrom;
  final bool lockRoundUpLastDigit;
  final bool isLocked;
  final bool isActive;
  final String? mid;

  bool get allowIncomeRounding {
    final system = settings['system'] as Map<String, dynamic>? ?? {};
    return system['income_rounding'] == 'on';
  }

  factory CashierProfile.fromMap(
    Map<String, Object?> map,
    String packageBalance,
  ) {
    Map<String, dynamic> settings = {};
    try {
      settings =
          jsonDecode(map['settings_json'] as String? ?? '{}')
              as Map<String, dynamic>;
    } catch (_) {}

    final tiers = <CommissionTier>[];
    try {
      final profit =
          jsonDecode(map['profit_json'] as String? ?? '{}')
              as Map<String, dynamic>;
      final list = profit['commission_tiers'] as List<dynamic>? ?? [];
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          tiers.add(
            CommissionTier(
              min: item['min'] as int? ?? 0,
              max: item['max'] as int? ?? 0,
              percent: (item['percent'] as num?)?.toDouble() ?? 0,
            ),
          );
        }
      }
    } catch (_) {}

    return CashierProfile(
      cashierId: map['cashier_id'] as String? ?? '',
      partnerId: map['partner_id'] as int? ?? 0,
      category: map['category'] as String? ?? 'default',
      packageBalance: packageBalance,
      speedRange: _parseSpeedRange(map['speed_range']),
      sound: map['sound'] as int? ?? CashierDefaults.callerVoice,
      cashierProfit: map['cashier_profit'] as int? ?? 0,
      settings: settings,
      profitTiers: tiers,
      usePartnerCommissionTiers: _partnerCommissionTiersOn(
        map['partner_settings'] as String?,
      ),
      startGetMoneyFrom:
          int.tryParse('${map['start_get_mony_from']}') ?? 0,
      lockRoundUpLastDigit:
          (map['lock_round_up_last_digit'] as int? ?? 0) == 1,
      isLocked: (map['is_locked'] as int? ?? 0) == 1,
      isActive: (map['is_active'] as int? ?? 0) == 1,
      mid: map['mid'] as String?,
    );
  }

  static bool _partnerCommissionTiersOn(String? partnerSettingsJson) {
    if (partnerSettingsJson == null || partnerSettingsJson.trim().isEmpty) {
      return false;
    }
    try {
      final settings =
          jsonDecode(partnerSettingsJson) as Map<String, dynamic>;
      final custom =
          settings['custom_profit_json'] as Map<String, dynamic>?;
      return custom?['status'] == 'on';
    } catch (_) {
      return false;
    }
  }

  static int _parseSpeedRange(Object? value) {
    final parsed = value is int ? value : int.tryParse('$value');
    if (parsed == null || parsed < 1) return CashierDefaults.speedRange;
    return parsed;
  }
}

class CommissionTier {
  const CommissionTier({
    required this.min,
    required this.max,
    required this.percent,
  });
  final int min;
  final int max;
  final double percent;
}

class TransactionReportRow {
  const TransactionReportRow({
    required this.id,
    required this.gameRound,
    required this.santim,
    required this.sew,
    required this.income,
    required this.bonus,
    required this.date,
    required this.result,
    required this.checkedNumber,
  });

  final int id;
  final int gameRound;
  final int santim;
  final int sew;
  final double income;
  final double bonus;
  final String date;
  final String result;
  final String checkedNumber;

  int get drawnCount => result.isEmpty
      ? 0
      : result.split(',').where((e) => e.trim().isNotEmpty).length;
  int get totalBet =>
      BetCalculator.totalBet(cardCount: sew, pricePerCard: santim);
  double get paid => totalBet - income;
  bool get isFreeDemoRound =>
      BetCalculator.isFreeDemoRound(cardCount: sew, pricePerCard: santim);
}

class DepositLogRow {
  const DepositLogRow({
    required this.transactionId,
    required this.timestamp,
    required this.action,
    required this.amount,
    required this.status,
    required this.message,
  });

  final int transactionId;
  final String timestamp;
  final String action;
  final double amount;
  final String status;
  final String message;
}
