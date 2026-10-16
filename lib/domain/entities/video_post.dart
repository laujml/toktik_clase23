class VideoPost {
  const VideoPost({
    required this.id,
    required this.uid,
    required this.authorName,
    required this.caption,
    required this.videoUrl,
    required this.createdAt,
    this.likes = 0,
    this.views = 0,
    this.isLiked = false,
    this.isLocal = false,
  });

  final String id;
  final String uid;
  final String authorName;
  final String caption;
  final String videoUrl;
  final int likes;
  final int views;
  final DateTime createdAt;
  final bool isLiked;
  final bool isLocal;

  VideoPost copyWith({
    String? id,
    String? uid,
    String? authorName,
    String? caption,
    String? videoUrl,
    int? likes,
    int? views,
    DateTime? createdAt,
    bool? isLiked,
    bool? isLocal,
  }) {
    return VideoPost(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      authorName: authorName ?? this.authorName,
      caption: caption ?? this.caption,
      videoUrl: videoUrl ?? this.videoUrl,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
      isLocal: isLocal ?? this.isLocal,
    );
  }
}
