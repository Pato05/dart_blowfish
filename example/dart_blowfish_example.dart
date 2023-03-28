import 'dart:typed_data';

import 'package:dart_blowfish/src/constants.dart';
import 'package:dart_blowfish/src/encoding.dart';
import 'package:dart_blowfish/src/helpers.dart';

void main() {
  // test signedToUnsigned
  final int signed = -1;
  final int unsigned = Helpers.signedToUnsigned(signed);
  print('signed: $signed, unsigned: $unsigned');

  // test xor
  final int a = 1;
  final int b = 2;
  final int c = Helpers.xor(a, b);
  print('a: $a, b: $b, c: $c');

  // test sumMod32
  final int d = 1;
  final int e = 2;
  final int f = Helpers.sumMod32(d, e);
  print('d: $d, e: $e, f: $f');

  // test packFourBytes
  final int byte1 = 1;
  final int byte2 = 2;
  final int byte3 = 3;
  final int byte4 = 4;
  final int pack = Helpers.packFourBytes(byte1, byte2, byte3, byte4);
  print(
      'byte1: $byte1, byte2: $byte2, byte3: $byte3, byte4: $byte4, pack: $pack');

  // test unpackFourBytes
  final List<int> unpack = Helpers.unpackFourBytes(pack);
  print('pack2: $pack, unpack: $unpack');

  // test isString
  final String str = 'test';
  final bool isString = Helpers.isString(str);
  print('str: $str, isString: $isString');

  // test isBuffer
  final List<int> buffer = [1, 2, 3, 4];
  final bool isBuffer = Helpers.isBuffer(buffer);
  print('buffer: $buffer, isBuffer: $isBuffer');

  // test includes
  final Map<dynamic, dynamic> obj = {'a': 1, 'b': 2, 'c': 3};
  final bool includes = Helpers.includes(obj, 2);
  print('obj: $obj, includes: $includes');

  // test toUint8Array
  final Uint8List u8 = Helpers.toUint8Array(str);
  print('str: $str, u8: $u8');

  // test expandKey
  final aa = 'test';
  final bb = Encoding.stringToU8(aa);
  final cc = Helpers.expandKey(bb);
  print('aa: $aa, bb: $bb, cc: $cc, length: ${cc.length}');

  print('-------------------------');

  // test pad pkcs5
  final dd = 'test';
  final ee = Encoding.stringToU8(dd);
  final ff = Helpers.pad(ee, Padding.pkcs5);
  print('pad pkcs5 dd: $dd, ee: $ee, ff: $ff, length: ${ff.length}');

  // test pad oneAndZeros
  final gg = 'test';
  final hh = Encoding.stringToU8(gg);
  final ii = Helpers.pad(hh, Padding.oneAndZeros);
  print('pad oneAndZeros gg: $gg, hh: $hh, ii: $ii, length: ${ii.length}');

  // test pad lastByte
  final jj = 'test';
  final kk = Encoding.stringToU8(jj);
  final ll = Helpers.pad(kk, Padding.lastByte);
  print('pad lastByte jj: $jj, kk: $kk, ll: $ll, length: ${ll.length}');

  // test pad nulls
  final mm = 'test';
  final nn = Encoding.stringToU8(mm);
  final oo = Helpers.pad(nn, Padding.none);
  print('pad none mm: $mm, nn: $nn, oo: $oo, length: ${oo.length}');

  // test pad space
  final pp = 'test';
  final qq = Encoding.stringToU8(pp);
  final rr = Helpers.pad(qq, Padding.spaces);
  print('pad spaces pp: $pp, qq: $qq, rr: $rr, length: ${rr.length}');

  // test unpad
  final ss = 'test';
  final tt = Encoding.stringToU8(ss);
  final uu = Helpers.pad(tt, Padding.spaces);
  final vv = Helpers.unpad(uu, Padding.spaces);
  print('unpad ss: $ss, tt: $tt, uu: $uu, vv: $vv, length: ${vv.length}');
}
