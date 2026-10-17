import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:toktok/infrastructure/camera/frame_pixels.dart';

void main() {
  test('NV21 gris queda gris en RGBA', () {
    final nv21 = Uint8List(6)..fillRange(0, 6, 128);
    final rgba = nv21ToRgba(bytes: nv21, width: 2, height: 2, bytesPerRow: 2);

    expect(rgba.length, 16);
    expect(rgba[0], inInclusiveRange(120, 136));
    expect(rgba[1], inInclusiveRange(120, 136));
    expect(rgba[2], inInclusiveRange(120, 136));
    expect(rgba[3], 255);
  });

  test('BGRA pasa a RGBA', () {
    final bgra = Uint8List.fromList([
      0, 0, 255, 255, // blue, green, red, alpha -> red
    ]);
    final rgba = bgraToRgba(bytes: bgra, width: 1, height: 1, bytesPerRow: 4);
    expect(rgba, Uint8List.fromList([255, 0, 0, 255]));
  });
}
