import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toktok/domain/entities/video_post.dart';

class VideoPostModel extends VideoPost {
  const VideoPostModel({
    required super.id,
    required super.uid,
    required super.authorName,
    required super.caption,
    required super.videoUrl,
    required super.createdAt,
    super.likes,
    super.views,
    super.isLiked,
    super.isLocal,
  });

  factory VideoPostModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required bool isLiked,
  }) {
    return VideoPostModel.fromMap(
      doc.id,
      doc.data() ?? const {},
      isLiked: isLiked,
    );
  }

  factory VideoPostModel.fromMap(
    String id,
    Map<String, dynamic> data, {
    bool isLiked = false,
  }) {
    return VideoPostModel(
      id: data['id'] as String? ?? id,
      uid: data['uid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Usuario',
      caption: data['caption'] as String? ?? '',
      videoUrl: data['videoUrl'] as String? ?? '',
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      views: (data['views'] as num?)?.toInt() ?? 0,
      createdAt: _readDate(data['createdAt']),
      isLiked: isLiked,
    );
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
