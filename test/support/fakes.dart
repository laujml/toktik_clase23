import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/domain/repositories/video_post_repository.dart';

VideoPost sampleVideo({
  String id = 'video-1',
  String uid = 'author',
  int likes = 0,
  bool isLiked = false,
  bool isLocal = false,
}) {
  return VideoPost(
    id: id,
    uid: isLocal ? '' : uid,
    authorName: isLocal ? 'TokTik' : 'Ana',
    caption: 'Un video',
    videoUrl: isLocal ? 'assets/videos/1.mp4' : 'https://example.com/video.mp4',
    likes: likes,
    views: 3,
    createdAt: DateTime.utc(2024, 1, 2),
    isLiked: isLiked,
    isLocal: isLocal,
  );
}

class FakeVideoRepository implements VideoPostRepository {
  FakeVideoRepository({List<List<VideoPost>>? pages})
      : pages = pages ?? const [];

  List<List<VideoPost>> pages;
  int calls = 0;

  @override
  bool hasMore = true;
  Duration delay = Duration.zero;
  VideoPost? toggled;
  VideoPost? deleted;

  @override
  void reset() {
    calls = 0;
    hasMore = true;
  }

  @override
  Future<List<VideoPost>> loadNextPage({
    required String? currentUid,
    int limit = 5,
  }) async {
    calls++;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (pages.isEmpty) {
      hasMore = false;
      return const [];
    }
    final page = pages.removeAt(0);
    hasMore = pages.isNotEmpty;
    return page;
  }

  @override
  Future<VideoPost> toggleLike({
    required VideoPost video,
    required String uid,
  }) async {
    toggled = video.copyWith(isLiked: !video.isLiked, likes: video.likes + 1);
    return toggled!;
  }

  @override
  Future<void> deleteVideo({
    required VideoPost video,
    required String uid,
  }) async {
    deleted = video;
  }

  @override
  Future<VideoPost> uploadVideo({
    required String filePath,
    required String caption,
    required String uid,
    required String authorName,
    required void Function(double progress) onProgress,
  }) {
    throw UnimplementedError();
  }
}
