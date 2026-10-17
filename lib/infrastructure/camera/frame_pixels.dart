import 'dart:typed_data';

Uint8List convertCameraFrame(List<Object> args) {
  final bytes = args[0] as Uint8List;
  final width = args[1] as int;
  final height = args[2] as int;
  final bytesPerRow = args[3] as int;
  final nv21 = args[4] as bool;
  if (nv21) {
    return nv21ToRgba(
      bytes: bytes,
      width: width,
      height: height,
      bytesPerRow: bytesPerRow,
    );
  }
  return bgraToRgba(
    bytes: bytes,
    width: width,
    height: height,
    bytesPerRow: bytesPerRow,
  );
}

Uint8List nv21ToRgba({
  required Uint8List bytes,
  required int width,
  required int height,
  required int bytesPerRow,
}) {
  final rgba = Uint8List(width * height * 4);
  final packedLength = width * height * 3 ~/ 2;
  final packed = bytes.length == packedLength;
  final yStride = packed ? width : bytesPerRow;
  final uvStride = packed ? width : bytesPerRow;
  final uvStart = packed ? width * height : yStride * height;

  for (var y = 0; y < height; y++) {
    final yRow = y * yStride;
    final uvRow = uvStart + (y >> 1) * uvStride;
    for (var x = 0; x < width; x++) {
      final yIndex = yRow + x;
      final yValue = yIndex < bytes.length ? bytes[yIndex] & 0xff : 0;
      final uvIndex = uvRow + (x & ~1);
      var u = 0;
      var v = 0;
      if (uvIndex + 1 < bytes.length) {
        v = (bytes[uvIndex] & 0xff) - 128;
        u = (bytes[uvIndex + 1] & 0xff) - 128;
      }
      var r = (yValue + 1.370705 * v).round();
      var g = (yValue - 0.337633 * u - 0.698001 * v).round();
      var b = (yValue + 1.732446 * u).round();
      if (r < 0) {
        r = 0;
      } else if (r > 255) {
        r = 255;
      }
      if (g < 0) {
        g = 0;
      } else if (g > 255) {
        g = 255;
      }
      if (b < 0) {
        b = 0;
      } else if (b > 255) {
        b = 255;
      }
      final dst = (y * width + x) * 4;
      rgba[dst] = r;
      rgba[dst + 1] = g;
      rgba[dst + 2] = b;
      rgba[dst + 3] = 255;
    }
  }
  return rgba;
}

Uint8List bgraToRgba({
  required Uint8List bytes,
  required int width,
  required int height,
  required int bytesPerRow,
}) {
  final rgba = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final src = y * bytesPerRow + x * 4;
      final dst = (y * width + x) * 4;
      if (src + 3 >= bytes.length) continue;
      rgba[dst] = bytes[src + 2];
      rgba[dst + 1] = bytes[src + 1];
      rgba[dst + 2] = bytes[src];
      rgba[dst + 3] = 255;
    }
  }
  return rgba;
}
