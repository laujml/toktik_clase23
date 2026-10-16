import 'package:flutter/material.dart';
import 'package:toktok/config/feed_config.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/domain/exceptions/video_feed_exception.dart';
import 'package:toktok/domain/repositories/video_post_repository.dart';

class DiscoverProvider extends ChangeNotifier {
  DiscoverProvider({required VideoPostRepository repository})
      : _repository = repository {
    _repository.reset();
  }

  final VideoPostRepository _repository;

  bool initialLoading = true;
  bool isLoading = false;
  String? errorMessage;
  List<VideoPost> videos = [];

  bool get hasMore => _repository.hasMore;

  Future<void> loadNextPage(String? uid) async {
    if (isLoading || !_repository.hasMore) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final page = await _repository.loadNextPage(
        currentUid: uid,
        limit: FeedConfig.pageSize,
      );
      final knownIds = videos.map((item) => item.id).toSet();
      videos = [
        ...videos,
        ...page.where((item) => !knownIds.contains(item.id)),
      ];
    } on VideoFeedException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage =
          'No se pudieron cargar los videos. Revisá tu conexión e intentá de nuevo.';
    } finally {
      isLoading = false;
      initialLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry(String? uid) async {
    if (videos.isEmpty) {
      _repository.reset();
      initialLoading = true;
      errorMessage = null;
      isLoading = false;
      notifyListeners();
    }
    await loadNextPage(uid);
  }

  Future<String?> toggleLike(VideoPost video, String uid) async {
    if (video.isLocal) {
      return 'Este video de ejemplo no se puede likear.';
    }

    try {
      final updated = await _repository.toggleLike(video: video, uid: uid);
      final index = videos.indexWhere((item) => item.id == video.id);
      if (index == -1) return null;
      final next = [...videos];
      next[index] = updated;
      videos = next;
      notifyListeners();
      return null;
    } on VideoFeedException catch (error) {
      return error.message;
    } catch (_) {
      return 'No se pudo actualizar el like. Revisá tu conexión e intentá de nuevo.';
    }
  }

  void insertUploaded(VideoPost video) {
    videos = [video, ...videos.where((item) => item.id != video.id)];
    notifyListeners();
  }
}
