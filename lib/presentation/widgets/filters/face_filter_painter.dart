import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/camera_filter.dart';
import 'package:toktok/domain/entities/tracked_face.dart';
import 'package:toktok/infrastructure/camera/face_coordinate_mapper.dart';
import 'package:toktok/presentation/widgets/filters/face_sticker_painter.dart';

class FilterCameraView {
  const FilterCameraView({
    required this.faces,
    required this.imageSize,
    required this.rotationDegrees,
  });

  static const empty = FilterCameraView(
    faces: [],
    imageSize: Size.zero,
    rotationDegrees: 0,
  );

  final List<TrackedFace> faces;
  final Size imageSize;
  final int rotationDegrees;
}

class FaceFilterPainter extends CustomPainter {
  FaceFilterPainter({
    required this.view,
    required this.filter,
    required this.phase,
    required this.isIos,
  }) : super(repaint: phase);

  final FilterCameraView view;
  final CameraFilter filter;
  final Animation<double> phase;
  final bool isIos;

  @override
  void paint(Canvas canvas, Size size) {
    if (view.imageSize.isEmpty || filter == CameraFilter.none) return;
    final mapper = FaceCoordinateMapper(
      imageSize: view.imageSize,
      rotationDegrees: view.rotationDegrees,
      frontCamera: true,
      isIos: isIos,
      canvasSize: size,
    );
    paintFaceFilters(
      canvas: canvas,
      mapper: mapper,
      filter: filter,
      faces: view.faces,
      phase: phase.value,
    );
  }

  @override
  bool shouldRepaint(FaceFilterPainter oldDelegate) {
    return oldDelegate.filter != filter ||
        oldDelegate.isIos != isIos ||
        oldDelegate.view.rotationDegrees != view.rotationDegrees ||
        oldDelegate.view.imageSize != view.imageSize ||
        oldDelegate.view.faces != view.faces;
  }
}
