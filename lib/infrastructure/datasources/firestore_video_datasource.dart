import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toktok/domain/datasources/video_post_datasource.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/domain/exceptions/video_feed_exception.dart';
import 'package:toktok/infrastructure/auth/auth_error_messages.dart';
import 'package:toktok/infrastructure/models/video_post_model.dart';
import 'package:toktok/infrastructure/storage/video_file_storage.dart';

class FirestoreVideoDatasource implements VideoPostDatasource {
  FirestoreVideoDatasource({
    FirebaseFirestore? firestore,
    required VideoFileStorage storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final VideoFileStorage _storage;

  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool _hasMore = true;

  @override
  bool get hasMore => _hasMore;

  @override
  void reset() {
    _lastDocument = null;
    _hasMore = true;
  }

  @override
  Future<List<VideoPost>> loadNextPage({
    required String? currentUid,
    int limit = 5,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('videos')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final cursor = _lastDocument;
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      _hasMore = snapshot.docs.length >= limit;

      final videos = <VideoPost>[];
      for (final doc in snapshot.docs) {
        var liked = false;
        final uid = currentUid;
        if (uid != null && uid.isNotEmpty) {
          final likeSnap =
              await doc.reference.collection('likes').doc(uid).get();
          liked = likeSnap.exists;
        }
        videos.add(VideoPostModel.fromDoc(doc, isLiked: liked));
      }
      return videos;
    } on VideoFeedException {
      rethrow;
    } on FirebaseException catch (error) {
      throw VideoFeedException(messageForFirebaseCode(error.code));
    } catch (_) {
      throw const VideoFeedException(
        'No se pudieron cargar los videos. Revisá tu conexión e intentá de nuevo.',
      );
    }
  }

  @override
  Future<VideoPost> uploadVideo({
    required String filePath,
    required String caption,
    required String uid,
    required String authorName,
    required void Function(double progress) onProgress,
  }) async {
    try {
      final videoUrl = await _storage.upload(
        filePath: filePath,
        uid: uid,
        onProgress: onProgress,
      );
      final doc = _firestore.collection('videos').doc();
      final createdAt = DateTime.now();
      await doc.set({
        'id': doc.id,
        'uid': uid,
        'authorName': authorName,
        'caption': caption.trim(),
        'videoUrl': videoUrl,
        'likes': 0,
        'views': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      onProgress(1);
      return VideoPost(
        id: doc.id,
        uid: uid,
        authorName: authorName,
        caption: caption.trim(),
        videoUrl: videoUrl,
        createdAt: createdAt,
      );
    } on VideoFeedException {
      rethrow;
    } on FirebaseException catch (error) {
      throw VideoFeedException(messageForFirebaseCode(error.code));
    } catch (_) {
      throw const VideoFeedException(
        'No se pudo guardar el video. Revisá tu conexión e intentá de nuevo.',
      );
    }
  }

  @override
  Future<VideoPost> toggleLike({
    required VideoPost video,
    required String uid,
  }) async {
    if (video.isLocal || video.id.isEmpty) {
      throw const VideoFeedException(
        'Este video de ejemplo no se puede likear.',
      );
    }

    final videoRef = _firestore.collection('videos').doc(video.id);
    final likeRef = videoRef.collection('likes').doc(uid);

    try {
      final nowLiked =
          await _firestore.runTransaction<bool>((transaction) async {
        final videoSnap = await transaction.get(videoRef);
        final likeSnap = await transaction.get(likeRef);
        if (!videoSnap.exists) {
          throw const VideoFeedException('Ese video ya no está disponible.');
        }

        final currentLikes = (videoSnap.data()?['likes'] as num?)?.toInt() ?? 0;
        if (likeSnap.exists) {
          transaction.delete(likeRef);
          if (currentLikes > 0) {
            transaction.update(videoRef, {'likes': currentLikes - 1});
          }
          return false;
        }

        transaction.set(likeRef, {
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(videoRef, {'likes': currentLikes + 1});
        return true;
      });

      final likes =
          nowLiked ? video.likes + 1 : (video.likes > 0 ? video.likes - 1 : 0);
      return video.copyWith(likes: likes, isLiked: nowLiked);
    } on VideoFeedException {
      rethrow;
    } on FirebaseException catch (error) {
      throw VideoFeedException(messageForFirebaseCode(error.code));
    } catch (_) {
      throw const VideoFeedException(
        'No se pudo actualizar el like. Revisá tu conexión e intentá de nuevo.',
      );
    }
  }
}
