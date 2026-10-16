import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../crypto/package_crypto.dart';

/// Offline manual deposit request/response encoding.
///
/// Admin generates the response code from:
/// serial (decimal) + random number + amount — same formula as [computeResponseCode].
class ManualDepositCodec {
  static const serialHexLength = 7;

  /// Seven hex chars from device id (GUID hex) or MD5 fallback.
  static String serialHexFromMachineId(String machineId) {
    final hexOnly = machineId.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    if (hexOnly.length >= serialHexLength) {
      return hexOnly.substring(0, serialHexLength).toUpperCase();
    }
    final hash = md5.convert(utf8.encode(machineId.trim())).toString();
    return hash.substring(0, serialHexLength).toUpperCase();
  }

  /// Matches C# `Convert.ToInt64(serial, 16)`.
  static int serialDecimalFromHex(String hexSerial) {
    return int.parse(hexSerial.trim().toUpperCase(), radix: 16);
  }

  static int serialDecimalFromMachineId(String machineId) {
    return serialDecimalFromHex(serialHexFromMachineId(machineId));
  }

  static int generateRandomNumber() {
    final rng = Random.secure();
    return 100000 + rng.nextInt(900000);
  }

  /// Unique key for a deposit request (machine + random + amount).
  static String requestFingerprint({
    required String machineId,
    required int randomNumber,
    required int amount,
  }) {
    final serial = serialDecimalFromMachineId(machineId);
    return '$serial-$randomNumber-$amount';
  }

  static String formatRequestForCopy({
    required int serialDecimal,
    required int randomNumber,
    required int amount,
    required String cashierId,
  }) {
    return [
      'Cashier: $cashierId',
      'Request: $serialDecimal $randomNumber',
      'Generated ID: $serialDecimal',
      'Random: $randomNumber',
      'Amount: $amount',
    ].join('\n');
  }

  static int computeResponseCode({
    required String machineId,
    required int randomNumber,
    required int amount,
  }) {
    return computeResponseCodeFromParts(
      serialDecimal: serialDecimalFromMachineId(machineId),
      randomNumber: randomNumber,
      amount: amount,
    );
  }

  static int computeResponseCodeFromParts({
    required int serialDecimal,
    required int randomNumber,
    required int amount,
  }) {
    final input = '$serialDecimal|$randomNumber|$amount|${PackageCrypto.baseKey}';
    final digest = sha256.convert(utf8.encode(input)).bytes;
    var value = 0;
    for (var i = 0; i < 8; i++) {
      value = (value * 256 + digest[i]) % 10000000000;
    }
    if (value < 100000000) {
      value += 100000000;
    }
    return value;
  }

  static bool verifyResponseCode({
    required String machineId,
    required int randomNumber,
    required int amount,
    required String responseInput,
  }) {
    final trimmed = responseInput.trim().replaceAll(RegExp(r'\s+'), '');
    final entered = int.tryParse(trimmed);
    if (entered == null) return false;
    return entered ==
        computeResponseCode(
          machineId: machineId,
          randomNumber: randomNumber,
          amount: amount,
        );
  }
}
