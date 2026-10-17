import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:toktok/domain/entities/camera_filter.dart';
import 'package:toktok/domain/entities/tracked_face.dart';
import 'package:toktok/infrastructure/camera/face_coordinate_mapper.dart';
import 'package:toktok/presentation/providers/face_filter_provider.dart';
import 'package:toktok/presentation/widgets/filters/face_sticker_painter.dart';
import 'package:toktok/presentation/widgets/filters/heart_glasses_asset.dart';

void main() {
  test('el filtro elegido avisa a quien escucha', () {
    final provider = FaceFilterProvider();
    var notices = 0;
    provider.addListener(() => notices += 1);

    provider.select(CameraFilter.kawaii);
    expect(notices, 0);

    provider.select(CameraFilter.glasses);
    expect(provider.selected, CameraFilter.glasses);
    expect(notices, 1);
    provider.dispose();
  });

  test('los landmarks de ML Kit pasan al rostro dibujado', () {
    final face = TrackedFace.fromMlKit(
      Face(
        boundingBox: const Rect.fromLTWH(10, 20, 80, 100),
        headEulerAngleZ: 12,
        landmarks: {
          FaceLandmarkType.noseBase: FaceLandmark(
            type: FaceLandmarkType.noseBase,
            position: const Point<int>(50, 70),
          ),
          FaceLandmarkType.leftCheek: FaceLandmark(
            type: FaceLandmarkType.leftCheek,
            position: const Point<int>(30, 80),
          ),
          FaceLandmarkType.rightCheek: FaceLandmark(
            type: FaceLandmarkType.rightCheek,
            position: const Point<int>(70, 82),
          ),
          FaceLandmarkType.leftEye: FaceLandmark(
            type: FaceLandmarkType.leftEye,
            position: const Point<int>(35, 50),
          ),
          FaceLandmarkType.rightEye: FaceLandmark(
            type: FaceLandmarkType.rightEye,
            position: const Point<int>(65, 48),
          ),
        },
        contours: const {},
      ),
    );

    expect(face.nose, const Offset(50, 70));
    expect(face.leftCheek, const Offset(30, 80));
    expect(face.rightEye, const Offset(65, 48));
    expect(face.eulerZ, 12);
  });

  test('el cuadro grabado pone el pixel del rostro donde cae el landmark', () async {
    const rawWidth = 8;
    const rawHeight = 4;
    final source = await _colorBlocks(rawWidth, rawHeight);
    final mapper = FaceCoordinateMapper(
      imageSize: Size(rawWidth.toDouble(), rawHeight.toDouble()),
      rotationDegrees: 270,
      frontCamera: true,
      isIos: false,
      canvasSize: Size(rawHeight.toDouble(), rawWidth.toDouble()),
    );

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    paintOrientedCamera(canvas: canvas, image: source, mapper: mapper);
    final picture = recorder.endRecording();
    final rendered = await picture.toImage(rawHeight, rawWidth);
    final bytes = await rendered.toByteData(format: ImageByteFormat.rawRgba);
    source.dispose();
    rendered.dispose();
    picture.dispose();

    expect(bytes, isNotNull);
    final red = _pixel(bytes!, rawHeight, 2, 6);
    expect(red.$1, greaterThan(200));
    expect(red.$2, lessThan(40));
    expect(red.$3, lessThan(40));

    final green = _pixel(bytes, rawHeight, 2, 1);
    expect(green.$2, greaterThan(200));
    expect(green.$1, lessThan(40));
  });

  test('Kawaii y Lentes se dibujan en cada cara sin tirar error', () {
    final faces = [
      TrackedFace(
        boundingBox: const Rect.fromLTWH(20, 30, 120, 150),
        nose: const Offset(80, 110),
        leftCheek: const Offset(50, 120),
        rightCheek: const Offset(110, 122),
        leftEye: const Offset(55, 80),
        rightEye: const Offset(105, 78),
        eulerZ: -8,
      ),
      const TrackedFace(
        boundingBox: Rect.fromLTWH(180, 40, 90, 110),
        nose: Offset(220, 100),
        leftEye: Offset(200, 70),
        rightEye: Offset(245, 74),
      ),
    ];
    const mapper = FaceCoordinateMapper(
      imageSize: Size(320, 240),
      rotationDegrees: 270,
      frontCamera: true,
      isIos: false,
      canvasSize: Size(240, 320),
    );
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    paintFaceFilters(
      canvas: canvas,
      mapper: mapper,
      filter: CameraFilter.kawaii,
      faces: faces,
      phase: 0.35,
    );
    paintFaceFilters(
      canvas: canvas,
      mapper: mapper,
      filter: CameraFilter.glasses,
      faces: faces,
      phase: 0,
    );
    final picture = recorder.endRecording();
    picture.dispose();
  });

  test('los lentes quedan centrados entre los ojos', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await HeartGlassesAsset.ensureLoaded();
    expect(HeartGlassesAsset.size.width, greaterThan(100));

    const canvasSize = Size(200, 200);
    const mapper = FaceCoordinateMapper(
      imageSize: canvasSize,
      rotationDegrees: 0,
      frontCamera: false,
      isIos: true,
      canvasSize: canvasSize,
    );
    const face = TrackedFace(
      boundingBox: Rect.fromLTWH(20, 20, 160, 180),
      leftEye: Offset(60, 100),
      rightEye: Offset(140, 100),
    );
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    paintFaceFilters(
      canvas: canvas,
      mapper: mapper,
      filter: CameraFilter.glasses,
      faces: const [face],
      phase: 0,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(200, 200);
    final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
    image.dispose();
    picture.dispose();
    expect(bytes, isNotNull);

    final asset = HeartGlassesAsset.size;
    final scale = 160 * 0.95 / asset.width;
    final lens = Offset(
      100 + (288 / 960 * asset.width - asset.width / 2) * scale,
      100 + (260 / 520 * asset.height - asset.height / 2) * scale,
    );
    final pink = _pixel(bytes!, 200, lens.dx.round(), lens.dy.round());
    expect(pink.$4, inInclusiveRange(70, 180));
    expect(pink.$1 / pink.$4, closeTo(0xF4 / 255, 0.08));
    expect(pink.$2 / pink.$4, closeTo(0x8F / 255, 0.08));

    final corner = _pixel(bytes, 200, 2, 2);
    expect(corner.$4, lessThan(10));
  });
}

Future<Image> _colorBlocks(int width, int height) {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width / 2, height.toDouble()),
    Paint()..color = const Color(0xFFFF0000),
  );
  canvas.drawRect(
    Rect.fromLTWH(width / 2, 0, width / 2, height.toDouble()),
    Paint()..color = const Color(0xFF00FF00),
  );
  final picture = recorder.endRecording();
  return picture.toImage(width, height);
}

(int, int, int, int) _pixel(ByteData data, int width, int x, int y) {
  final offset = (y * width + x) * 4;
  return (
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  );
}
