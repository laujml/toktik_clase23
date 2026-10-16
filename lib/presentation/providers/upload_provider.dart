import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/domain/exceptions/video_feed_exception.dart';
import 'package:toktok/domain/repositories/video_post_repository.dart';

class UploadProvider extends ChangeNotifier {
  UploadProvider({required VideoPostRepository repository})
      : _repository = repository;

  final VideoPostRepository _repository;

  bool isUploading = false;
  double progress = 0;
  String? errorMessage;

  Future<VideoPost?> upload({
    required String filePath,
    required String caption,
    required String uid,
    required String authorName,
  }) async {
    if (isUploading) return null;

    isUploading = true;
    progress = 0;
    errorMessage = null;
    notifyListeners();

    try {
      final video = await _repository.uploadVideo(
        filePath: filePath,
        caption: caption,
        uid: uid,
        authorName: authorName,
        onProgress: (value) {
          progress = value.clamp(0, 1).toDouble();
          notifyListeners();
        },
      );
      return video;
    } on VideoFeedException catch (error) {
      errorMessage = error.message;
      return null;
    } catch (_) {
      errorMessage =
          'No se pudo subir el video. Revisá tu conexión e intentá de nuevo.';
      return null;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }
}
