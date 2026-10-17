import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:toktok/domain/exceptions/video_feed_exception.dart';
import 'package:toktok/infrastructure/auth/auth_error_messages.dart';
import 'package:toktok/infrastructure/storage/video_file_storage.dart';

class FirebaseVideoStorage implements VideoFileStorage {
  FirebaseVideoStorage({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<String> upload({
    required String filePath,
    required String uid,
    required void Function(double progress) onProgress,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw const VideoFeedException('No se encontró el video seleccionado.');
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final ref = _storage.ref().child('videos/$uid/$fileName');

    try {
      final task = ref.putFile(
        file,
        SettableMetadata(contentType: 'video/mp4'),
      );
      await for (final snapshot in task.snapshotEvents) {
        final total = snapshot.totalBytes;
        if (total > 0) {
          onProgress(snapshot.bytesTransferred / total);
        }
      }
      return await ref.getDownloadURL();
    } on FirebaseException catch (error) {
      throw VideoFeedException(_message(error));
    } catch (_) {
      throw const VideoFeedException(
        'No se pudo subir el video a Storage. Revisá tu conexión e intentá de nuevo.',
      );
    }
  }

  @override
  Future<void> deleteStoredFile({required String videoUrl}) async {
    if (!_isFirebaseUrl(videoUrl)) return;
    try {
      await _storage.refFromURL(videoUrl).delete();
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') return;
      throw VideoFeedException(_message(error));
    }
  }

  bool _isFirebaseUrl(String videoUrl) {
    return videoUrl.contains('firebasestorage.googleapis.com') ||
        videoUrl.contains('firebasestorage.app');
  }

  String _message(FirebaseException error) {
    switch (error.code) {
      case 'unauthorized':
      case 'unauthenticated':
      case 'object-not-found':
      case 'bucket-not-found':
      case 'retry-limit-exceeded':
        return 'No se pudo usar Firebase Storage. En un proyecto nuevo hace falta el plan Blaze. Si no lo tenés, usá Cloudinary (está en el README).';
      default:
        return messageForFirebaseCode(error.code);
    }
  }
}
