import 'package:toktok/domain/entities/video_post.dart';

abstract class VideoPostRepository {
  bool get hasMore;

  void reset();

  Future<List<VideoPost>> loadNextPage({
    required String? currentUid,
    int limit = 5,
  });

  Future<VideoPost> uploadVideo({
    required String filePath,
    required String caption,
    required String uid,
    required String authorName,
    required void Function(double progress) onProgress,
  });

  Future<VideoPost> toggleLike({
    required VideoPost video,
    required String uid,
  });

  Future<void> deleteVideo({
    required VideoPost video,
    required String uid,
  });
}
