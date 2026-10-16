import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';

/// HTTP client for remote admin package sync (mirrors ethiomark DepositService.php).
class DepositService {
  Future<Map<String, dynamic>> remotePost(Map<String, String> data) async {
    final url = await AppConfig.remoteSyncUrl();
    try {
      final response = await http
          .post(Uri.parse(url), body: data)
          .timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        return {
          'ok': false,
          'message': 'Server returned HTTP ${response.statusCode}',
          'url': url,
        };
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return {
          'ok': false,
          'message': 'Invalid JSON from admin server.',
          'url': url,
          'raw': response.body.length > 200
              ? '${response.body.substring(0, 200)}…'
              : response.body,
        };
      }

      return {'ok': true, 'data': decoded, 'url': url};
    } catch (e) {
      return {
        'ok': false,
        'offline': true,
        'message': 'Unable to reach admin server. Check internet connection.',
      };
    }
  }

  Future<Map<String, dynamic>> fetchCashierPackage({
    required String cashierId,
    required String partnerId,
    String? encryptedMid,
  }) {
    final payload = <String, String>{
      'cashier_id': cashierId,
      'partner_id': partnerId,
      'request_type': 'fetch_cashier_package',
    };
    if (encryptedMid != null && encryptedMid.trim().isNotEmpty) {
      payload['mid'] = encryptedMid.trim();
    }
    return remotePost(payload);
  }

  Future<Map<String, dynamic>> ackRemotePackage({
    required String cashierId,
    required String partnerId,
    required String transactionId,
    bool duplicateLocal = false,
  }) async {
    final payload = <String, String>{
      'cashier_id': cashierId,
      'partner_id': partnerId,
      'request_type': 'cashier_package_confirm_is_ok',
      'clear_pending': '1',
      'transaction_id': transactionId,
    };
    if (duplicateLocal) {
      payload['duplicate_local'] = '1';
    }

    final result = await remotePost(payload);
    final data = result['data'];
    final ok =
        result['ok'] == true && data is Map && data['status'] == 'success';
    return {
      'ok': ok,
      'message': data is Map
          ? '${data['message'] ?? ''}'
          : '${result['message'] ?? ''}',
    };
  }
}

String formatDepositCodeBlock(Map<String, dynamic> display) {
  String row(String label, String value) {
    final text = '$label : $value';
    return '║ ${text.padRight(40).substring(0, text.length.clamp(0, 40))}${' ' * (40 - text.length).clamp(0, 40)}║';
  }

  return [
    '╔══════════════════════════════════════════╗',
    '║         PACKAGE DEPOSIT RESULT           ║',
    '╠══════════════════════════════════════════╣',
    row('Cashier', '${display['cashier_id'] ?? ''}'),
    row('Deposit', '${_fmtNum(display['deposit_amount'])} Birr'),
    row('Old balance', '${_fmtNum(display['previous_balance'])} Birr'),
    row('New balance', '${_fmtNum(display['new_balance'])} Birr'),
    '╠══════════════════════════════════════════╣',
    row('Time', '${display['timestamp'] ?? '-'}'),
    row('Remote OK', (display['confirmed_remote'] == true) ? 'Yes' : 'No'),
    '╚══════════════════════════════════════════╝',
  ].join('\n');
}

String _fmtNum(Object? v) {
  final n = double.tryParse('$v') ?? 0;
  return n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
}
