import 'package:toktok/domain/datasources/video_post_datasource.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/domain/repositories/video_post_repository.dart';

class VideoPostRepositoryImpl implements VideoPostRepository {
  VideoPostRepositoryImpl({
    required VideoPostDatasource remoteDatasource,
    required List<VideoPost> localVideos,
  })  : _remoteDatasource = remoteDatasource,
        _localVideos = List<VideoPost>.unmodifiable(localVideos);

  final VideoPostDatasource _remoteDatasource;
  final List<VideoPost> _localVideos;
  bool _localAdded = false;

  @override
  bool get hasMore => _remoteDatasource.hasMore || !_localAdded;

  @override
  void reset() {
    _localAdded = false;
    _remoteDatasource.reset();
  }

  @override
  Future<List<VideoPost>> loadNextPage({
    required String? currentUid,
    int limit = 5,
  }) async {
    if (_remoteDatasource.hasMore) {
      final page = await _remoteDatasource.loadNextPage(
        currentUid: currentUid,
        limit: limit,
      );
      if (!_remoteDatasource.hasMore && !_localAdded) {
        _localAdded = true;
        return [...page, ..._localVideos];
      }
      return page;
    }

    if (!_localAdded) {
      _localAdded = true;
      return _localVideos;
    }

    return const [];
  }

  @override
  Future<VideoPost> uploadVideo({
    required String filePath,
    required String caption,
    required String uid,
    required String authorName,
    required void Function(double progress) onProgress,
  }) {
    return _remoteDatasource.uploadVideo(
      filePath: filePath,
      caption: caption,
      uid: uid,
      authorName: authorName,
      onProgress: onProgress,
    );
  }

  @override
  Future<VideoPost> toggleLike({
    required VideoPost video,
    required String uid,
  }) {
    return _remoteDatasource.toggleLike(video: video, uid: uid);
  }

  @override
  Future<void> deleteVideo({
    required VideoPost video,
    required String uid,
  }) {
    return _remoteDatasource.deleteVideo(video: video, uid: uid);
  }
}
