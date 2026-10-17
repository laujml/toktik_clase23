import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/domain/entities/camera_filter.dart';
import 'package:toktok/presentation/providers/face_filter_provider.dart';
import 'package:toktok/presentation/widgets/filters/face_filter_painter.dart';

class FilterCameraStage extends StatelessWidget {
  const FilterCameraStage({
    super.key,
    required this.controller,
    required this.view,
    required this.phase,
    required this.isIos,
  });

  final CameraController controller;
  final ValueNotifier<FilterCameraView> view;
  final Animation<double> phase;
  final bool isIos;

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<FaceFilterProvider>().selected;
    final landscape = controller.value.aspectRatio;
    final portraitRatio = landscape == 0 ? 0.75 : 1 / landscape;
    const previewHeight = 1280.0;
    final previewWidth = previewHeight * portraitRatio;

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: previewWidth,
          height: previewHeight,
          child: CameraPreview(
            controller,
            child: ValueListenableBuilder<FilterCameraView>(
              valueListenable: view,
              builder: (context, snapshot, _) {
                return CustomPaint(
                  painter: FaceFilterPainter(
                    view: snapshot,
                    filter: filter,
                    phase: phase,
                    isIos: isIos,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class FaceHint extends StatelessWidget {
  const FaceHint({super.key, required this.view, required this.cameraReady});

  final ValueNotifier<FilterCameraView> view;
  final bool cameraReady;

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<FaceFilterProvider>().selected;
    return ValueListenableBuilder<FilterCameraView>(
      valueListenable: view,
      builder: (context, snapshot, _) {
        if (!cameraReady ||
            filter == CameraFilter.none ||
            snapshot.faces.isNotEmpty) {
          return const SizedBox.shrink();
        }
        return const Padding(
          padding: EdgeInsets.only(top: 12, left: 24, right: 24),
          child: Text(
            'Mostrá tu cara en la cámara',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
      },
    );
  }
}
