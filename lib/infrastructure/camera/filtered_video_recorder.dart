import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
import 'package:record/record.dart';

class FilteredVideoRecorder {
  FilteredVideoRecorder({AudioRecorder? audio}) : _audio = audio ?? AudioRecorder();

  static const fps = 24;
  static const sampleRate = 44100;
  static const channels = 1;

  final AudioRecorder _audio;
  final List<int> _pcm = <int>[];
  StreamSubscription<Uint8List>? _audioSub;

  bool _open = false;
  bool _disposed = false;
  int frames = 0;

  static int get bytesPerFrame => sampleRate * channels * 2 ~/ fps;

  Future<void> start({
    required int width,
    required int height,
    required String path,
  }) async {
    frames = 0;
    _pcm.clear();
    await FlutterQuickVideoEncoder.setup(
      width: width,
      height: height,
      fps: fps,
      videoBitrate: 1500000,
      profileLevel: ProfileLevel.baselineAutoLevel,
      audioChannels: channels,
      audioBitrate: 64000,
      sampleRate: sampleRate,
      filepath: path,
    );
    try {
      final stream = await _audio.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: channels,
        ),
      );
      _audioSub = stream.listen(_pcm.addAll);
      _open = true;
    } catch (_) {
      try {
        await FlutterQuickVideoEncoder.finish();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> addFrame(Uint8List rgba) async {
    if (!_open) return;
    await FlutterQuickVideoEncoder.appendVideoFrame(rgba);
    await FlutterQuickVideoEncoder.appendAudioFrame(_takePcm(bytesPerFrame));
    frames += 1;
  }

  Future<void> finish({void Function(double progress)? onProgress}) async {
    if (!_open) return;
    _open = false;
    await _stopAudio();
    final subscription = FlutterQuickVideoEncoder.progress.listen(
      (value) => onProgress?.call(value),
      onError: (_) {},
    );
    try {
      await FlutterQuickVideoEncoder.finish();
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> cancel() async {
    if (!_open) {
      await _stopAudio();
      return;
    }
    _open = false;
    await _stopAudio();
    try {
      await FlutterQuickVideoEncoder.finish().timeout(const Duration(seconds: 8));
    } catch (_) {
      // The partial file is discarded by the caller.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _audioSub?.cancel();
    _audioSub = null;
    try {
      await _audio.dispose();
    } catch (_) {}
  }

  Future<void> _stopAudio() async {
    await _audioSub?.cancel();
    _audioSub = null;
    try {
      await _audio.stop();
    } catch (_) {}
  }

  Uint8List _takePcm(int byteCount) {
    final chunk = Uint8List(byteCount);
    final available = _pcm.length < byteCount ? _pcm.length : byteCount;
    for (var i = 0; i < available; i++) {
      chunk[i] = _pcm[i];
    }
    if (available > 0) {
      _pcm.removeRange(0, available);
    }
    return chunk;
  }
}
