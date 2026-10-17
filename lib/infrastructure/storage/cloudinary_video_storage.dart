import 'dart:io';

import 'package:dio/dio.dart';
import 'package:toktok/domain/exceptions/video_feed_exception.dart';
import 'package:toktok/infrastructure/storage/video_file_storage.dart';

class CloudinaryVideoStorage implements VideoFileStorage {
  CloudinaryVideoStorage({
    required this.cloudName,
    required this.uploadPreset,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(minutes: 2),
                receiveTimeout: const Duration(seconds: 30),
              ),
            );

  final String cloudName;
  final String uploadPreset;
  final Dio _dio;

  @override
  Future<String> upload({
    required String filePath,
    required String uid,
    required void Function(double progress) onProgress,
  }) async {
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw const VideoFeedException(
        'Cloudinary no está configurado. Copiá dart_defines.example.json a dart_defines.json y completá el cloud name y el upload preset. El README tiene los pasos.',
      );
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      throw const VideoFeedException('No se encontró el video seleccionado.');
    }

    try {
      final form = FormData.fromMap({
        'upload_preset': uploadPreset,
        'file': await MultipartFile.fromFile(
          filePath,
          filename: '$uid.mp4',
        ),
      });
      final response = await _dio.post<dynamic>(
        'https://api.cloudinary.com/v1_1/$cloudName/video/upload',
        data: form,
        onSendProgress: (sent, total) {
          if (total > 0) onProgress(sent / total);
        },
      );
      final data = response.data;
      final url = data is Map ? data['secure_url'] : null;
      if (url is! String || url.isEmpty) {
        throw const VideoFeedException(
          'Cloudinary no devolvió la dirección del video.',
        );
      }
      return url;
    } on VideoFeedException {
      rethrow;
    } on DioException catch (error) {
      throw VideoFeedException(_message(error));
    } catch (_) {
      throw const VideoFeedException(
        'No se pudo subir el video. Revisá tu conexión e intentá de nuevo.',
      );
    }
  }

  @override
  Future<void> deleteStoredFile({required String videoUrl}) async {
    // Un upload unsigned no se puede destruir desde la app sin el API Secret.
  }

  String _message(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Sin conexión al subir el video. Revisá tu red e intentá de nuevo.';
      default:
        break;
    }

    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final message = (data['error'] as Map)['message'];
      if (message is String && message.isNotEmpty) {
        return 'No se pudo subir el video: $message';
      }
    }
    return 'No se pudo subir el video. Revisá el upload preset de Cloudinary y tu conexión.';
  }
}
