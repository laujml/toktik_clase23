import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:toktok/domain/entities/tracked_face.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/infrastructure/camera/face_coordinate_mapper.dart';
import 'package:toktok/infrastructure/camera/filtered_frame_renderer.dart';
import 'package:toktok/infrastructure/camera/filtered_video_recorder.dart';
import 'package:toktok/infrastructure/camera/frame_pixels.dart';
import 'package:toktok/presentation/providers/face_filter_provider.dart';
import 'package:toktok/presentation/screens/upload/upload_video_screen.dart';
import 'package:toktok/presentation/widgets/filters/face_filter_painter.dart';
import 'package:toktok/presentation/widgets/filters/heart_glasses_asset.dart';
import 'package:toktok/presentation/widgets/filters/filter_camera_stage.dart';
import 'package:toktok/presentation/widgets/filters/filter_carousel.dart';

const filtersNeedPhoneMessage =
    'Los filtros de cámara funcionan en un teléfono Android o iPhone.';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key, required this.onUploaded});

  final ValueChanged<VideoPost> onUploaded;

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _CopiedFrame {
  const _CopiedFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.bytesPerRow,
    required this.nv21,
    required this.rotationDegrees,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final int bytesPerRow;
  final bool nv21;
  final int rotationDegrees;
}

class _FiltersScreenState extends State<FiltersScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _view = ValueNotifier<FilterCameraView>(FilterCameraView.empty);
  late final AnimationController _heart;
  late final bool _phone = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  late final bool _isIos = !kIsWeb && Platform.isIOS;

  CameraController? _controller;
  FaceDetector? _detector;
  FilteredVideoRecorder? _recorder;
  _CopiedFrame? _latest;
  Timer? _recordTimer;
  DateTime? _recordStarted;
  String? _recordPath;
  String? _error;
  bool _closed = false;
  bool _opening = false;
  bool _detecting = false;
  bool _recording = false;
  bool _encoding = false;
  bool _stopping = false;
  bool _saving = false;
  int _savePercent = 0;
  bool _canOpenSettings = false;
  bool _observing = false;
  int _sensorOrientation = 0;
  int _shownSeconds = 0;
  int _lockWidth = 0;
  int _lockHeight = 0;
  int _lockRotation = 0;

  @override
  void initState() {
    super.initState();
    _heart = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    if (!_phone) {
      _error = filtersNeedPhoneMessage;
      return;
    }
    unawaited(HeartGlassesAsset.ensureLoaded());
    _observing = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_open());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_closed || !_phone) return;
    if (state == AppLifecycleState.paused) {
      unawaited(_abandon());
      return;
    }
    if (state == AppLifecycleState.resumed &&
        mounted &&
        _controller == null &&
        !_saving &&
        (ModalRoute.of(context)?.isCurrent ?? true)) {
      unawaited(_open());
    }
  }

  @override
  void dispose() {
    _closed = true;
    _recordTimer?.cancel();
    _heart.dispose();
    _view.dispose();
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    if (_phone) {
      unawaited(
        SystemChrome.setPreferredOrientations(DeviceOrientation.values),
      );
    }
    final controller = _controller;
    final detector = _detector;
    final recorder = _recorder;
    _controller = null;
    _detector = null;
    _recorder = null;
    unawaited(_shutdown(controller, detector, recorder));
    super.dispose();
  }

  Future<void> _open() async {
    if (!_phone || _closed || _opening || _controller != null) return;
    _opening = true;
    if (mounted) {
      setState(() {
        _error = null;
        _canOpenSettings = false;
      });
    }
    try {
      final cameraStatus = await Permission.camera.request();
      if (!mounted || _closed) return;
      final micStatus = await Permission.microphone.request();
      if (!mounted || _closed) return;
      if (!cameraStatus.isGranted || !micStatus.isGranted) {
        final blocked = cameraStatus.isPermanentlyDenied ||
            micStatus.isPermanentlyDenied ||
            cameraStatus.isRestricted ||
            micStatus.isRestricted;
        setState(() {
          _canOpenSettings = blocked;
          _error = blocked
              ? 'La cámara o el micrófono están bloqueados. Activalos en los ajustes del teléfono para usar los filtros.'
              : 'Para usar los filtros necesitás permitir la cámara y el micrófono.';
        });
        return;
      }

      final cameras = await availableCameras();
      if (!mounted || _closed) return;
      CameraDescription? front;
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          front = camera;
          break;
        }
      }
      if (front == null) {
        setState(() => _error = 'Este teléfono no tiene cámara frontal.');
        return;
      }

      _sensorOrientation = front.sensorOrientation;
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted || _closed) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      try {
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
        if (!mounted || _closed) {
          await _releaseCamera();
          return;
        }
        _detector ??= FaceDetector(
          options: FaceDetectorOptions(
            enableLandmarks: true,
            enableTracking: true,
            performanceMode: FaceDetectorMode.fast,
            minFaceSize: 0.15,
          ),
        );
        await controller.startImageStream(_onCameraImage);
      } catch (_) {
        await _releaseCamera();
        rethrow;
      }
      if (!mounted || _closed) {
        await _releaseCamera();
        return;
      }
      setState(() {});
    } on CameraException catch (error) {
      await _releaseCamera();
      if (!mounted || _closed) return;
      setState(() => _error = _cameraMessage(error));
    } catch (_) {
      await _releaseCamera();
      if (!mounted || _closed) return;
      setState(
        () => _error =
            'No se pudo abrir la cámara. Revisá los permisos e intentá de nuevo.',
      );
    } finally {
      _opening = false;
    }
  }

  Future<void> _retry() async {
    await _abandon();
    if (!mounted || _closed) return;
    await _open();
  }

  void _onCameraImage(CameraImage image) {
    if (_closed || image.planes.isEmpty) return;
    final controller = _controller;
    if (controller == null) return;
    final nv21 = image.format.group == ImageFormatGroup.nv21;
    final bgra = image.format.group == ImageFormatGroup.bgra8888;
    if (!nv21 && !bgra) return;
    final rotation = imageRotationDegrees(
      sensorOrientation: _sensorOrientation,
      deviceOrientation: controller.value.lockedCaptureOrientation ??
          controller.value.deviceOrientation,
      frontCamera: true,
      isIos: _isIos,
    );
    if (rotation == null) return;
    final plane = image.planes.first;
    final hadFrame = _latest != null;
    _latest = _CopiedFrame(
      bytes: Uint8List.fromList(plane.bytes),
      width: image.width,
      height: image.height,
      bytesPerRow: plane.bytesPerRow,
      nv21: nv21,
      rotationDegrees: rotation,
    );
    if (!hadFrame && mounted) setState(() {});
    if (_detecting) return;
    _detecting = true;
    unawaited(_detect(_latest!));
  }

  Future<void> _detect(_CopiedFrame frame) async {
    try {
      final rotation = InputImageRotationValue.fromRawValue(
        frame.rotationDegrees,
      );
      final detector = _detector;
      if (rotation == null || detector == null) return;
      final input = InputImage.fromBytes(
        bytes: frame.bytes,
        metadata: InputImageMetadata(
          size: Size(frame.width.toDouble(), frame.height.toDouble()),
          rotation: rotation,
          format: frame.nv21 ? InputImageFormat.nv21 : InputImageFormat.bgra8888,
          bytesPerRow: frame.bytesPerRow,
        ),
      );
      final faces = await detector.processImage(input);
      if (!mounted || _closed) return;
      _view.value = FilterCameraView(
        faces: [for (final face in faces) TrackedFace.fromMlKit(face)],
        imageSize: Size(frame.width.toDouble(), frame.height.toDouble()),
        rotationDegrees: frame.rotationDegrees,
      );
    } catch (_) {
      if (!mounted || _closed || _error != null) return;
      setState(
        () => _error = 'No se pudo analizar el rostro. Intentá de nuevo.',
      );
    } finally {
      _detecting = false;
    }
  }

  Future<void> _toggleRecord() async {
    if (_saving || _stopping) return;
    if (_recording) {
      await _stopRecording();
      return;
    }
    await _startRecording();
  }

  Future<void> _startRecording() async {
    final frame = _latest;
    final ready = _controller?.value.isInitialized ?? false;
    if (!ready || frame == null || _recording || _error != null) return;
    final output = _outputSize(frame);
    final dir = await getTemporaryDirectory();
    if (!mounted || _closed) return;
    final path =
        '${dir.path}${Platform.pathSeparator}filtro_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final recorder = FilteredVideoRecorder();
    try {
      await recorder.start(width: output.$1, height: output.$2, path: path);
    } catch (_) {
      await recorder.dispose();
      if (!mounted || _closed) return;
      setState(
        () => _error = 'No se pudo empezar a grabar. Revisá el micrófono.',
      );
      return;
    }
    if (!mounted || _closed) {
      await recorder.cancel();
      await recorder.dispose();
      return;
    }
    _recorder = recorder;
    _recordPath = path;
    _recordStarted = DateTime.now();
    _shownSeconds = 0;
    _lockWidth = frame.width;
    _lockHeight = frame.height;
    _lockRotation = frame.rotationDegrees;
    _recording = true;
    setState(() {});
    _recordTimer = Timer.periodic(
      const Duration(milliseconds: 1000 ~/ FilteredVideoRecorder.fps),
      (_) => unawaited(_captureRecordingFrame()),
    );
  }

  Future<void> _captureRecordingFrame() async {
    if (!_recording || _encoding || _closed) return;
    final started = _recordStarted;
    final frame = _latest;
    final recorder = _recorder;
    if (started == null || frame == null || recorder == null) return;
    final elapsed = DateTime.now().difference(started);
    if (elapsed >= const Duration(seconds: 15)) {
      unawaited(_stopRecording());
      return;
    }
    final seconds = elapsed.inSeconds;
    if (seconds != _shownSeconds && mounted) {
      _shownSeconds = seconds;
      setState(() {});
    }
    final expected = elapsed.inMilliseconds * FilteredVideoRecorder.fps ~/ 1000;
    if (recorder.frames >= expected) return;
    if (frame.width != _lockWidth ||
        frame.height != _lockHeight ||
        frame.rotationDegrees != _lockRotation) {
      return;
    }
    _encoding = true;
    try {
      final rgba = await compute(convertCameraFrame, <Object>[
        frame.bytes,
        frame.width,
        frame.height,
        frame.bytesPerRow,
        frame.nv21,
      ]);
      if (!mounted || _closed || !_recording) return;
      final filtered = await renderFilteredFrame(
        rgba: rgba,
        width: frame.width,
        height: frame.height,
        rotationDegrees: frame.rotationDegrees,
        isIos: _isIos,
        filter: context.read<FaceFilterProvider>().selected,
        faces: _view.value.faces,
        phase: _heart.value,
      );
      if (!mounted || _closed || !_recording) return;
      final output = _outputSize(frame);
      if (filtered.length != output.$1 * output.$2 * 4) return;
      if (!_recording || recorder.frames >= _expectedFrames()) return;
      await recorder.addFrame(filtered);
      if (!mounted || _closed) return;
    } catch (_) {
      if (!mounted || _closed) return;
      _recording = false;
      _recordTimer?.cancel();
      setState(() => _error = 'No se pudo guardar el video con el filtro.');
      await _discardRecording();
    } finally {
      _encoding = false;
    }
  }

  int _expectedFrames() {
    final started = _recordStarted;
    if (started == null) return 0;
    final elapsed = DateTime.now().difference(started);
    return elapsed.inMilliseconds * FilteredVideoRecorder.fps ~/ 1000;
  }

  (int, int) _outputSize(_CopiedFrame frame) {
    final mapper = FaceCoordinateMapper(
      imageSize: Size(frame.width.toDouble(), frame.height.toDouble()),
      rotationDegrees: frame.rotationDegrees,
      frontCamera: true,
      isIos: _isIos,
      canvasSize: Size.zero,
    );
    final size = cappedVideoSize(mapper.orientedSize);
    return (size.width.round(), size.height.round());
  }

  Future<void> _stopRecording() async {
    if (_stopping) return;
    if (!_recording && _recorder == null) return;
    _stopping = true;
    _recording = false;
    _recordTimer?.cancel();
    _recordTimer = null;
    final recorder = _recorder;
    final path = _recordPath;
    _recorder = null;
    _recordPath = null;
    _recordStarted = null;
    if (mounted) {
      setState(() {
        _saving = true;
        _savePercent = 8;
      });
    }
    var saved = false;
    try {
      final composeDeadline = DateTime.now().add(const Duration(seconds: 20));
      while (_encoding && !_closed && DateTime.now().isBefore(composeDeadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        _setSavePercent(12);
      }
      if (!mounted || _closed) return;
      if (_encoding || recorder == null || path == null) {
        await _failSave(
          recorder,
          path,
          'Guardar el video tardó demasiado. La cámara sigue lista: pulsá Reintentar y grabá de nuevo.',
        );
        return;
      }
      if (recorder.frames == 0) {
        await recorder.dispose();
        await _deleteFile(path);
        if (!mounted || _closed) return;
        setState(
          () => _error =
              'La grabación quedó vacía. Intentá de nuevo con la cara en cámara.',
        );
        return;
      }
      _setSavePercent(15);
      try {
        final finishing = recorder.finish(
          onProgress: (value) => _setSavePercent(15 + (value * 80).round()),
        );
        unawaited(finishing.then<void>((_) {}, onError: (_) {}));
        await finishing.timeout(const Duration(seconds: 25));
        saved = true;
      } on TimeoutException {
        await _failSave(
          recorder,
          path,
          'Guardar el video tardó demasiado. La cámara sigue lista: pulsá Reintentar y grabá de nuevo.',
        );
        return;
      } finally {
        await recorder.dispose();
      }
      if (!mounted || _closed) return;
      _setSavePercent(100);
      await _releaseCamera();
      if (!mounted || _closed) return;
      final created = await Navigator.of(context).push<VideoPost>(
        MaterialPageRoute(
          builder: (_) => UploadVideoScreen(
            initialVideo: XFile(path),
            videoLocked: true,
          ),
        ),
      );
      if (!mounted || _closed) return;
      if (created != null) {
        widget.onUploaded(created);
        return;
      }
      await _open();
    } catch (_) {
      await _failSave(
        null,
        saved ? null : path,
        'No se pudo guardar el video con el filtro. La cámara sigue lista: pulsá Reintentar y grabá de nuevo.',
      );
    } finally {
      _stopping = false;
      if (mounted && !_closed) {
        setState(() {
          _saving = false;
          _savePercent = 0;
        });
      }
    }
  }

  void _setSavePercent(int value) {
    final next = value.clamp(0, 100);
    if (!mounted || _closed || next == _savePercent) return;
    setState(() => _savePercent = next);
  }

  Future<void> _failSave(
    FilteredVideoRecorder? recorder,
    String? path,
    String message,
  ) async {
    try {
      await recorder?.cancel();
    } catch (_) {}
    try {
      await recorder?.dispose();
    } catch (_) {}
    if (path != null) await _deleteFile(path);
    if (!mounted || _closed) return;
    setState(() => _error = message);
  }

  Future<void> _discardRecording() async {
    final recorder = _recorder;
    final path = _recordPath;
    _recorder = null;
    _recordPath = null;
    _recording = false;
    _recordStarted = null;
    await recorder?.cancel();
    await recorder?.dispose();
    if (path != null) await _deleteFile(path);
  }

  Future<void> _abandon() async {
    _recording = false;
    _recordTimer?.cancel();
    _recordTimer = null;
    await _discardRecording();
    await _releaseCamera();
    if (mounted && !_closed) setState(() => _saving = false);
  }

  Future<void> _releaseCamera() async {
    final controller = _controller;
    _controller = null;
    _latest = null;
    if (controller == null) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}
    try {
      await controller.dispose();
    } catch (_) {}
  }

  Future<void> _deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> _shutdown(
    CameraController? controller,
    FaceDetector? detector,
    FilteredVideoRecorder? recorder,
  ) async {
    try {
      if (controller != null && controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}
    try {
      await controller?.dispose();
    } catch (_) {}
    try {
      await detector?.close();
    } catch (_) {}
    try {
      if (recorder != null) {
        await recorder.cancel();
        await recorder.dispose();
      }
    } catch (_) {}
  }

  String _cameraMessage(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'AudioAccessDenied':
        return 'Para usar los filtros necesitás permitir la cámara y el micrófono.';
      default:
        return 'No se pudo abrir la cámara. ${error.description}';
    }
  }

  String _elapsedLabel() {
    final started = _recordStarted;
    final seconds = started == null
        ? 0
        : DateTime.now().difference(started).inSeconds.clamp(0, 15);
    return '0:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    final height = MediaQuery.sizeOf(context).height;
    final canRecord = ready && !_saving && _error == null && _latest != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            FilterCameraStage(
              controller: controller,
              view: _view,
              phase: _heart,
              isIos: _isIos,
            )
          else
            const ColoredBox(color: Colors.black),
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.paddingOf(context).top + 12,
              child: Material(
                color: const Color(0xFF5C1A1A),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (_phone)
                            Semantics(
                              button: true,
                              label: 'Reintentar cámara',
                              child: TextButton(
                                onPressed: _saving ? null : () => unawaited(_retry()),
                                child: const Text('Reintentar'),
                              ),
                            ),
                          if (_canOpenSettings)
                            Semantics(
                              button: true,
                              label: 'Abrir ajustes del teléfono',
                              child: TextButton(
                                onPressed: () => unawaited(openAppSettings()),
                                child: const Text('Abrir ajustes'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                FaceHint(view: _view, cameraReady: ready && _error == null),
                const Spacer(),
                if (_recording)
                  Semantics(
                    label: 'Tiempo de grabación',
                    value: _elapsedLabel(),
                    child: Text(
                      _elapsedLabel(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                if (_saving)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    child: Column(
                      children: [
                        Semantics(
                          label: 'Progreso al guardar',
                          value: '$_savePercent por ciento',
                          child: LinearProgressIndicator(
                            value: _savePercent / 100,
                            color: const Color(0xFFF48FB1),
                            backgroundColor: const Color(0xFF3A3A3A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Guardando el video con el filtro… $_savePercent%'),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Semantics(
                  button: true,
                  enabled: canRecord || _recording,
                  label: _recording
                      ? 'Detener grabación'
                      : 'Grabar video con filtro',
                  child: IconButton(
                    onPressed: (canRecord || _recording)
                        ? () => unawaited(_toggleRecord())
                        : null,
                    iconSize: height < 700 ? 64 : 76,
                    icon: Icon(
                      _recording ? Icons.stop_circle : Icons.fiber_manual_record,
                      color: _recording
                          ? const Color(0xFFFF4D6D)
                          : const Color(0xFFF48FB1),
                    ),
                  ),
                ),
                SizedBox(
                  height: height < 700 ? 72 : 88,
                  child: FilterCarousel(enabled: !_saving && !_recording),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
