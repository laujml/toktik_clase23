import 'package:flutter/foundation.dart';
import 'package:toktok/domain/entities/camera_filter.dart';

class FaceFilterProvider extends ChangeNotifier {
  CameraFilter selected = CameraFilter.kawaii;

  void select(CameraFilter filter) {
    if (selected == filter) return;
    selected = filter;
    notifyListeners();
  }
}
