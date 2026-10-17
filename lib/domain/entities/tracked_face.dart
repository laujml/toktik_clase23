import 'dart:ui';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class TrackedFace {
  const TrackedFace({
    required this.boundingBox,
    this.nose,
    this.leftCheek,
    this.rightCheek,
    this.leftEye,
    this.rightEye,
    this.leftMouth,
    this.rightMouth,
    this.eulerZ = 0,
  });

  final Rect boundingBox;
  final Offset? nose;
  final Offset? leftCheek;
  final Offset? rightCheek;
  final Offset? leftEye;
  final Offset? rightEye;
  final Offset? leftMouth;
  final Offset? rightMouth;
  final double eulerZ;

  factory TrackedFace.fromMlKit(Face face) {
    Offset? point(FaceLandmarkType type) {
      final landmark = face.landmarks[type];
      if (landmark == null) return null;
      return Offset(
        landmark.position.x.toDouble(),
        landmark.position.y.toDouble(),
      );
    }

    return TrackedFace(
      boundingBox: face.boundingBox,
      nose: point(FaceLandmarkType.noseBase),
      leftCheek: point(FaceLandmarkType.leftCheek),
      rightCheek: point(FaceLandmarkType.rightCheek),
      leftEye: point(FaceLandmarkType.leftEye),
      rightEye: point(FaceLandmarkType.rightEye),
      leftMouth: point(FaceLandmarkType.leftMouth),
      rightMouth: point(FaceLandmarkType.rightMouth),
      eulerZ: face.headEulerAngleZ ?? 0,
    );
  }
}
