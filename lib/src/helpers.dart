import 'dart:typed_data';
import 'encoding.dart';
import 'constants.dart';

abstract class Helpers {
  static int signedToUnsigned(int signed) {
    return signed.toUnsigned(32);
  }

  static int xor(int a, int b) {
    return signedToUnsigned(a ^ b);
  }

  static int sumMod32(int a, int b) {
    return signedToUnsigned((a + b) & 0xffffffff);
  }

  static int packFourBytes(int byte1, int byte2, int byte3, int byte4) {
    return signedToUnsigned(byte1 << 24 | byte2 << 16 | byte3 << 8 | byte4);
  }

  static List<int> unpackFourBytes(int pack) {
    return [
      (pack >> 24) & 0xFF,
      (pack >> 16) & 0xFF,
      (pack >> 8) & 0xFF,
      pack & 0xFF
    ];
  }

  static bool isString(var val) {
    return val is String;
  }

  static bool isBuffer(var val) {
    return val is List<int> || val is Uint8List;
  }

  static bool isStringOrBuffer(var val) {
    return isString(val) || isBuffer(val);
  }

  static bool includes(Map<dynamic, dynamic> obj, var val) {
    bool result = false;
    obj.forEach((key, value) {
      if (value == val) {
        result = true;
      }
    });
    return result;
  }

  static Uint8List toUint8Array(var val) {
    if (isString(val)) {
      return Encoding.stringToU8(val);
    } else if (isBuffer(val)) {
      return Uint8List.fromList(val);
    }
    throw Exception('Unsupported type');
  }

  static Uint8List expandKey(Uint8List key) {
    if (key.length >= 72) {
      // 576 bits -> 72 bytes
      return key;
    }
    final longKey = <int>[];
    while (longKey.length < 72) {
      for (var i = 0; i < key.length; i++) {
        longKey.add(key[i]);
      }
    }
    return Uint8List.fromList(longKey);
  }

  static Uint8List pad(Uint8List bytes, Padding padding) {
    final count = 8 - bytes.length % 8;
    if (count == 8 && bytes.isNotEmpty && padding != Padding.pkcs5) {
      return bytes;
    }
    final writer = Uint8List(bytes.length + count);
    final newBytes = <int>[];
    var remaining = count;
    var padChar = 0;

    switch (padding) {
      case Padding.pkcs5:
        {
          padChar = count;
          break;
        }
      case Padding.oneAndZeros:
        {
          newBytes.add(0x80);
          remaining--;
          break;
        }
      case Padding.spaces:
        {
          padChar = 0x20;
          break;
        }
      case Padding.lastByte:
        break;
      case Padding.none:
        break;
    }

    while (remaining > 0) {
      if (padding == Padding.lastByte && remaining == 1) {
        newBytes.add(count);
        break;
      }
      newBytes.add(padChar);
      remaining--;
    }

    writer.setRange(0, bytes.length, bytes);
    writer.setRange(bytes.length, writer.length, newBytes);
    return writer;
  }

  static Uint8List unpad(Uint8List bytes, Padding padding) {
    int cutLength = 0;
    switch (padding) {
      case Padding.lastByte:
        break;
      case Padding.pkcs5:
        {
          int lastChar = bytes[bytes.length - 1];
          if (lastChar <= 8) {
            cutLength = lastChar;
          }
        }
        break;
      case Padding.oneAndZeros:
        {
          int i = 1;
          while (i <= 8) {
            int char = bytes[bytes.length - i];
            if (char == 0x80) {
              cutLength = i;
              break;
            }
            if (char != 0) {
              break;
            }
            i++;
          }
        }
        break;
      case Padding.none:
        break;
      case Padding.spaces:
        {
          int padChar = (padding == Padding.spaces) ? 0x20 : 0;
          int i = 1;
          while (i <= 8) {
            int char = bytes[bytes.length - i];
            if (char != padChar) {
              cutLength = i - 1;
              break;
            }
            i++;
          }
        }
        break;
    }
    return bytes.sublist(0, bytes.length - cutLength);
  }
}
