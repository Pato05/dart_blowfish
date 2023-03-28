import 'dart:typed_data';

import 'package:dart_blowfish/src/constants.dart';
import 'package:dart_blowfish/src/dart_blowfish_base.dart';

void main() {
  final cipher = Blowfish(key: 'test', mode: Mode.cbc, padding: Padding.none);
  cipher.setIv(Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]));
  final chunk = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]);
  final decrypted = cipher.decode(chunk, returnType: Type.uInt8Array);
  print(decrypted);
}
