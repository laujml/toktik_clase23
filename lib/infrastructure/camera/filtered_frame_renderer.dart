import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/camera_filter.dart';
import 'package:toktok/domain/entities/tracked_face.dart';
import 'package:toktok/infrastructure/camera/face_coordinate_mapper.dart';
import 'package:toktok/presentation/widgets/filters/face_sticker_painter.dart';
import 'package:toktok/presentation/widgets/filters/heart_glasses_asset.dart';

Future<ui.Image> rgbaToImage(Uint8List rgba, int width, int height) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: width,
    height: height,
    rowBytes: width * 4,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  final frame = await codec.getNextFrame();
  buffer.dispose();
  descriptor.dispose();
  codec.dispose();
  return frame.image;
}

Future<Uint8List> renderFilteredFrame({
  required Uint8List rgba,
  required int width,
  required int height,
  required int rotationDegrees,
  required bool isIos,
  required CameraFilter filter,
  required List<TrackedFace> faces,
  required double phase,
}) async {
  final source = FaceCoordinateMapper(
    imageSize: Size(width.toDouble(), height.toDouble()),
    rotationDegrees: rotationDegrees,
    frontCamera: true,
    isIos: isIos,
    canvasSize: Size.zero,
  );
  final output = cappedVideoSize(source.orientedSize);
  final outputWidth = output.width.round();
  final outputHeight = output.height.round();
  final mapper = FaceCoordinateMapper(
    imageSize: Size(width.toDouble(), height.toDouble()),
    rotationDegrees: rotationDegrees,
    frontCamera: true,
    isIos: isIos,
    canvasSize: output,
  );

  if (filter == CameraFilter.glasses) {
    await HeartGlassesAsset.ensureLoaded();
  }

  final image = await rgbaToImage(rgba, width, height);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  paintOrientedCamera(canvas: canvas, image: image, mapper: mapper);
  paintFaceFilters(
    canvas: canvas,
    mapper: mapper,
    filter: filter,
    faces: faces,
    phase: phase,
  );
  final picture = recorder.endRecording();
  final rendered = await picture.toImage(outputWidth, outputHeight);
  final data = await rendered.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  rendered.dispose();
  picture.dispose();
  if (data == null) {
    throw StateError('No se pudo leer el cuadro con el filtro.');
  }
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}
