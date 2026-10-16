import 'dart:convert';

import 'package:encrypt/encrypt.dart';

/// Matches ethiomark `config/PackageCrypto.php` (AES-256-CBC + device serial).
class PackageCrypto {
  static const baseKey = '0dN8G\$kPz9HcL3u!vB1eTxQz6RmJ2s';
  static const baseIv = 'a9BvC3eF5hJ7kL1M';

  static String keyFromSerial(String serial) {
    final trimmed = serial.trim();
    final prefix = trimmed.length >= 2 ? trimmed.substring(0, 2) : 'XX';
    return '$baseKey$prefix';
  }

  static String encryptValue(String value, String serial) {
    if (value.isEmpty) return '';
    final key = Key.fromUtf8(keyFromSerial(serial));
    final iv = IV.fromUtf8(baseIv);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    final encrypted = encrypter.encrypt(value, iv: iv);
    return base64.encode(encrypted.bytes);
  }

  static String? decryptValue(String? stored, String serial) {
    final text = (stored ?? '').trim();
    if (text.isEmpty) return null;
    if (num.tryParse(text) != null) return null;

    try {
      final decoded = base64.decode(text);
      final key = Key.fromUtf8(keyFromSerial(serial));
      final iv = IV.fromUtf8(baseIv);
      final encrypter = Encrypter(
        AES(key, mode: AESMode.cbc, padding: 'PKCS7'),
      );
      final plain = encrypter.decrypt(Encrypted(decoded), iv: iv);
      if (plain.isEmpty) return null;
      return plain;
    } catch (_) {
      return null;
    }
  }

  static String encryptCashierPackage(String amount, String serial) {
    return encryptValue(amount, serial);
  }

  static String encryptMachineMid(String serial) {
    return encryptValue(serial, serial);
  }

  static List<String> serialCandidates({String? serial, String? encryptedMid}) {
    final candidates = <String>{};
    if (serial != null && serial.trim().isNotEmpty) {
      candidates.add(serial.trim());
    }
    if (encryptedMid != null && encryptedMid.isNotEmpty) {
      for (final candidate in List<String>.from(candidates)) {
        final fromMid = decryptValue(encryptedMid, candidate);
        if (fromMid != null && fromMid.isNotEmpty) {
          candidates.add(fromMid);
        }
      }
    }
    return candidates.toList();
  }

  static String decryptCashierPackage(
    String? stored, {
    String? serial,
    String? encryptedMid,
    bool allowPlain = false,
  }) {
    final text = (stored ?? '').trim();
    if (text.isEmpty || text == '0') return '0';
    if (num.tryParse(text) != null) {
      return allowPlain ? text : '0';
    }

    for (final candidate in serialCandidates(
      serial: serial,
      encryptedMid: encryptedMid,
    )) {
      final plain = decryptValue(text, candidate);
      if (plain != null && plain.isNotEmpty) {
        return plain;
      }
    }
    return '0';
  }

  static String decryptMachineMid(String? stored, {String? serial}) {
    for (final candidate in serialCandidates(
      serial: serial,
      encryptedMid: stored,
    )) {
      final plain = decryptValue(stored, candidate);
      if (plain != null && plain.isNotEmpty) {
        return plain;
      }
    }
    return '';
  }
}
