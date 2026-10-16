import 'package:toktok/domain/entities/video_post.dart';

class LocalVideoModel {
  const LocalVideoModel({
    required this.name,
    required this.videoUrl,
    this.likes = 0,
    this.views = 0,
  });

  final String name;
  final String videoUrl;
  final int likes;
  final int views;

  factory LocalVideoModel.fromJson(Map<String, dynamic> json) {
    return LocalVideoModel(
      name: json['name'] ?? 'No name',
      videoUrl: json['videoUrl'] as String,
      likes: json['likes'] ?? 0,
      views: json['views'] ?? 0,
    );
  }

  VideoPost toVideoPostEntity({required String id}) {
    return VideoPost(
      id: id,
      uid: '',
      authorName: 'TokTik',
      caption: name,
      videoUrl: videoUrl,
      likes: likes,
      views: views,
      createdAt: DateTime.utc(2020),
      isLocal: true,
    );
  }
}
