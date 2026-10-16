import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/infrastructure/models/local_video_model.dart';
import 'package:toktok/shared/data/local_video_posts.dart';

List<VideoPost> mapLocalVideoPosts() {
  final videos = <VideoPost>[];
  for (var index = 0; index < videoPosts.length; index++) {
    videos.add(
      LocalVideoModel.fromJson(videoPosts[index]).toVideoPostEntity(
        id: 'local-${index + 1}',
      ),
    );
  }
  return videos;
}
