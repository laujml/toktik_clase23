import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';

/// Lentes de corazón cargados una sola vez para la vista en vivo y el video.
class HeartGlassesAsset {
  HeartGlassesAsset._();

  static const asset = 'assets/filters/lentes_corazon.svg';

  static ui.Picture? picture;
  static ui.Size size = ui.Size.zero;
  static Future<void>? _loading;

  static Future<void> ensureLoaded() {
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    final info = await vg.loadPicture(const SvgAssetLoader(asset), null);
    picture = info.picture;
    size = info.size;
  }
}
