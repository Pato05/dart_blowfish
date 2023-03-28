import 'dart:typed_data';

import 'package:dart_blowfish/src/constants.dart';
import 'package:dart_blowfish/src/encoding.dart';
import 'package:dart_blowfish/src/helpers.dart';

class Blowfish {
  final Mode mode;
  final Padding padding;
  Uint8List? iv;

  late List<int> p;
  late List<List<int>> s;

  Blowfish({required String key, required this.mode, required this.padding}) {
    p = List<int>.from(Blocks.P);
    s = [List<int>.from(Blocks.S0), List<int>.from(Blocks.S1), List<int>.from(Blocks.S2), List<int>.from(Blocks.S3)];

    Uint8List nKey = Helpers.expandKey(Encoding.stringToU8(key));

    for (int i = 0, j = 0; i < 18; i++, j += 4) {
      final n = Helpers.packFourBytes(nKey[j], nKey[j + 1], nKey[j + 2], nKey[j + 3]);
      p[i] = Helpers.xor(p[i], n);
    }

    int l = 0;
    int r = 0;
    for (int i = 0; i < 18; i += 2) {
      var result = _encryptBlock(l, r);
      l = result[0];
      r = result[1];
      p[i] = l;
      p[i + 1] = r;
    }
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 256; j += 2) {
        var result = _encryptBlock(l, r);
        l = result[0];
        r = result[1];
        s[i][j] = l;
        s[i][j + 1] = r;
      }
    }
  }

  setIv(Uint8List value) {
    if (value.length != 8) {
      throw Exception('IV should be 8 byte length');
    }
    iv = value;
  }

  int _f(int x) {
    int a = (x >> 24) & 0xFF;
    int b = (x >> 16) & 0xFF;
    int c = (x >> 8) & 0xFF;
    int d = x & 0xFF;

    int res = Helpers.sumMod32(s[0][a], s[1][b]);
    res = Helpers.xor(res, s[2][c]);
    return Helpers.sumMod32(res, s[3][d]);
  }

  List<int> _encryptBlock(int l, int r) {
    for (int i = 0; i < 16; i++) {
      l = Helpers.xor(l, p[i]);
      r = Helpers.xor(r, _f(l));
      List<int> temp = [r, l];
      l = temp[0];
      r = temp[1];
    }
    List<int> temp = [r, l];
    l = temp[0];
    r = temp[1];
    r = Helpers.xor(r, p[16]);
    l = Helpers.xor(l, p[17]);
    return [l, r];
  }

  Uint8List encode(Uint8List data) {
    if (mode == Mode.cbc && iv == null) {
      throw Exception('IV is not set');
    }
    data = Helpers.pad(data, padding);
    if (mode == Mode.cbc) {
      return _encodeCBC(data);
    } else if (mode == Mode.ecb) {
      return _encodeECB(data);
    }
    return Uint8List(0);
  }

  dynamic decode(data, {Type returnType = Type.string}) {
    if (!Helpers.isStringOrBuffer(data)) {
      throw Exception('Decode data should be a string or an ArrayBuffer / Buffer');
    }
    if (mode != Mode.ecb && iv == null) {
      throw Exception('IV is not set');
    }
    data = Helpers.toUint8Array(data);

    if (data.length % 8 != 0) {
      throw Exception('Decoded data should be multiple of 8 bytes');
    }

    switch (mode) {
      case Mode.ecb:
        {
          data = _decodeECB(data);
          break;
        }
      case Mode.cbc:
        {
          data = _decodeCBC(data);
          break;
        }
    }

    data = Helpers.unpad(data, padding);

    switch (returnType) {
      case Type.uInt8Array:
        {
          return data;
        }
      case Type.string:
        {
          return Encoding.u8ToString(data);
        }
      default:
        {
          throw Exception('Unsupported return type');
        }
    }
  }

  Uint8List _encodeCBC(Uint8List bytes) {
    Uint8List encoded = Uint8List(bytes.length);
    int prevL = Helpers.packFourBytes(iv![0], iv![1], iv![2], iv![3]);
    int prevR = Helpers.packFourBytes(iv![4], iv![5], iv![6], iv![7]);
    for (int i = 0; i < bytes.length; i += 8) {
      int l = Helpers.packFourBytes(bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]);
      int r = Helpers.packFourBytes(bytes[i + 4], bytes[i + 5], bytes[i + 6], bytes[i + 7]);
      List<int> temp = [Helpers.xor(prevL, l), Helpers.xor(prevR, r)];
      l = temp[0];
      r = temp[1];
      List<int> encrypted = _encryptBlock(l, r);
      prevL = encrypted[0];
      prevR = encrypted[1];
      encoded.setRange(i, i + 4, Helpers.unpackFourBytes(encrypted[0]));
      encoded.setRange(i + 4, i + 8, Helpers.unpackFourBytes(encrypted[1]));
    }
    return encoded;
  }

  Uint8List _encodeECB(Uint8List bytes) {
    Uint8List encoded = Uint8List(bytes.length);
    for (int i = 0; i < bytes.length; i += 8) {
      int l = Helpers.packFourBytes(bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]);
      int r = Helpers.packFourBytes(bytes[i + 4], bytes[i + 5], bytes[i + 6], bytes[i + 7]);
      List<int> result = _encryptBlock(l, r);
      l = result[0];
      r = result[1];
      encoded.setRange(i, i + 4, Helpers.unpackFourBytes(l));
      encoded.setRange(i + 4, i + 8, Helpers.unpackFourBytes(r));
    }
    return encoded;
  }

  List<int> _decryptBlock(int l, int r) {
    for (int i = 17; i > 1; i--) {
      l = Helpers.xor(l, p[i]);
      r = Helpers.xor(r, _f(l));
      List<int> temp = [r, l];
      l = temp[0];
      r = temp[1];
    }
    List<int> temp = [r, l];
    l = temp[0];
    r = temp[1];
    r = Helpers.xor(r, p[1]);
    l = Helpers.xor(l, p[0]);
    return [l, r];
  }

  Uint8List _decodeECB(Uint8List bytes) {
    final decoded = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i += 8) {
      final l = Helpers.packFourBytes(bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]);
      final r = Helpers.packFourBytes(bytes[i + 4], bytes[i + 5], bytes[i + 6], bytes[i + 7]);
      final decrypted = _decryptBlock(l, r);
      decoded.setRange(i, i + 4, Helpers.unpackFourBytes(decrypted[0]));
      decoded.setRange(i + 4, i + 8, Helpers.unpackFourBytes(decrypted[1]));
    }
    return decoded;
  }

  Uint8List _decodeCBC(Uint8List bytes) {
    final decoded = Uint8List(bytes.length);
    var prevL = Helpers.packFourBytes(iv![0], iv![1], iv![2], iv![3]);
    var prevR = Helpers.packFourBytes(iv![4], iv![5], iv![6], iv![7]);
    int prevLTmp, prevRTmp;
    for (var i = 0; i < bytes.length; i += 8) {
      final l = Helpers.packFourBytes(bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]);
      final r = Helpers.packFourBytes(bytes[i + 4], bytes[i + 5], bytes[i + 6], bytes[i + 7]);
      prevLTmp = l;
      prevRTmp = r;
      final decrypted = _decryptBlock(l, r);
      final xoredL = Helpers.xor(prevL, decrypted[0]);
      final xoredR = Helpers.xor(prevR, decrypted[1]);
      prevL = prevLTmp;
      prevR = prevRTmp;
      decoded.setRange(i, i + 4, Helpers.unpackFourBytes(xoredL));
      decoded.setRange(i + 4, i + 8, Helpers.unpackFourBytes(xoredR));
    }
    return decoded;
  }
}
