import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

/// Helper class for encryption, decryption, and checksum generation
class EncryptionHelper {
  /// Generate SHA-256 checksum for data integrity verification
  static String generateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify checksum matches data
  static bool verifyChecksum(String data, String expectedChecksum) {
    final actualChecksum = generateChecksum(data);
    return actualChecksum == expectedChecksum;
  }

  /// Encrypt data using AES-256 with password-based key derivation
  static String encryptData(String data, String password) {
    try {
      // Derive encryption key from password using PBKDF2
      final key = _deriveKeyFromPassword(password);

      // Generate random IV (Initialization Vector)
      final iv = encrypt.IV.fromSecureRandom(16);

      // Create encrypter
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      // Encrypt data
      final encrypted = encrypter.encrypt(data, iv: iv);

      // Combine IV and encrypted data for storage
      // Format: base64(IV) + ':' + base64(encrypted)
      final combined = '${iv.base64}:${encrypted.base64}';

      return combined;
    } catch (e) {
      debugPrint('EncryptionHelper: Encryption failed: $e');
      throw Exception('Failed to encrypt data');
    }
  }

  /// Decrypt data using AES-256 with password
  static String decryptData(String encryptedData, String password) {
    try {
      // Split IV and encrypted data
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid encrypted data format');
      }

      final ivBase64 = parts[0];
      final encryptedBase64 = parts[1];

      // Derive same encryption key from password
      final key = _deriveKeyFromPassword(password);

      // Recreate IV
      final iv = encrypt.IV.fromBase64(ivBase64);

      // Create encrypter
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      // Decrypt data
      final decrypted = encrypter.decrypt64(encryptedBase64, iv: iv);

      return decrypted;
    } catch (e) {
      debugPrint('EncryptionHelper: Decryption failed: $e');
      throw Exception('Failed to decrypt data - wrong password or corrupted file');
    }
  }

  /// Derive encryption key from password using PBKDF2
  static encrypt.Key _deriveKeyFromPassword(String password) {
    // Use PBKDF2 with fixed salt for deterministic key generation
    // In production, consider storing salt with encrypted data for better security
    final salt = 'workout_wizard_salt_v1'; // Fixed salt for simplicity
    final iterations = 10000; // PBKDF2 iterations

    // Generate key bytes
    final keyBytes = _pbkdf2(
      password,
      salt,
      iterations,
      32, // 32 bytes = 256 bits for AES-256
    );

    return encrypt.Key(Uint8List.fromList(keyBytes));
  }

  /// PBKDF2 key derivation implementation
  static List<int> _pbkdf2(
    String password,
    String salt,
    int iterations,
    int keyLength,
  ) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = utf8.encode(salt);

    var derivedKey = <int>[];
    var block = Uint8List(0);

    for (var i = 1; derivedKey.length < keyLength; i++) {
      // Create block number as 4-byte big-endian integer
      final blockNumber = Uint8List(4)
        ..buffer.asByteData().setUint32(0, i, Endian.big);

      // Initial U = HMAC(password, salt + blockNumber)
      var u = Hmac(sha256, passwordBytes)
          .convert([...saltBytes, ...blockNumber])
          .bytes;

      block = Uint8List.fromList(u);

      // Iterate: U = HMAC(password, U)
      for (var j = 1; j < iterations; j++) {
        u = Hmac(sha256, passwordBytes).convert(u).bytes;

        // XOR with previous block
        for (var k = 0; k < block.length; k++) {
          block[k] ^= u[k];
        }
      }

      derivedKey.addAll(block);
    }

    // Return exactly keyLength bytes
    return derivedKey.sublist(0, keyLength);
  }

  /// Generate random backup code (for future use with cloud sync)
  static String generateBackupCode() {
    final random = encrypt.IV.fromSecureRandom(16);
    return random.base64
        .replaceAll('+', '')
        .replaceAll('/', '')
        .replaceAll('=', '')
        .substring(0, 12)
        .toUpperCase();
  }

  /// Validate password strength (minimum requirements)
  static bool isPasswordStrong(String password) {
    if (password.length < 6) return false;
    return true;
  }

  /// Get password strength feedback
  static String getPasswordStrengthFeedback(String password) {
    if (password.isEmpty) {
      return 'Enter a password';
    } else if (password.length < 6) {
      return 'Password too short (minimum 6 characters)';
    } else if (password.length < 8) {
      return 'Weak password - consider adding more characters';
    } else if (password.length < 12) {
      return 'Good password';
    } else {
      return 'Strong password';
    }
  }
}
