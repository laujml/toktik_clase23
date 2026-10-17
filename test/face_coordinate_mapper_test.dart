import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toktok/infrastructure/camera/face_coordinate_mapper.dart';

void main() {
  test('la cámara frontal en vertical espeja el eje X', () {
    const mapper = FaceCoordinateMapper(
      imageSize: Size(640, 480),
      rotationDegrees: 270,
      frontCamera: true,
      isIos: false,
      canvasSize: Size(480, 640),
    );

    expect(mapper.swapsAxes, isTrue);
    expect(mapper.mirrorsX, isTrue);
    expect(mapper.orientedSize, const Size(480, 640));
    expect(mapper.map(100, 40), const Offset(380, 40));
    expect(mapper.tiltRadians(90), closeTo(math.pi / 2, 0.001));
  });

  test('en iOS no se intercambian los ejes', () {
    const mapper = FaceCoordinateMapper(
      imageSize: Size(480, 640),
      rotationDegrees: 270,
      frontCamera: true,
      isIos: true,
      canvasSize: Size(480, 640),
    );

    expect(mapper.swapsAxes, isFalse);
    expect(mapper.map(10, 20).dx, 470);
    expect(mapper.map(10, 20).dy, 20);
  });

  test('el video guardado queda por debajo de 720p', () {
    final small = cappedVideoSize(const Size(480, 640));
    expect(small, const Size(480, 640));

    final capped = cappedVideoSize(const Size(720, 1280));
    expect(math.max(capped.width, capped.height), lessThanOrEqualTo(960));
    expect(capped.width, 540);
    expect(capped.height, 960);
  });

  test('la rotación de un teléfono en vertical usa el sensor', () {
    expect(
      imageRotationDegrees(
        sensorOrientation: 270,
        deviceOrientation: DeviceOrientation.portraitUp,
        frontCamera: true,
        isIos: false,
      ),
      270,
    );
    expect(
      imageRotationDegrees(
        sensorOrientation: 90,
        deviceOrientation: DeviceOrientation.portraitUp,
        frontCamera: false,
        isIos: false,
      ),
      90,
    );
    expect(
      imageRotationDegrees(
        sensorOrientation: 270,
        deviceOrientation: DeviceOrientation.landscapeLeft,
        frontCamera: true,
        isIos: true,
      ),
      270,
    );
  });
}
