import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/camera_filter.dart';
import 'package:toktok/domain/entities/tracked_face.dart';
import 'package:toktok/infrastructure/camera/face_coordinate_mapper.dart';
import 'package:toktok/presentation/widgets/filters/heart_glasses_asset.dart';

const _blushFill = Color(0x99F7B3C8);
const _blushLine = Color(0xFFFFFFFF);
const _bandageFill = Color(0xFFF8C9D8);
const _bandageStroke = Color(0xFFE48AAA);
const _ink = Color(0xFFC45B7A);
const _heartFill = Color(0xFFF48FB1);
const _frame = Color(0xFFAD1457);

void paintOrientedCamera({
  required Canvas canvas,
  required ui.Image image,
  required FaceCoordinateMapper mapper,
}) {
  final canvasSize = mapper.canvasSize;
  canvas.drawRect(
    Offset.zero & canvasSize,
    Paint()..color = const Color(0xFF000000),
  );
  canvas.save();
  if (mapper.mirrorsX) {
    canvas.translate(canvasSize.width, 0);
    canvas.scale(-1, 1);
  }

  final source = Rect.fromLTWH(
    0,
    0,
    image.width.toDouble(),
    image.height.toDouble(),
  );
  final paint = Paint()..filterQuality = FilterQuality.low;
  if (mapper.swapsAxes && mapper.rotationDegrees == 90) {
    canvas.translate(canvasSize.width, 0);
    canvas.rotate(math.pi / 2);
    canvas.drawImageRect(
      image,
      source,
      Rect.fromLTWH(0, 0, canvasSize.height, canvasSize.width),
      paint,
    );
  } else if (mapper.swapsAxes && mapper.rotationDegrees == 270) {
    canvas.translate(0, canvasSize.height);
    canvas.rotate(-math.pi / 2);
    canvas.drawImageRect(
      image,
      source,
      Rect.fromLTWH(0, 0, canvasSize.height, canvasSize.width),
      paint,
    );
  } else {
    canvas.drawImageRect(
      image,
      source,
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      paint,
    );
  }
  canvas.restore();
}

void paintFaceFilters({
  required Canvas canvas,
  required FaceCoordinateMapper mapper,
  required CameraFilter filter,
  required List<TrackedFace> faces,
  required double phase,
}) {
  if (filter == CameraFilter.none) return;
  for (final face in faces) {
    if (filter == CameraFilter.kawaii) {
      _paintKawaii(canvas, mapper, face, phase);
    } else {
      _paintGlasses(canvas, mapper, face);
    }
  }
}

void _paintKawaii(
  Canvas canvas,
  FaceCoordinateMapper mapper,
  TrackedFace face,
  double phase,
) {
  final box = mapper.mapRect(face.boundingBox);
  if (box.width < 8 || box.height < 8) return;
  final center = box.center;
  final faceWidth = box.width;
  final angle = mapper.tiltRadians(face.eulerZ);

  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);

  final nose = _placed(
        mapper,
        face.nose,
        center,
        angle,
        Offset(0, faceWidth * 0.06),
      ) +
      Offset(0, faceWidth * 0.04);
  _bandage(canvas, nose, faceWidth);
  final leftCheek = _cheek(
    mapper: mapper,
    center: center,
    angle: angle,
    faceWidth: faceWidth,
    nose: nose,
    cheek: face.leftCheek,
    eye: face.leftEye,
    mouth: face.leftMouth,
    fallback: Offset(-faceWidth * 0.32, faceWidth * 0.14),
  );
  final rightCheek = _cheek(
    mapper: mapper,
    center: center,
    angle: angle,
    faceWidth: faceWidth,
    nose: nose,
    cheek: face.rightCheek,
    eye: face.rightEye,
    mouth: face.rightMouth,
    fallback: Offset(faceWidth * 0.32, faceWidth * 0.14),
  );
  _blush(canvas, leftCheek, faceWidth);
  _blush(canvas, rightCheek, faceWidth);
  _hearts(canvas, faceWidth, phase);
  canvas.restore();
}

void _paintGlasses(
  Canvas canvas,
  FaceCoordinateMapper mapper,
  TrackedFace face,
) {
  final glasses = HeartGlassesAsset.picture;
  final assetSize = HeartGlassesAsset.size;
  if (glasses == null || assetSize.width < 1 || assetSize.height < 1) return;

  final box = mapper.mapRect(face.boundingBox);
  if (box.width < 8) return;
  final left = face.leftEye == null
      ? box.center + Offset(-box.width * 0.22, -box.height * 0.08)
      : mapper.map(face.leftEye!.dx, face.leftEye!.dy);
  final right = face.rightEye == null
      ? box.center + Offset(box.width * 0.22, -box.height * 0.08)
      : mapper.map(face.rightEye!.dx, face.rightEye!.dy);
  final mid = Offset((left.dx + right.dx) / 2, (left.dy + right.dy) / 2);
  if ((right - left).distance < 4) return;

  final width = box.width * 0.95;
  final scale = width / assetSize.width;
  canvas.save();
  canvas.translate(mid.dx, mid.dy);
  canvas.rotate(mapper.tiltRadians(face.eulerZ));
  canvas.scale(scale);
  canvas.translate(-assetSize.width / 2, -assetSize.height / 2);
  canvas.drawPicture(glasses);
  canvas.restore();
}

Offset _cheek({
  required FaceCoordinateMapper mapper,
  required Offset center,
  required double angle,
  required double faceWidth,
  required Offset nose,
  required Offset? cheek,
  required Offset? eye,
  required Offset? mouth,
  required Offset fallback,
}) {
  final source = cheek ??
      (eye != null && mouth != null
          ? Offset((eye.dx + mouth.dx) / 2, (eye.dy + mouth.dy) / 2)
          : null);
  var placed = _placed(mapper, source, center, angle, fallback);
  final away = placed - nose;
  final distance = away.distance;
  final minDistance = faceWidth * 0.26;
  if (distance < 1) return nose + fallback;
  if (distance < minDistance) {
    placed = nose + away * (minDistance / distance);
  }
  return placed;
}

Offset? _local(FaceCoordinateMapper mapper, Offset? point, Offset center) {
  if (point == null) return null;
  final mapped = mapper.map(point.dx, point.dy);
  return mapped - center;
}

Offset _placed(
  FaceCoordinateMapper mapper,
  Offset? point,
  Offset center,
  double angle,
  Offset fallback,
) {
  final local = _local(mapper, point, center);
  if (local == null) return fallback;
  return _undoRotation(local, angle);
}

/// A point already mapped on screen has to be drawn in the rotated face
/// space, or the tilt would be applied twice.
Offset _undoRotation(Offset point, double angle) {
  final cosine = math.cos(angle);
  final sine = math.sin(angle);
  return Offset(
    cosine * point.dx + sine * point.dy,
    -sine * point.dx + cosine * point.dy,
  );
}

void _bandage(Canvas canvas, Offset center, double faceWidth) {
  final width = faceWidth * 0.22;
  final height = width * 0.48;
  final rect = RRect.fromRectAndRadius(
    Rect.fromCenter(center: center, width: width, height: height),
    Radius.circular(height / 2),
  );
  canvas.drawRRect(rect, Paint()..color = _bandageFill);
  canvas.drawRRect(
    rect,
    Paint()
      ..color = _bandageStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, faceWidth * 0.012),
  );
  final eyeY = center.dy - height * 0.08;
  final eyeDx = width * 0.16;
  final eyeRadius = math.max(1.2, faceWidth * 0.012);
  final ink = Paint()..color = _ink;
  canvas.drawCircle(Offset(center.dx - eyeDx, eyeY), eyeRadius, ink);
  canvas.drawCircle(Offset(center.dx + eyeDx, eyeY), eyeRadius, ink);
  final smile = Path()
    ..moveTo(center.dx - width * 0.12, center.dy + height * 0.1)
    ..quadraticBezierTo(
      center.dx,
      center.dy + height * 0.34,
      center.dx + width * 0.12,
      center.dy + height * 0.1,
    );
  canvas.drawPath(
    smile,
    Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.2, faceWidth * 0.012),
  );
}

void _blush(Canvas canvas, Offset center, double faceWidth) {
  final width = faceWidth * 0.16;
  final height = width * 0.62;
  canvas.drawOval(
    Rect.fromCenter(center: center, width: width, height: height),
    Paint()..color = _blushFill,
  );
  final line = Paint()
    ..color = _blushLine
    ..strokeCap = StrokeCap.round
    ..strokeWidth = math.max(1.5, faceWidth * 0.014);
  for (var i = -1; i <= 1; i++) {
    final dx = i * width * 0.22;
    canvas.drawLine(
      center + Offset(dx - width * 0.08, height * 0.18),
      center + Offset(dx + width * 0.04, -height * 0.2),
      line,
    );
  }
}

void _hearts(Canvas canvas, double faceWidth, double phase) {
  final turns = phase * math.pi * 2;
  for (var i = 0; i < 6; i++) {
    final theta = turns * 0.35 + i * (math.pi * 2 / 6);
    final wobble = math.sin(turns + i) * faceWidth * 0.045;
    final radius = faceWidth * 0.78 + wobble;
    final point =
        Offset(math.cos(theta) * radius, math.sin(theta) * radius * 0.86);
    canvas.save();
    canvas.translate(point.dx, point.dy);
    canvas.rotate(math.sin(turns + i) * 0.35);
    _heartShape(canvas, Offset.zero, faceWidth * 0.1);
    canvas.restore();
  }
}

void _heartShape(Canvas canvas, Offset center, double size) {
  final path = _heartPath(center, size);
  canvas.drawPath(path, Paint()..color = _heartFill);
  canvas.drawPath(
    path,
    Paint()
      ..color = _frame
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, size * 0.08),
  );
}

Path _heartPath(Offset center, double size) {
  return Path()
    ..moveTo(center.dx, center.dy + size * 0.35)
    ..cubicTo(
      center.dx - size * 0.95,
      center.dy - size * 0.15,
      center.dx - size * 0.5,
      center.dy - size * 0.95,
      center.dx,
      center.dy - size * 0.32,
    )
    ..cubicTo(
      center.dx + size * 0.5,
      center.dy - size * 0.95,
      center.dx + size * 0.95,
      center.dy - size * 0.15,
      center.dx,
      center.dy + size * 0.35,
    )
    ..close();
}
