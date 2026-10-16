import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

/// AES-256-CBC encryption for cartela JSON exports (bundled assets + profile imports).
class CartelaCrypto {
  static const _magic = 'EMBCARTELA1:';
  static const _ivSeed = 'CartelaIv16bytes';

  static Key get _key {
    final digest = sha256.convert(
      utf8.encode('EthiomarkCartela|0dN8G\$kPz9HcL3u!vB1eTxQz6RmJ2s|v1'),
    );
    return Key(Uint8List.fromList(digest.bytes));
  }

  static IV get _iv => IV.fromUtf8(_ivSeed);

  static Encrypter get _encrypter =>
      Encrypter(AES(_key, mode: AESMode.cbc, padding: 'PKCS7'));

  static String encrypt(String plainJson) {
    final compressed = gzip.encode(utf8.encode(plainJson));
    final encrypted = _encrypter.encryptBytes(compressed, iv: _iv);
    return '$_magic${base64Encode(encrypted.bytes)}';
  }

  static String decrypt(String encryptedText) {
    final text = encryptedText.trim();
    if (!text.startsWith(_magic)) {
      throw FormatException('Not a valid encrypted cartela file.');
    }
    final payload = text.substring(_magic.length);
    final decoded = base64.decode(payload);
    final plainBytes = _encrypter.decryptBytes(Encrypted(decoded), iv: _iv);
    return utf8.decode(gzip.decode(plainBytes));
  }

  static bool looksEncrypted(String text) => text.trim().startsWith(_magic);
}
