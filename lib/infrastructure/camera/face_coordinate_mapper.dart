import 'dart:math' as math;

import 'package:flutter/services.dart';

/// Maps ML Kit points onto the preview and onto the recorded frame.
///
/// The formulas follow the camera example of google_ml_kit: on Android a
/// 90/270 rotation swaps axes, and 270 (the usual front camera in portrait)
/// mirrors X so the overlay matches the selfie preview.
class FaceCoordinateMapper {
  const FaceCoordinateMapper({
    required this.imageSize,
    required this.rotationDegrees,
    required this.frontCamera,
    required this.isIos,
    required this.canvasSize,
  });

  final Size imageSize;
  final int rotationDegrees;
  final bool frontCamera;
  final bool isIos;
  final Size canvasSize;

  bool get swapsAxes =>
      !isIos && (rotationDegrees == 90 || rotationDegrees == 270);

  bool get mirrorsX {
    if (rotationDegrees == 270) return true;
    if (rotationDegrees == 0 || rotationDegrees == 180) return frontCamera;
    return false;
  }

  Size get orientedSize {
    if (swapsAxes) return Size(imageSize.height, imageSize.width);
    return imageSize;
  }

  Offset map(double x, double y) {
    return Offset(_x(x), _y(y));
  }

  Rect mapRect(Rect rect) {
    final a = map(rect.left, rect.top);
    final b = map(rect.right, rect.bottom);
    return Rect.fromLTRB(
      math.min(a.dx, b.dx),
      math.min(a.dy, b.dy),
      math.max(a.dx, b.dx),
      math.max(a.dy, b.dy),
    );
  }

  /// Tilt in radians for the mirrored preview. Positive canvas rotation is
  /// clockwise, and ML Kit's Euler Z is counter-clockwise.
  double tiltRadians(double eulerZ) {
    final sign = mirrorsX ? 1.0 : -1.0;
    return sign * eulerZ * math.pi / 180;
  }

  double _x(double x) {
    switch (rotationDegrees) {
      case 90:
        return x * canvasSize.width / (isIos ? imageSize.width : imageSize.height);
      case 270:
        return canvasSize.width -
            x * canvasSize.width / (isIos ? imageSize.width : imageSize.height);
      case 0:
      case 180:
        final scaled = x * canvasSize.width / imageSize.width;
        return frontCamera ? canvasSize.width - scaled : scaled;
      default:
        return x;
    }
  }

  double _y(double y) {
    switch (rotationDegrees) {
      case 90:
      case 270:
        return y *
            canvasSize.height /
            (isIos ? imageSize.height : imageSize.width);
      case 0:
      case 180:
        return y * canvasSize.height / imageSize.height;
      default:
        return y;
    }
  }
}

int? imageRotationDegrees({
  required int sensorOrientation,
  required DeviceOrientation deviceOrientation,
  required bool frontCamera,
  required bool isIos,
}) {
  if (isIos) return sensorOrientation;
  const turns = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
  final compensation = turns[deviceOrientation];
  if (compensation == null) return null;
  if (frontCamera) return (sensorOrientation + compensation) % 360;
  return (sensorOrientation - compensation + 360) % 360;
}

int alignEven(double value) {
  final rounded = value.round();
  if (rounded <= 2) return 2;
  return rounded.isEven ? rounded : rounded - 1;
}

/// Saved frames stay under 720p. The long side is at most 960 px.
Size cappedVideoSize(Size oriented) {
  const maxLongSide = 960.0;
  final longSide = math.max(oriented.width, oriented.height);
  final scale = longSide > maxLongSide ? maxLongSide / longSide : 1.0;
  return Size(
    alignEven(oriented.width * scale).toDouble(),
    alignEven(oriented.height * scale).toDouble(),
  );
}
